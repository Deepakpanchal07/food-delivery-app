
import 'dart:async';

import 'package:flutter/material.dart';
import '../services/order_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderService _orderService = OrderService();

  Map<String, dynamic>? _order;
  String? _error;
  bool _loading = true;
  bool _requestInProgress = false;

  Timer? _refreshTimer;

  static const Color _orange = Color(0xFFFF6B35);

  static const List<String> _statuses = [
    'Placed',
    'Confirmed',
    'Preparing',
    'Out for Delivery',
    'Delivered',
  ];

  @override
  void initState() {
    super.initState();

    _loadOrder();

    // Refresh the status automatically every 15 seconds.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadOrder(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    if (_requestInProgress) return;

    _requestInProgress = true;

    try {
      final result = await _orderService.trackOrder(widget.orderId);

      if (!mounted) return;

      setState(() {
        _order = result;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    } finally {
      _requestInProgress = false;
    }
  }

  int _currentStatusIndex(String status) {
    return _statuses.indexWhere(
      (item) => item.toLowerCase() == status.toLowerCase(),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Placed':
        return Icons.receipt_long;
      case 'Confirmed':
        return Icons.check_circle_outline;
      case 'Preparing':
        return Icons.soup_kitchen;
      case 'Out for Delivery':
        return Icons.delivery_dining;
      case 'Delivered':
        return Icons.home;
      default:
        return Icons.circle;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return '';

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} at '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final status = _order?['status']?.toString() ?? 'Placed';
    final cancelled = status.toLowerCase() == 'cancelled';

    final currentIndex = _currentStatusIndex(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Track Order',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _orange),
            )
          : _order == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 55,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load order tracking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error ?? 'Please try again.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOrder,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrder,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E9),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              cancelled
                                  ? Icons.cancel_outlined
                                  : Icons.delivery_dining,
                              size: 54,
                              color: cancelled ? Colors.red : _orange,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              cancelled
                                  ? 'Order Cancelled'
                                  : status == 'Delivered'
                                      ? 'Your food has arrived!'
                                      : 'Your order is $status',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: cancelled ? Colors.red : _orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Order status refreshes automatically.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Order Progress',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (cancelled)
                        const ListTile(
                          leading: Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 32,
                          ),
                          title: Text(
                            'Cancelled',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'This order will not proceed to delivery.',
                          ),
                        )
                      else
                        ...List.generate(_statuses.length, (index) {
                          final step = _statuses[index];
                          final completed = currentIndex >= index;
                          final isCurrent = currentIndex == index;

                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 44,
                                  child: Column(
                                    children: [
                                      Icon(
                                        _statusIcon(step),
                                        size: 28,
                                        color: completed
                                            ? _orange
                                            : Colors.grey.shade400,
                                      ),
                                      if (index < _statuses.length - 1)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: completed &&
                                                    currentIndex > index
                                                ? _orange
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 26,
                                      top: 3,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          step,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isCurrent
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: completed
                                                ? Colors.black87
                                                : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isCurrent
                                              ? 'Current status'
                                              : completed
                                                  ? 'Completed'
                                                  : 'Pending',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isCurrent
                                                ? _orange
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                      const Divider(height: 16),

                      const Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _detailRow(
                        'Order ID',
                        _order?['id']?.toString() ??
                            widget.orderId,
                      ),

                      _detailRow(
                        'Placed on',
                        _formatDate(_order?['createdAt']),
                      ),

                      _detailRow(
                        'Last updated',
                        _formatDate(_order?['updatedAt']),
                      ),

                      _detailRow(
                        'Subtotal',
                        '₹${((_order?['subtotal'] as num?) ?? 0).toStringAsFixed(2)}',
                      ),

                      _detailRow(
                        'Delivery fee',
                        '₹${((_order?['deliveryFee'] as num?) ?? 0).toStringAsFixed(2)}',
                      ),

                      _detailRow(
                        'Total amount',
                        '₹${((_order?['totalAmount'] as num?) ?? 0).toStringAsFixed(2)}',
                        bold: true,
                      ),

                      const SizedBox(height: 20),

                      OutlinedButton.icon(
                        onPressed: _loadOrder,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Status Now'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                fontSize: bold ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
