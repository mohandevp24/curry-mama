import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models.dart';

class DeliveryPartnersScreen extends StatefulWidget {
  const DeliveryPartnersScreen({super.key});

  @override
  State<DeliveryPartnersScreen> createState() => _DeliveryPartnersScreenState();
}

class _DeliveryPartnersScreenState extends State<DeliveryPartnersScreen> {
  List<DeliveryPartner> _partners = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPartners();
  }

  Future<void> _fetchPartners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final list = await ApiService.getDeliveryPartners();
      setState(() {
        _partners = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _deletePartner(int id) async {
    try {
      await ApiService.deleteDeliveryPartner(id);
      _fetchPartners();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery partner removed successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddPartnerDialog() {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final locationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161E),
        title: const Text('Add Delivery Partner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Delivery Boy Name',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C853))),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: mobileController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C853))),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter mobile number' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Location / Hub Area',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C853))),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter location' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await ApiService.createDeliveryPartner({
                    'name': nameController.text.trim(),
                    'mobile_number': mobileController.text.trim(),
                    'location': locationController.text.trim(),
                  });
                  Navigator.pop(context);
                  _fetchPartners();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.black),
            child: const Text('Add Partner', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width < 700 ? 1 : (width < 1200 ? 2 : 3);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
          : RefreshIndicator(
              onRefresh: _fetchPartners,
              color: const Color(0xFF00C853),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Curry Mama Admin',
                              style: TextStyle(color: Colors.white24, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Delivery Partners',
                              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddPartnerDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add Delivery Partner', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (_errorMessage.isNotEmpty)
                      Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
                    else if (_partners.isEmpty)
                      const SizedBox(
                        height: 300,
                        child: Center(
                          child: Text(
                            'No delivery partners registered yet.',
                            style: TextStyle(color: Colors.white38, fontSize: 16),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 1.8,
                        ),
                        itemCount: _partners.length,
                        itemBuilder: (context, index) {
                          final partner = _partners[index];
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16161E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        partner.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _deletePartner(partner.id),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(Icons.phone_outlined, 'Mobile', partner.mobileNumber),
                                    const SizedBox(height: 6),
                                    _buildInfoRow(Icons.location_on_outlined, 'Hub Location', partner.location),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF00C853)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
