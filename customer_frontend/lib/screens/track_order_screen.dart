import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_service.dart';
import '../providers/language_provider.dart';

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final _mobileController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _orders = [];
  bool _searched = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _trackOrders(LanguageProvider lang) async {
    final mobile = _mobileController.text.trim();
    if (mobile.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('Enter valid mobile number', 'சரியான மொபைல் எண்ணை உள்ளிடவும்')), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _searched = true;
    });

    try {
      final orders = await ApiService.trackOrders(mobile);
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF00E676)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lang.t('Track Order', 'ஆர்டரைத் தேடு'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : MediaQuery.of(context).size.width * 0.2,
          vertical: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.t('Enter your mobile number to check order status:', 'ஆர்டர் நிலையை அறிய உங்கள் மொபைல் எண்ணை உள்ளிடவும்:'),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      hintText: lang.t('Mobile Number', 'மொபைல் எண்'),
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(Icons.phone_android, color: Color(0xFF00E676)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _trackOrders(lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.search),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            if (_searched && !_isLoading)
              if (_orders.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, color: Colors.white24, size: 80),
                      const SizedBox(height: 16),
                      Text(
                        lang.t('No orders found for this number.', 'இந்த எண்ணிற்கு ஆர்டர்கள் ஏதும் இல்லை.'),
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('Your Orders', 'உங்கள் ஆர்டர்கள்'),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 20),
                    ..._orders.map((order) {
                      final status = order['status'] ?? 'Pending';
                      final orderId = order['id'].toString();
                      final date = order['created_at'] != null 
                        ? DateTime.tryParse(order['created_at'])?.toLocal().toString().split('.')[0] ?? '' 
                        : '';
                      
                      Color statusColor = Colors.orange;
                      IconData statusIcon = Icons.hourglass_empty;
                      
                      if (status.toLowerCase() == 'completed') {
                        statusColor = const Color(0xFF00E676);
                        statusIcon = Icons.check_circle;
                      } else if (status.toLowerCase() == 'cancelled') {
                        statusColor = Colors.redAccent;
                        statusIcon = Icons.cancel;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #$orderId',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(statusIcon, color: statusColor, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        status,
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(date, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                            const SizedBox(height: 16),
                            Text(
                              '₹${order['total_price']}',
                              style: const TextStyle(color: Color(0xFF00E676), fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
