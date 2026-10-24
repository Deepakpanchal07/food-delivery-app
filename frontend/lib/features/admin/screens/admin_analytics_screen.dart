
import 'package:flutter/material.dart';
import 'package:frontend/features/admin/screens/services/admin_analytics_service.dart';


class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState
    extends State<AdminAnalyticsScreen> {
  static const Color primary = Color(0xFFFF6B35);
  static const Color background = Color(0xFFFFF9F5);

  final AdminAnalyticsService _service =
      AdminAnalyticsService();

  late Future<Map<String, dynamic>> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() {
    _analyticsFuture = _service.getAnalytics();
  }

  Future<void> _refresh() async {
    setState(_loadAnalytics);

    try {
      await _analyticsFuture;
    } catch (_) {
      // The FutureBuilder displays the error.
    }
  }

  int _number(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _amount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    return '₹${_amount(value).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh analytics',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error
                              ?.toString()
                              .replaceFirst('Exception: ', '') ??
                          'Unable to load analytics.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final statuses =
              data['statusBreakdown'] is Map
                  ? Map<String, dynamic>.from(
                      data['statusBreakdown'] as Map,
                    )
                  : <String, dynamic>{};

          final recentOrders =
              data['recentOrders'] is List
                  ? data['recentOrders'] as List
                  : [];

          final cards = [
            (
              'Total Orders',
              _number(data['totalOrders']).toString(),
              Icons.receipt_long_rounded,
              const Color(0xFF3867D6),
            ),
            (
              'Delivered',
              _number(data['deliveredOrders']).toString(),
              Icons.check_circle_outline_rounded,
              const Color(0xFF20A464),
            ),
            (
              'Delivered Revenue',
              _money(data['totalRevenue']),
              Icons.currency_rupee_rounded,
              primary,
            ),
            (
              'Customers',
              _number(data['totalCustomers']).toString(),
              Icons.people_alt_rounded,
              const Color(0xFF8E44AD),
            ),
            (
              'Restaurants',
              _number(data['totalRestaurants']).toString(),
              Icons.storefront_rounded,
              const Color(0xFF168AAD),
            ),
          ];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Business Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        constraints.maxWidth >= 650 ? 3 : 2;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: cards.length,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 132,
                      ),
                      itemBuilder: (context, index) {
                        final card = cards[index];

                        return _statCard(
                          title: card.$1,
                          value: card.$2,
                          icon: card.$3,
                          color: card.$4,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Order Status Breakdown',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: statuses.isEmpty
                        ? const Text('No order data available.')
                        : Column(
                            children: statuses.entries.map((entry) {
                              final count = _number(entry.value);
                              final total =
                                  _number(data['totalOrders']);
                              final progress = total == 0
                                  ? 0.0
                                  : (count / total)
                                      .clamp(0.0, 1.0)
                                      .toDouble();

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(entry.key),
                                        ),
                                        Text(
                                          count.toString(),
                                          style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 7,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      backgroundColor:
                                          Colors.grey.shade200,
                                      color: primary,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (recentOrders.isEmpty)
                  const Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No orders found.'),
                    ),
                  )
                else
                  ...recentOrders.map((item) {
                    final order = item is Map
                        ? Map<String, dynamic>.from(item)
                        : <String, dynamic>{};

                    final status =
                        order['status']?.toString() ?? 'Unknown';
                    final restaurant =
                        order['restaurantName']?.toString() ??
                            'Unknown restaurant';
                    final customer =
                        order['customerName']?.toString() ??
                            'Customer';

                    return Card(
                      color: Colors.white,
                      margin:
                          const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              primary.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: primary,
                          ),
                        ),
                        title: Text(
                          customer,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text('$restaurant\n$status'),
                        isThreeLine: true,
                        trailing: Text(
                          _money(order['totalAmount']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 25),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
