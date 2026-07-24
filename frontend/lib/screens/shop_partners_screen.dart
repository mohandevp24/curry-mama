import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models.dart';

class ShopPartnersScreen extends StatefulWidget {
  const ShopPartnersScreen({super.key});

  @override
  State<ShopPartnersScreen> createState() => _ShopPartnersScreenState();
}

class _ShopPartnersScreenState extends State<ShopPartnersScreen> {
  List<ShopPartner> _shops = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  Future<void> _fetchShops() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final list = await ApiService.getShops();
      setState(() {
        _shops = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _deleteShop(int id) async {
    try {
      await ApiService.deleteShop(id);
      _fetchShops();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop partner removed successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showShopDialog({ShopPartner? shop}) {
    final isEdit = shop != null;
    final nameController = TextEditingController(text: shop?.name ?? '');
    final ownerController = TextEditingController(text: shop?.ownerName ?? '');
    final workersController = TextEditingController(text: shop?.workers ?? '');
    final workersMobileController = TextEditingController(text: shop?.workersMobile ?? '');
    final locationController = TextEditingController(text: shop?.location ?? '');
    final phoneController = TextEditingController(text: shop?.phoneNumber ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161E),
        title: Text(isEdit ? 'Edit Shop Partner' : 'Add Shop Partner', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    labelText: 'Shop Name',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C853))),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter shop name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ownerController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Owner Name',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C853))),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter owner name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: workersController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Workers (Comma separated)',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C853))),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: workersMobileController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Workers' Mobile Number",
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C853))),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C853))),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter location' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C853))),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter phone number' : null,
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
                  final data = {
                    'name': nameController.text.trim(),
                    'owner_name': ownerController.text.trim(),
                    'workers': workersController.text.trim(),
                    'workers_mobile': workersMobileController.text.trim(),
                    'location': locationController.text.trim(),
                    'phone_number': phoneController.text.trim(),
                  };
                  if (isEdit) {
                    await ApiService.updateShop(shop.id, data);
                  } else {
                    await ApiService.createShop(data);
                  }
                  Navigator.pop(context);
                  _fetchShops();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.black),
            child: Text(isEdit ? 'Save Changes' : 'Add Shop', style: const TextStyle(fontWeight: FontWeight.bold)),
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
               onRefresh: _fetchShops,
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
                               'Shop Partners',
                               style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                             ),
                           ],
                         ),
                         ElevatedButton.icon(
                           onPressed: () => _showShopDialog(),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: const Color(0xFF00C853),
                             foregroundColor: Colors.black,
                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           ),
                           icon: const Icon(Icons.add, size: 20),
                           label: const Text('Add Shop Partner', style: TextStyle(fontWeight: FontWeight.bold)),
                         ),
                       ],
                     ),
                     const SizedBox(height: 32),

                     if (_errorMessage.isNotEmpty)
                       Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
                     else if (_shops.isEmpty)
                       const SizedBox(
                         height: 300,
                         child: Center(
                           child: Text(
                             'No shop partners registered yet.',
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
                           childAspectRatio: 1.3,
                         ),
                         itemCount: _shops.length,
                         itemBuilder: (context, index) {
                           final shop = _shops[index];
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
                                         shop.name,
                                         style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                         maxLines: 1,
                                         overflow: TextOverflow.ellipsis,
                                       ),
                                     ),
                                     Row(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         IconButton(
                                           icon: const Icon(Icons.edit_outlined, color: Color(0xFF00C853)),
                                           onPressed: () => _showShopDialog(shop: shop),
                                         ),
                                         IconButton(
                                           icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                           onPressed: () => _deleteShop(shop.id),
                                         ),
                                       ],
                                     ),
                                   ],
                                 ),
                                 const Divider(color: Colors.white10),
                                 Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     _buildInfoRow(Icons.person_outline, 'Owner', shop.ownerName),
                                     const SizedBox(height: 6),
                                     _buildInfoRow(Icons.people_outline, 'Workers', shop.workers.isEmpty ? 'None' : shop.workers),
                                     const SizedBox(height: 6),
                                     _buildInfoRow(Icons.phone_android_outlined, 'Workers Mobile', shop.workersMobile.isEmpty ? 'None' : shop.workersMobile),
                                     const SizedBox(height: 6),
                                     _buildInfoRow(Icons.location_on_outlined, 'Location', shop.location),
                                     const SizedBox(height: 6),
                                     _buildInfoRow(Icons.phone_outlined, 'Phone', shop.phoneNumber),
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
