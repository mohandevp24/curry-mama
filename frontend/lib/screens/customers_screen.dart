import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_service.dart';
import '../models.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<CustomerModel> _customers = [];
  List<CustomerModel> _filteredCustomers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }
    try {
      final list = await ApiService.getCustomers();
      setState(() {
        _customers = list;
        _filteredCustomers = list;
        _isLoading = false;
      });
      _onSearchChanged();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((c) {
          final nameMatch = c.customerName.toLowerCase().contains(query);
          final phoneMatch = c.mobileNumber.contains(query);
          final addressMatch = c.address.toLowerCase().contains(query);
          return nameMatch || phoneMatch || addressMatch;
        }).toList();
      }
    });
  }

  void _showOrderHistoryDialog(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final bool isMobile = screenWidth < 700;

        return StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            backgroundColor: const Color(0xFF16161E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF00C853), width: 1.5),
            ),
            child: Container(
              width: isMobile ? screenWidth * 0.95 : 700,
              constraints: const BoxConstraints(maxHeight: 650),
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Customer Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: isMobile ? 20 : 24,
                            backgroundColor: const Color(0xFF00C853).withOpacity(0.2),
                            child: Text(
                              customer.customerName.isNotEmpty
                                  ? customer.customerName[0].toUpperCase()
                                  : 'C',
                              style: TextStyle(
                                color: const Color(0xFF00C853),
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 16 : 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.customerName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 15 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customer.mobileNumber.isNotEmpty ? '+91 ${customer.mobileNumber}' : 'No mobile number',
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Address & Stats Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Color(0xFF00C853), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            customer.address.isNotEmpty ? customer.address : 'Address: Not specified',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${customer.totalPurchases.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: const Color(0xFF00C853),
                                fontSize: isMobile ? 15 : 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${customer.totalOrders} ${customer.totalOrders == 1 ? 'Order' : 'Orders'}',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                const Text(
                  'Order History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Orders List
                Expanded(
                  child: customer.orderHistory.isEmpty
                      ? const Center(
                          child: Text(
                            'No past orders recorded.',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : ListView.separated(
                          itemCount: customer.orderHistory.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = customer.orderHistory[index];
                            final Color statusColor = _getStatusColor(order.status);

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E2E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black26,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Order #${order.id}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            order.date,
                                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: statusColor.withOpacity(0.5)),
                                            ),
                                            child: Text(
                                              order.status,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '₹${order.totalPrice.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Color(0xFF00C853),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Items Breakdown
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: order.items.map((it) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16161E),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white10),
                                        ),
                                        child: Text(
                                          '${it.name} × ${it.quantity}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Payment: ${order.paymentMethod} (${order.paymentStatus})',
                                        style: TextStyle(
                                          color: order.paymentStatus.toLowerCase() == 'paid'
                                              ? const Color(0xFF00C853)
                                              : Colors.orangeAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (order.address.isNotEmpty)
                                        Flexible(
                                          child: Text(
                                            order.address,
                                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return const Color(0xFF00C853);
      case 'pending':
        return Colors.orangeAccent;
      case 'preparing':
        return Colors.lightBlueAccent;
      case 'out for delivery':
        return Colors.purpleAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalRevenue = _customers.fold(0.0, (sum, c) => sum + c.totalPurchases);
    final int repeatCount = _customers.where((c) => c.totalOrders > 1).length;
    final double avgSpend = _customers.isNotEmpty ? (totalRevenue / _customers.length) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text('Error: $_errorMessage', style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _fetchCustomers(),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                        child: const Text('Retry', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _fetchCustomers(),
                  color: const Color(0xFF00C853),
                  child: Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final bool isMobile = screenWidth < 700;

                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(isMobile ? 14.0 : 28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Header (Responsive)
                            isMobile
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Customer Management',
                                        style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Text(
                                            'Customers Log',
                                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00C853).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: const Color(0xFF00C853).withOpacity(0.4)),
                                            ),
                                            child: Text(
                                              '${_customers.length}',
                                              style: const TextStyle(
                                                color: Color(0xFF00C853),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _fetchCustomers(isSilent: true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1E1E2E),
                                            foregroundColor: const Color(0xFF00C853),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: BorderSide(color: const Color(0xFF00C853).withOpacity(0.3)),
                                            ),
                                          ),
                                          icon: const Icon(Icons.refresh, size: 18),
                                          label: const Text('Refresh Customers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Customer Management',
                                            style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Text(
                                                'Customers Log',
                                                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF00C853).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(color: const Color(0xFF00C853).withOpacity(0.4)),
                                                ),
                                                child: Text(
                                                  '${_customers.length} Registered',
                                                  style: const TextStyle(
                                                    color: Color(0xFF00C853),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _fetchCustomers(isSilent: true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1E1E2E),
                                          foregroundColor: const Color(0xFF00C853),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(color: const Color(0xFF00C853).withOpacity(0.3)),
                                          ),
                                        ),
                                        icon: const Icon(Icons.refresh, size: 18),
                                        label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                            SizedBox(height: isMobile ? 16 : 24),

                            // Analytics Summary Cards
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 800;
                                return GridView.count(
                                  crossAxisCount: isWide ? 4 : 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: isMobile ? 10 : 14,
                                  mainAxisSpacing: isMobile ? 10 : 14,
                                  childAspectRatio: isWide ? 2.2 : (isMobile ? 1.5 : 1.6),
                                  children: [
                                    _buildSummaryCard('Total Customers', '${_customers.length}', Icons.people_alt, const Color(0xFF00C853)),
                                    _buildSummaryCard('Total Purchases', '₹${totalRevenue.toStringAsFixed(0)}', Icons.payments, Colors.lightBlueAccent),
                                    _buildSummaryCard('Repeat Customers', '$repeatCount', Icons.repeat, Colors.amberAccent),
                                    _buildSummaryCard('Avg. Order Value', '₹${avgSpend.toStringAsFixed(0)}', Icons.analytics_outlined, Colors.purpleAccent),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: isMobile ? 16 : 24),

                            // Search Bar
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16161E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  icon: Icon(Icons.search, color: Color(0xFF00C853)),
                                  hintText: 'Search customer name, phone, or address...',
                                  hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            SizedBox(height: isMobile ? 14 : 20),

                            // Customers List
                            if (_filteredCustomers.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16161E),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.person_search, color: Colors.white24, size: 48),
                                    SizedBox(height: 12),
                                    Text(
                                      'No customers found matching your search.',
                                      style: TextStyle(color: Colors.white54, fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredCustomers.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final customer = _filteredCustomers[index];

                                  return Container(
                                    padding: EdgeInsets.all(isMobile ? 14 : 18),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16161E),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: isMobile
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 20,
                                                    backgroundColor: const Color(0xFF00C853).withOpacity(0.15),
                                                    child: Text(
                                                      customer.customerName.isNotEmpty
                                                          ? customer.customerName[0].toUpperCase()
                                                          : 'C',
                                                      style: const TextStyle(
                                                        color: Color(0xFF00C853),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                customer.customerName,
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 15,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                            if (customer.totalOrders > 1)
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.amberAccent.withOpacity(0.15),
                                                                  borderRadius: BorderRadius.circular(4),
                                                                ),
                                                                child: const Text(
                                                                  'Repeat',
                                                                  style: TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.phone, color: Color(0xFF00C853), size: 12),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              customer.mobileNumber.isNotEmpty ? '+91 ${customer.mobileNumber}' : 'No phone',
                                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (customer.address.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.location_on, color: Colors.white38, size: 13),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        customer.address,
                                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              const SizedBox(height: 10),
                                              const Divider(color: Colors.white10, height: 1),
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '₹${customer.totalPurchases.toStringAsFixed(0)}',
                                                        style: const TextStyle(
                                                          color: Color(0xFF00C853),
                                                          fontWeight: FontWeight.w900,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '(${customer.totalOrders} ${customer.totalOrders == 1 ? 'order' : 'orders'})',
                                                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                                                      ),
                                                    ],
                                                  ),
                                                  ElevatedButton.icon(
                                                    onPressed: () => _showOrderHistoryDialog(customer),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF1E1E2E),
                                                      foregroundColor: const Color(0xFF00C853),
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        side: BorderSide(color: const Color(0xFF00C853).withOpacity(0.3)),
                                                      ),
                                                    ),
                                                    icon: const Icon(Icons.receipt_long, size: 13),
                                                    label: const Text(
                                                      'Order History',
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              // Avatar
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor: const Color(0xFF00C853).withOpacity(0.15),
                                                child: Text(
                                                  customer.customerName.isNotEmpty
                                                      ? customer.customerName[0].toUpperCase()
                                                      : 'C',
                                                  style: const TextStyle(
                                                    color: Color(0xFF00C853),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),

                                              // Customer Details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          customer.customerName,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        if (customer.totalOrders > 1)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: Colors.amberAccent.withOpacity(0.15),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: const Text(
                                                              'Repeat',
                                                              style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.phone, color: Color(0xFF00C853), size: 14),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          customer.mobileNumber.isNotEmpty ? '+91 ${customer.mobileNumber}' : 'No phone number',
                                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                                        ),
                                                        if (customer.mobileNumber.isNotEmpty) ...[
                                                          const SizedBox(width: 6),
                                                          InkWell(
                                                            onTap: () {
                                                              Clipboard.setData(ClipboardData(text: customer.mobileNumber));
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text('Phone number copied!'),
                                                                  duration: Duration(seconds: 1),
                                                                ),
                                                              );
                                                            },
                                                            child: const Icon(Icons.copy, color: Colors.white38, size: 13),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.location_on, color: Colors.white38, size: 14),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            customer.address.isNotEmpty ? customer.address : 'Address not recorded',
                                                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Purchases & Order History Button
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '₹${customer.totalPurchases.toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF00C853),
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${customer.totalOrders} ${customer.totalOrders == 1 ? 'order' : 'orders'}',
                                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  ElevatedButton.icon(
                                                    onPressed: () => _showOrderHistoryDialog(customer),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF1E1E2E),
                                                      foregroundColor: const Color(0xFF00C853),
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        side: BorderSide(color: const Color(0xFF00C853).withOpacity(0.3)),
                                                      ),
                                                    ),
                                                    icon: const Icon(Icons.receipt_long, size: 14),
                                                    label: const Text(
                                                      'Order History',
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
