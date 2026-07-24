import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api_service.dart';
import '../providers/cart_provider.dart';
import '../providers/language_provider.dart';
import 'success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(LanguageProvider lang) async {
    if (_formKey.currentState?.validate() ?? false) {
      final cart = context.read<CartProvider>();
      final mobileNumber = _mobileController.text.trim();
      final customerName = _nameController.text.trim();
      final address = _addressController.text.trim();

      String paymentStatus = 'Unpaid';
      String txnId = 'COD-DIRECT';

      try {
        setState(() => _isLoading = true);

        // Step 1: Place Cash on Delivery Order Directly
        await ApiService.placeOrder(
          customerName: customerName,
          mobileNumber: mobileNumber,
          address: address,
          paymentMethod: _selectedPaymentMethod,
          cartItems: cart.items,
          totalPrice: cart.totalPrice,
          paymentStatus: paymentStatus,
          transactionId: txnId,
        );

        // Step 2: Send Thank You SMS Note
        await ApiService.sendThankYouSms(
          mobileNumber: mobileNumber,
          customerName: customerName,
          orderId: DateTime.now().millisecondsSinceEpoch % 10000,
          totalAmount: cart.totalPrice,
        );

        final orderTotal = cart.totalPrice;
        cart.clearCart();
        setState(() => _isLoading = false);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => SuccessScreen(
                customerName: customerName,
                orderTotal: orderTotal,
              ),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
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
          lang.t('Checkout', 'செக்-அவுட்'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF00E676)),
                  const SizedBox(height: 16),
                  Text(lang.t('Placing your order...', 'ஆர்டர் வைக்கப்படுகிறது...'), style: const TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : MediaQuery.of(context).size.width * 0.2,
                vertical: 24.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary
                    _buildSectionTitle(Icons.shopping_cart_checkout, lang.t('Order Summary', 'ஆர்டர் சுருக்கம்')),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.1), width: 1.5),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ...cart.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      item.product.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text(cart.getFormattedTotalWeight(item).replaceAll('Kg', lang.isTamil ? 'கிலோ' : 'Kg'), style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${(item.product.price * item.quantity).toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const Divider(color: Colors.white10, height: 40, thickness: 1.5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(lang.t('Total Amount', 'மொத்த தொகை'), style: const TextStyle(color: Colors.white70, fontSize: 18)),
                              Text(
                                '₹${cart.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(color: Color(0xFF00E676), fontSize: 28, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Delivery Details
                    _buildSectionTitle(Icons.local_shipping, lang.t('Delivery Details', 'டெலிவரி விபரங்கள்')),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.1), width: 1.5),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildModernTextField(
                            controller: _nameController,
                            label: lang.t('Full Name', 'முழு பெயர்'),
                            icon: Icons.person,
                            validatorMsg: lang.t('Please enter your name', 'உங்கள் பெயரை எழுதவும்'),
                          ),
                          const SizedBox(height: 20),
                          _buildModernTextField(
                            controller: _mobileController,
                            label: lang.t('Mobile Number', 'மொபைல் எண்'),
                            icon: Icons.phone_android,
                            isPhone: true,
                            validatorMsg: lang.t('Please enter valid mobile', 'சரியான மொபைல் எண்ணை எழுதவும்'),
                          ),
                          const SizedBox(height: 20),
                          _buildModernTextField(
                            controller: _addressController,
                            label: lang.t('Full Address', 'முழு முகவரி'),
                            icon: Icons.location_on,
                            maxLines: 3,
                            validatorMsg: lang.t('Please enter your address', 'உங்கள் முகவரியை எழுதவும்'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Payment Method
                    _buildSectionTitle(Icons.payments, lang.t('Payment Method', 'கட்டண முறை')),
                    const SizedBox(height: 16),
                    _buildPaymentOption('Cash on Delivery', Icons.money, lang.t('Pay cash when fresh meat arrives', 'இறைச்சி வரும்போது பணம் செலுத்தவும்'), lang),
                    const SizedBox(height: 48),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _submitOrder(lang),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          '${lang.t('Place Order', 'ஆர்டர் செய்')} - ₹${cart.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF00E676), size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPhone = false,
    int maxLines = 1,
    required String validatorMsg,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        hintText: label,
        hintStyle: const TextStyle(color: Colors.white30, fontWeight: FontWeight.normal),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? 40.0 : 0),
          child: Icon(icon, color: const Color(0xFF00E676)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return validatorMsg;
        if (isPhone && value.trim().length < 10) return validatorMsg;
        return null;
      },
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, String subtitle, LanguageProvider lang) {
    final isSelected = _selectedPaymentMethod == title;
    
    String displayTitle = title;
    if (lang.isTamil) {
      if (title == 'Cash on Delivery') displayTitle = 'பணம் செலுத்துதல்';
      if (title == 'Online Payment') displayTitle = 'ஆன்லைன் கட்டணம்';
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E676).withOpacity(0.1) : const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E676) : Colors.white10,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF00E676) : Colors.white54, size: 36),
            const SizedBox(height: 12),
            Text(
              displayTitle, 
              style: TextStyle(
                color: isSelected ? const Color(0xFF00E676) : Colors.white, 
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, 
                fontSize: 14
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
