import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardAnalytics? _analytics;
  List<Order> _recentOrders = [];
  List<Order> _allOrders = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedTimeframe = 'All Time';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _dateStringForOffset(int daysOffset) {
    final DateTime target = DateTime.now().subtract(Duration(days: daysOffset));
    String y = target.year.toString();
    String m = target.month.toString().padLeft(2, '0');
    String d = target.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<Order> get _filteredOrdersForTimeframe {
    if (_selectedTimeframe == 'All Time') {
      return _allOrders;
    }
    
    final String targetDateStr = _selectedTimeframe == 'Today' 
        ? _dateStringForOffset(0)
        : _selectedTimeframe == 'Yesterday'
            ? _dateStringForOffset(1)
            : _dateStringForOffset(2); // 'Day 1'

    return _allOrders.where((o) => o.date.startsWith(targetDateStr)).toList();
  }

  double get _revenueForTimeframe {
    final filtered = _filteredOrdersForTimeframe;
    return filtered.where((o) => o.status == 'Completed').fold(0.0, (sum, o) => sum + o.totalPrice);
  }

  int get _completedForTimeframe {
    final filtered = _filteredOrdersForTimeframe;
    return filtered.where((o) => o.status == 'Completed').length;
  }

  int get _pendingForTimeframe {
    final filtered = _filteredOrdersForTimeframe;
    return filtered.where((o) => o.status == 'Pending').length;
  }

  int get _totalForTimeframe {
    return _filteredOrdersForTimeframe.length;
  }

  Future<void> _fetchData({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }
    try {
      final analytics = await ApiService.getAnalytics();
      final allOrders = await ApiService.getOrders();
      setState(() {
        _analytics = analytics;
        _allOrders = allOrders;
        _recentOrders = allOrders.take(4).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    try {
      await ApiService.updateOrderStatus(orderId, newStatus);
      _fetchData(isSilent: true); // Refresh analytics & lists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #$orderId status updated to $newStatus'),
          backgroundColor: Colors.green[800],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order status: $e'),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00C853),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load analytics: $_errorMessage',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            )
          ],
        ),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1100;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFF00C853),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Curry Mama Dashboard',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Analytics & Metrics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Timeframe Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16161E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTimeframe,
                          dropdownColor: const Color(0xFF16161E),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00C853)),
                          items: const [
                            DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                            DropdownMenuItem(value: 'Today', child: Text('Today')),
                            DropdownMenuItem(value: 'Yesterday', child: Text('Yesterday')),
                            DropdownMenuItem(value: 'Day 1', child: Text('Day 1 (2 Days Ago)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedTimeframe = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _fetchData(isSilent: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1E2E),
                        foregroundColor: const Color(0xFF00C853),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: const Color(0xFF00C853).withOpacity(0.3)),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Refresh Data', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // KPI Metrics Grid
            _buildMetricsGrid(isDesktop),
            const SizedBox(height: 32),

            // Sales Chart & Recent Orders
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildRevenueChartCard()),
                  const SizedBox(width: 32),
                  Expanded(flex: 2, child: _buildRecentOrdersCard()),
                ],
              )
            else ...[
              _buildRevenueChartCard(),
              const SizedBox(height: 32),
              _buildRecentOrdersCard(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(bool isDesktop) {
    int crossAxisCount = 4;
    if (!isDesktop) {
      crossAxisCount = MediaQuery.of(context).size.width < 600 ? 1 : 2;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _buildMetricCard(
          'Total Revenue',
          '₹${_revenueForTimeframe.toStringAsFixed(2)}',
          Icons.currency_rupee,
          const Color(0xFF4CAF50),
          '$_selectedTimeframe Revenue',
        ),
        _buildMetricCard(
          'Completed Orders',
          '$_completedForTimeframe',
          Icons.check_circle_outline,
          const Color(0xFF00BCD4),
          'Delivered for $_selectedTimeframe',
        ),
        _buildMetricCard(
          'Pending Orders',
          '$_pendingForTimeframe',
          Icons.pending_actions,
          const Color(0xFFFF9800),
          'Awaiting preparation',
        ),
        _buildMetricCard(
          'Total Orders Log',
          '$_totalForTimeframe',
          Icons.shopping_cart_outlined,
          const Color(0xFFE91E63),
          'Orders registered in $_selectedTimeframe',
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: color, size: 28),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white30,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChartCard() {
    final List<DailySale> sales = _analytics?.dailySales ?? [];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Trends',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Revenue collected on a daily basis (INR)',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 32),
          // Beautiful Custom Bar Chart
          if (sales.isEmpty)
            const SizedBox(
              height: 250,
              child: Center(
                child: Text('No completed sales recorded for chart yet.', style: TextStyle(color: Colors.white30)),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: sales.map((sale) {
                  // Max calculation for ratio
                  final double maxRevenue = sales.map((s) => s.revenue).reduce((a, b) => a > b ? a : b);
                  final double ratio = maxRevenue > 0 ? (sale.revenue / maxRevenue) : 0;
                  final double height = 180 * ratio;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '₹${sale.revenue.toInt()}',
                        style: const TextStyle(color: Color(0xFF00C853), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 45,
                        height: height.clamp(10, 180).toDouble(),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFFFF6F00)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C853).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 0),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // Parse simple date format 'YYYY-MM-DD'
                        sale.date.split('-').skip(1).join('/'),
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Orders Feed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage and track pending incoming requests',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          if (_recentOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'No orders registered yet.',
                  style: TextStyle(color: Colors.white30),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentOrders.length,
              itemBuilder: (context, index) {
                final order = _recentOrders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Order #${order.id} • ₹${order.totalPrice}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(order),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Order order) {
    if (order.status == 'Pending') {
      return ElevatedButton(
        onPressed: () => _updateStatus(order.id, 'Completed'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C853),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: const Text('Complete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      );
    }

    final Color badgeColor = order.status == 'Completed' ? Colors.green[800]! : Colors.red[800]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Text(
        order.status,
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
