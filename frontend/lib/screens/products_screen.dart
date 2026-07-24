import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../api_service.dart';
import '../models.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final list = await ApiService.getProducts();
      setState(() {
        _products = list;
        _filteredProducts = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((p) {
        return p.name.toLowerCase().contains(query) || p.category.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _deleteProduct(int id) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161E),
        title: const Text('Delete Product', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this meat item?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await ApiService.deleteProduct(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully'), backgroundColor: Colors.green),
      );
      _fetchProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddEditDialog([Product? product]) {
    final bool isEdit = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final categoryController = TextEditingController(text: product?.category ?? 'Chicken');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final weightController = TextEditingController(text: product?.weight ?? '500g');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '10');
    final imageUrlController = TextEditingController(
      text: product?.imageUrl ?? 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=500&auto=format&fit=crop&q=60'
    );

    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF16161E),
          title: Text(isEdit ? 'Edit Meat Product' : 'Add New Meat Product', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(nameController, 'Product Name (e.g. Tender Chicken Wings)'),
                const SizedBox(height: 12),
                _buildDialogField(categoryController, 'Category (Chicken, Mutton, Seafood, Marinated)'),
                const SizedBox(height: 12),
                _buildDialogField(priceController, 'Price (INR)', TextInputType.number),
                const SizedBox(height: 12),
                _buildDialogField(weightController, 'Weight Unit (e.g. 500g, 1kg)'),
                const SizedBox(height: 12),
                _buildDialogField(stockController, 'Initial Stock Quantity', TextInputType.number),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDialogField(imageUrlController, 'Photo Image URL'),
                    ),
                    const SizedBox(width: 8),
                    isUploading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Color(0xFF00C853), strokeWidth: 2),
                          )
                        : ElevatedButton.icon(
                            onPressed: () {
                              final html.FileUploadInputElement input = html.FileUploadInputElement()..accept = 'image/*';
                              input.click();
                              input.onChange.listen((e) {
                                final files = input.files;
                                if (files != null && files.isNotEmpty) {
                                  final file = files[0];
                                  final reader = html.FileReader();
                                  reader.readAsArrayBuffer(file);
                                  reader.onLoadEnd.listen((e) async {
                                    setStateDialog(() {
                                      isUploading = true;
                                    });
                                    try {
                                      final bytes = reader.result as List<int>;
                                      final url = await ApiService.uploadImage(bytes, file.name);
                                      imageUrlController.text = url;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Image uploaded successfully!'), backgroundColor: Colors.green),
                                      );
                                    } catch (err) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Upload failed: $err'), backgroundColor: Colors.red),
                                      );
                                    } finally {
                                      setStateDialog(() {
                                        isUploading = false;
                                      });
                                    }
                                  });
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E1E2E),
                              foregroundColor: const Color(0xFF00C853),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: const Text('Upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
          ElevatedButton(
            onPressed: () async {
              final Map<String, dynamic> data = {
                'name': nameController.text,
                'category': categoryController.text,
                'price': double.tryParse(priceController.text) ?? 0.0,
                'weight': weightController.text,
                'stock': int.tryParse(stockController.text) ?? 0,
                'image_url': imageUrlController.text,
              };

              try {
                if (isEdit) {
                  await ApiService.updateProduct(product.id, data);
                } else {
                  await ApiService.createProduct(data);
                }
                Navigator.pop(context);
                _fetchProducts();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Product updated successfully' : 'Product created successfully'),
                    backgroundColor: Colors.green[800],
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.black),
            child: Text(isEdit ? 'Save Changes' : 'Add Item', style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      )),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, [TextInputType keyboardType = TextInputType.text]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF00C853)),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    int crossAxisCount = 3;
    if (width < 600) {
      crossAxisCount = 1;
    } else if (width < 1000) {
      crossAxisCount = 2;
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'CURRY MAMA INVENTORY',
                    style: TextStyle(color: Colors.white24, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Meat Listings',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Meat Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              )
            ],
          ),
          const SizedBox(height: 32),

          // Search and filters
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by chicken, mutton, seafood category or product name...',
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF00C853)),
              filled: true,
              fillColor: const Color(0xFF16161E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Main Inventory Grid
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF00C853))),
            )
          else if (_filteredProducts.isEmpty)
            const Expanded(
              child: Center(child: Text('No meat items matched your criteria.', style: TextStyle(color: Colors.white38))),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 0.85,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final p = _filteredProducts[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image layer
                        Expanded(
                          flex: 4,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                p.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF2E2E3E),
                                    child: const Icon(Icons.restaurant, color: Colors.white24, size: 48),
                                  );
                                },
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    p.category,
                                    style: const TextStyle(color: Color(0xFF00C853), fontSize: 10, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        // Metadata layer
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Weight pack: ${p.weight}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '₹${p.price}',
                                      style: const TextStyle(color: Color(0xFF00C853), fontSize: 18, fontWeight: FontWeight.w900),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: p.stock > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p.stock > 0 ? 'Stock: ${p.stock}' : 'Out of Stock',
                                        style: TextStyle(
                                          color: p.stock > 0 ? Colors.green[400] : Colors.red[400],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const Divider(color: Color(0xFF2E2E3E), height: 1),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showAddEditDialog(p),
                                      icon: const Icon(Icons.edit, size: 16, color: Color(0xFF00C853)),
                                      label: const Text('Edit', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _deleteProduct(p.id),
                                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                      label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}
