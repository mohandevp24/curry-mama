import 'dart:convert';
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
    final stockController = TextEditingController(text: product?.stock.toString() ?? '50');
    final imageUrlController = TextEditingController(
      text: product?.imageUrl ?? 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=500&auto=format&fit=crop&q=60'
    );

    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final bool isMobile = screenWidth < 700;

        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            backgroundColor: const Color(0xFF16161E),
            title: Row(
              children: [
                const Icon(Icons.shopping_bag, color: Color(0xFF00C853)),
                const SizedBox(width: 8),
                Text(
                  isEdit ? 'Edit Meat Product' : 'Add New Meat Product',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: isMobile ? screenWidth * 0.95 : 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogField(nameController, 'Product Name (e.g. Tender Chicken Wings)'),
                    const SizedBox(height: 12),
                    StatefulBuilder(
                      builder: (context, setStateDropdown) {
                        final categoriesList = ['Chicken', 'Mutton', 'Seafood', 'Eggs'];
                        final currentCategory = categoryController.text.trim();
                        if (currentCategory.isNotEmpty && !categoriesList.contains(currentCategory)) {
                          categoriesList.add(currentCategory);
                        }
                        return DropdownButtonFormField<String>(
                          value: currentCategory.isEmpty ? 'Chicken' : currentCategory,
                          dropdownColor: const Color(0xFF16161E),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Category',
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
                          items: categoriesList
                              .map((cat) => DropdownMenuItem<String>(
                                    value: cat,
                                    child: Text(cat),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setStateDropdown(() {
                                categoryController.text = val;
                              });
                            }
                          },
                        );
                      }
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(priceController, 'Price (INR)', TextInputType.number),
                    const SizedBox(height: 12),
                    _buildDialogField(weightController, 'Weight Unit (e.g. 500g, 1kg)'),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: ['250g', '500g', '750g', '1kg', '1.5kg', '2kg'].map((w) {
                          return ActionChip(
                            label: Text(w, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                            backgroundColor: const Color(0xFF1E1E2E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFF2E2E3E)),
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                weightController.text = w;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(stockController, 'Initial Stock Quantity', TextInputType.number),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDialogField(imageUrlController, 'Photo Image URL / Data'),
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
                                      reader.readAsDataUrl(file);
                                      setStateDialog(() {
                                        isUploading = true;
                                      });
                                      reader.onLoadEnd.listen((e) {
                                        final String rawUrl = reader.result as String;
                                        try {
                                          // Lock image to exact 4:3 Aspect Ratio (800x600) via canvas
                                          final img = html.ImageElement();
                                          img.src = rawUrl;
                                          img.onLoad.listen((_) {
                                            const double targetAspect = 4.0 / 3.0;
                                            final double srcAspect = img.naturalWidth / img.naturalHeight;
                                            double sx = 0, sy = 0;
                                            double sWidth = img.naturalWidth.toDouble();
                                            double sHeight = img.naturalHeight.toDouble();
                                            if (srcAspect > targetAspect) {
                                              sWidth = img.naturalHeight * targetAspect;
                                              sx = (img.naturalWidth - sWidth) / 2.0;
                                            } else {
                                              sHeight = img.naturalWidth / targetAspect;
                                              sy = (img.naturalHeight - sHeight) / 2.0;
                                            }
                                            final canvas = html.CanvasElement(width: 800, height: 600);
                                            final ctx = canvas.context2D;
                                            ctx.drawImageScaledFromSource(img, sx, sy, sWidth, sHeight, 0, 0, 800, 600);
                                            final croppedDataUrl = canvas.toDataUrl('image/jpeg', 0.88);
                                            setStateDialog(() {
                                              imageUrlController.text = croppedDataUrl;
                                              isUploading = false;
                                            });
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Meat image locked to 4:3 ratio (800x600)!'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          });
                                        } catch (cropErr) {
                                          setStateDialog(() {
                                            imageUrlController.text = rawUrl;
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
                                icon: const Icon(Icons.crop, size: 16),
                                label: const Text('Upload (4:3)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                      ],
                    ),

                    // 4:3 Image Live Preview Container
                    if (imageUrlController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.aspect_ratio, color: Color(0xFF00C853), size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Preview (Locked 4:3 Ratio):',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF00C853)),
                            ),
                            child: const Text(
                              '4:3 LOCKED',
                              style: TextStyle(color: Color(0xFF00C853), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Container(
                            color: const Color(0xFF2E2E3E),
                            child: imageUrlController.text.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(imageUrlController.text.substring(imageUrlController.text.indexOf(',') + 1)),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image, color: Colors.orangeAccent),
                                    ),
                                  )
                                : Image.network(
                                    imageUrlController.text,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image, color: Colors.orangeAccent),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
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
                  final Map<String, dynamic> data = {
                    'name': nameController.text.trim(),
                    'category': categoryController.text.trim(),
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'weight': weightController.text.trim(),
                    'stock': (int.tryParse(stockController.text.trim()) ?? 50) <= 0 ? 50 : (int.tryParse(stockController.text.trim()) ?? 50),
                    'image_url': imageUrlController.text.trim(),
                  };

                  try {
                    if (isEdit) {
                      await ApiService.updateProduct(product.id, data);
                    } else {
                      await ApiService.createProduct(data);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      _fetchProducts();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit ? 'Product updated successfully' : 'Product created successfully'),
                          backgroundColor: Colors.green[800],
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.black),
                child: Text(isEdit ? 'Save Changes' : 'Add Item', style: const TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      },
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
    final bool isMobile = width < 700;
    int crossAxisCount = 3;
    if (width < 650) {
      crossAxisCount = 1;
    } else if (width < 1050) {
      crossAxisCount = 2;
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Responsive)
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRY MAMA INVENTORY',
                      style: TextStyle(color: Colors.white24, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Meat Listings',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddEditDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add Meat Item (4:3)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                )
              : Row(
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
          SizedBox(height: isMobile ? 16 : 32),

          // Search and filters
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search chicken, mutton, seafood...',
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
          SizedBox(height: isMobile ? 16 : 32),

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
                  crossAxisSpacing: isMobile ? 14 : 24,
                  mainAxisSpacing: isMobile ? 14 : 24,
                  childAspectRatio: isMobile ? 0.95 : 0.85,
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
                        // Image layer (Locked 4:3 Aspect Ratio)
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              p.imageUrl.startsWith('data:image')
                                  ? Image.memory(
                                      base64Decode(p.imageUrl.substring(p.imageUrl.indexOf(',') + 1)),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: const Color(0xFF2E2E3E),
                                          child: const Icon(Icons.restaurant, color: Colors.white24, size: 48),
                                        );
                                      },
                                    )
                                  : Image.network(
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
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    p.category,
                                    style: const TextStyle(color: Color(0xFF00C853), fontSize: 10, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black87.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: const Text(
                                    '4:3',
                                    style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Metadata layer
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
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
