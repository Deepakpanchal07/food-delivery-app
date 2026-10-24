
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/features/admin/screens/admin_panel_screen.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/constants/api_constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();
      final TextEditingController _searchController =
    TextEditingController();

String _searchQuery = '';
String _selectedStatus = 'All';

static const List<String> _statusFilters = [
  'All',
  'Placed',
  'Confirmed',
  'Preparing',
  'Out for Delivery',
  'Delivered',
  'Cancelled',
];

  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;

  List<Map<String, dynamic>> _orders = [];

  String get _ordersUrl =>
      '${ApiConstants.baseUrl}/orders/admin/all';

  static const List<String> _statuses = [
    'Placed',
    'Confirmed',
    'Preparing',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
  ];

  Color _statusColor(String status) {
  switch (status) {
    case 'Placed':
      return Colors.orange;
    case 'Confirmed':
      return Colors.blue;
    case 'Preparing':
      return Colors.deepPurple;
    case 'Out for Delivery':
      return Colors.teal;
    case 'Delivered':
      return Colors.green;
    case 'Cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // Get authentication headers.
  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Please sign in first.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Parse JSON safely, even when the server returns HTML.
  Map<String, dynamic> _parseJsonResponse(
    http.Response response,
  ) {
    final contentType =
        response.headers['content-type'] ?? '';

    if (!contentType.toLowerCase().contains(
      'application/json',
    )) {
      final body = response.body;
      final preview = body.substring(
        0,
        body.length > 200 ? 200 : body.length,
      );

      throw Exception(
        'Server returned HTML/text instead of JSON.\n'
        'URL: ${response.request?.url ?? _ordersUrl}\n'
        'HTTP Status: ${response.statusCode}\n'
        'Response: $preview',
      );
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('Unexpected API response format.');
      }

      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw Exception(
        'Server response contains invalid JSON.',
      );
    }
  }

  // Fetch all orders.
  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(_ordersUrl),
        headers: await _headers(),
      );

      final decoded = _parseJsonResponse(response);

      if (response.statusCode == 401) {
        throw Exception(
          'Session expired. Please sign in again.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'Admin access required. Check your account role.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          decoded['message']?.toString() ??
              'Could not load orders.',
        );
      }

      if (decoded['orders'] is! List) {
        throw Exception(
          'Orders list is missing in the API response.',
        );
      }

      final loadedOrders =
          (decoded['orders'] as List)
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList();

      if (!mounted) return;

      setState(() {
        _orders = loadedOrders;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst(
              'Exception: ',
              '',
            );
        _isLoading = false;
      });
    }
  }

  String _text(
    Map<String, dynamic> order,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = order[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  String _orderId(Map<String, dynamic> order) {
    return _text(order, ['_id', 'id']);
  }

  String _status(Map<String, dynamic> order) {
    final status = _text(
      order,
      ['status'],
      fallback: 'Placed',
    );

    return _statuses.contains(status) ? status : 'Placed';
  }

  double _amount(Map<String, dynamic> order) {
    final value = order['totalAmount'] ??
        order['totalPrice'] ??
        order['total'] ??
        order['grandTotal'] ??
        0;

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }

  int _itemCount(Map<String, dynamic> order) {
    final items = order['items'];

    if (items is! List) return 0;

    return items.fold<int>(0, (total, item) {
      if (item is! Map) return total;

      final quantity = item['quantity'];

      if (quantity is num) {
        return total + quantity.toInt();
      }

      return total +
          (int.tryParse(quantity.toString()) ?? 1);
    });
  }

  List<String> _allowedNextStatuses(String current) {
    switch (current) {
      case 'Placed':
        return ['Confirmed', 'Cancelled'];
      case 'Confirmed':
        return ['Preparing', 'Cancelled'];
      case 'Preparing':
        return ['Out for Delivery', 'Cancelled'];
      case 'Out for Delivery':
        return ['Delivered'];
      default:
        return [];
    }
  }

  // Update order status.
  Future<void> _updateStatus(
    Map<String, dynamic> order,
    String newStatus,
  ) async {
    if (_isUpdating) return;

    final id = _orderId(order);

    if (id.isEmpty) {
      _showMessage('Order ID missing.');
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await http.patch(
        Uri.parse(
          '${ApiConstants.baseUrl}/orders/$id/status',
        ),
        headers: await _headers(),
        body: jsonEncode({'status': newStatus}),
      );

      final decoded = _parseJsonResponse(response);

      if (response.statusCode == 401) {
        throw Exception(
          'Session expired. Please sign in again.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception('Admin access required.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          decoded['message']?.toString() ??
              'Status update failed.',
        );
      }

      await _loadOrders();

      if (!mounted) return;

      _showMessage('Order status updated to $newStatus.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int _countStatus(String status) {
    return _orders
        .where((order) => _status(order) == status)
        .length;
  }

  double get _totalSales {
  return _orders.fold<double>(0, (total, order) {
    final status = _status(order);

    if (status == 'Delivered') {
      return total + _amount(order);
    }

    return total;
  });
}

  List<Map<String, dynamic>> get _filteredOrders {
  final query = _searchQuery.trim().toLowerCase();

  return _orders.where((order) {
    final customerName = _text(
      order,
      ['customerName', 'name'],
    ).toLowerCase();

    final orderId = _orderId(order).toLowerCase();
    final status = _status(order);

    final matchesSearch = query.isEmpty ||
        customerName.contains(query) ||
        orderId.contains(query);

    final matchesStatus = _selectedStatus == 'All' ||
        status == _selectedStatus;

    return matchesSearch && matchesStatus;
  }).toList();
}

  Widget _summaryCard(
    String title,
    int value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.deepOrange,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _statusBadge(String status) {
  final color = _statusColor(status);

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: color.withValues(alpha: 0.5),
      ),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}

  Widget _orderCard(Map<String, dynamic> order) {
    final status = _status(order);
    final nextStatuses = _allowedNextStatuses(status);

    final customerName = _text(
      order,
      ['customerName', 'name'],
      fallback: 'Customer',
    );

    final restaurantName = _text(
      order,
      ['restaurantName'],
      fallback: 'Restaurant order',
    );

    final createdAt = DateTime.tryParse(
      _text(order, ['createdAt']),
    );

    final itemCount = _itemCount(order);
    final id = _orderId(order);

    final shortId = id.isEmpty
        ? 'N/A'
        : id.substring(0, id.length < 8 ? id.length : 8);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order #$shortId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '₹${_amount(order).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            Text('Customer: $customerName'),
            const SizedBox(height: 5),
            Text('Restaurant: $restaurantName'),
            const SizedBox(height: 5),
            Text('Items: $itemCount'),
            if (createdAt != null) ...[
              const SizedBox(height: 5),
              Text(
                'Date: ${createdAt.toLocal().toString().substring(0, 16)}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
                children: [
                  const Text(
                    'Status: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _statusBadge(status),
                    ),
                  ),
                ],
              ),
            if (nextStatuses.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: nextStatuses.map((nextStatus) {
                  return OutlinedButton(
                    onPressed: _isUpdating
                        ? null
                        : () => _updateStatus(
                              order,
                              nextStatus,
                            ),
                    child: Text(
                      nextStatus == 'Cancelled'
                          ? 'Cancel Order'
                          : 'Set: $nextStatus',
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'This order is in a final status.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
void dispose() {
  _searchController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    final activeOrders = _orders.where((order) {
      final status = _status(order);

      return status != 'Delivered' &&
          status != 'Cancelled';
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
            title: const Text('Admin Dashboard'),
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            leading: IconButton(
                tooltip: 'Back to Admin Panel',
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminPanelScreen(),
                      ),
                    );
                  }
                },
              ),
            actions: [
              IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Orders',
                  onPressed: _isLoading || _isUpdating
                      ? null
                      : _loadOrders,
                ),
            ],
        ),
        body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadOrders,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        childAspectRatio: 4.2,
                        children: [
                          _summaryCard(
                            'Total Orders',
                            _orders.length,
                            Icons.shopping_bag_outlined,
                          ),
                          _summaryCard(
                            'Active Orders',
                            activeOrders,
                            Icons.pending_actions,
                          ),
                          _summaryCard(
                            'Delivered',
                            _countStatus('Delivered'),
                            Icons.check_circle_outline,
                          ),
                          _summaryCard(
                            'Cancelled',
                            _countStatus('Cancelled'),
                            Icons.cancel_outlined,
                          ),
                          _summaryCard(
                            'Delivered Sales ₹${_totalSales.toStringAsFixed(0)}',
                            _countStatus('Delivered'),
                            Icons.currency_rupee,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.currency_rupee,
                                      color: Colors.green,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Delivered Sales',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '₹${_totalSales.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_countStatus('Delivered')} orders delivered',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: 20),
                      const Text(
                        'All Orders',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      const SizedBox(height: 10),

                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search customer name or Order ID',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.deepOrange,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Filter by Order Status',
                        prefixIcon: const Icon(
                          Icons.filter_list,
                          color: Colors.deepOrange,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _statusFilters.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                    ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Showing ${_filteredOrders.length} of ${_orders.length} orders',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 12),
                      if (_orders.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No orders found yet.',
                          ),
                        ),
                      ),
                    )
                  else
                    ..._orders.map(_orderCard),
                    ],
                  ),
                ),
    );
    
  }
}
