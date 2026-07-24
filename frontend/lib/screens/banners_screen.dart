import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';
import '../models.dart';

class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final list = await ApiService.getBanners();
      setState(() {
        _banners = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _deleteBanner(int id) async {
    try {
      await ApiService.deleteBanner(id);
      _fetchBanners();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner deleted successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete banner: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleActive(BannerModel banner) async {
    try {
      await ApiService.updateBanner(banner.id, {
        'image_url': banner.imageUrl,
        'title': banner.title,
        'is_active': !banner.isActive,
      });
      _fetchBanners();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddBannerDialog({BannerModel? existingBanner}) {
    final isEditing = existingBanner != null;
    final titleController = TextEditingController(text: existingBanner?.title ?? '');
    final urlController = TextEditingController(text: existingBanner?.imageUrl ?? '');
    final formKey = GlobalKey<FormState>();
    
    // Default mode: 0 for Upload from Gallery, 1 for URL Link
    int selectedOptionIndex = (isEditing && existingBanner.imageUrl.startsWith('http')) ? 1 : 0;
    bool isUploading = false;
    String currentImageUrl = existingBanner?.imageUrl ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF16161E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF00C853), width: 1.5),
            ),
            title: Row(
              children: [
                const Icon(Icons.view_carousel, color: Color(0xFF00C853)),
                const SizedBox(width: 10),
                Text(
                  isEditing ? 'Edit Home Banner' : 'Add Home Banner',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Title Input
                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Banner Title (e.g. Quality Chicken)',
                          labelStyle: TextStyle(color: Colors.white60),
                          prefixIcon: Icon(Icons.title, color: Color(0xFF00C853)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00C853), width: 2),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter banner title' : null,
                      ),
                      const SizedBox(height: 20),

                      // Image Source Selection Header
                      const Text(
                        'Select Image Option:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 10),

                      // 2 Option Buttons: Upload from Gallery vs URL Link
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedOptionIndex = 0;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: selectedOptionIndex == 0
                                      ? const Color(0xFF00C853).withOpacity(0.2)
                                      : const Color(0xFF22222E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedOptionIndex == 0 ? const Color(0xFF00C853) : Colors.white10,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_library,
                                      color: selectedOptionIndex == 0 ? const Color(0xFF00C853) : Colors.white60,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Upload from Gallery',
                                      style: TextStyle(
                                        color: selectedOptionIndex == 0 ? const Color(0xFF00C853) : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedOptionIndex = 1;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: selectedOptionIndex == 1
                                      ? const Color(0xFF00C853).withOpacity(0.2)
                                      : const Color(0xFF22222E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedOptionIndex == 1 ? const Color(0xFF00C853) : Colors.white10,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.link,
                                      color: selectedOptionIndex == 1 ? const Color(0xFF00C853) : Colors.white60,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'URL Link',
                                      style: TextStyle(
                                        color: selectedOptionIndex == 1 ? const Color(0xFF00C853) : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Option 1: Gallery Upload Box with Green Button
                      if (selectedOptionIndex == 0) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22222E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_upload_outlined, color: Color(0xFF00C853), size: 40),
                              const SizedBox(height: 8),
                              const Text(
                                'Select banner image from device gallery',
                                style: TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: isUploading
                                    ? null
                                    : () async {
                                        final picker = ImagePicker();
                                        final picked = await picker.pickImage(source: ImageSource.gallery);
                                        if (picked != null) {
                                          setDialogState(() => isUploading = true);
                                          try {
                                            final bytes = await picked.readAsBytes();
                                            final url = await ApiService.uploadImage(bytes, picked.name);
                                            setDialogState(() {
                                              currentImageUrl = url;
                                              urlController.text = url;
                                              isUploading = false;
                                            });
                                          } catch (e) {
                                            setDialogState(() => isUploading = false);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
                                              );
                                            }
                                          }
                                        }
                                      },
                                icon: isUploading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.photo_library, color: Colors.black),
                                label: Text(
                                  isUploading ? 'Uploading...' : 'Upload from Gallery',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00C853),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Option 2: URL Link Text Field
                      if (selectedOptionIndex == 1) ...[
                        TextFormField(
                          controller: urlController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'URL Link',
                            hintText: 'https://example.com/image.jpg',
                            hintStyle: TextStyle(color: Colors.white30),
                            labelStyle: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold),
                            prefixIcon: Icon(Icons.link, color: Color(0xFF00C853)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF00C853)),
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF00C853), width: 2),
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          onChanged: (val) {
                            setDialogState(() {
                              currentImageUrl = val.trim();
                            });
                          },
                          validator: (v) {
                            if (selectedOptionIndex == 1 && (v == null || v.trim().isEmpty)) {
                              return 'Please enter a valid image URL link';
                            }
                            return null;
                          },
                        ),
                      ],

                      // Image Preview Container
                      if (currentImageUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Preview:',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 130,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              border: Border.all(color: const Color(0xFF00C853).withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.network(
                              currentImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.broken_image, color: Colors.orangeAccent, size: 36),
                                    SizedBox(height: 4),
                                    Text('Unable to load image URL preview', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final finalUrl = urlController.text.trim().isNotEmpty
                        ? urlController.text.trim()
                        : currentImageUrl;

                    if (finalUrl.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an image or enter a URL!'), backgroundColor: Colors.orange),
                      );
                      return;
                    }

                    try {
                      if (isEditing) {
                        await ApiService.updateBanner(existingBanner.id, {
                          'title': titleController.text.trim(),
                          'image_url': finalUrl,
                          'is_active': existingBanner.isActive,
                        });
                      } else {
                        await ApiService.createBanner({
                          'title': titleController.text.trim(),
                          'image_url': finalUrl,
                          'is_active': true,
                        });
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        _fetchBanners();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing ? 'Banner updated successfully!' : 'Banner added successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Operation failed: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  isEditing ? 'Update Banner' : 'Save Banner',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannerImageCard(BannerModel banner) {
    return Image.network(
      banner.imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFF1F1F2C),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF00C853), strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF1F1F2C),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_not_supported_outlined, color: Colors.amber, size: 36),
              const SizedBox(height: 6),
              Text(
                banner.title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              const Text(
                'Image preview error',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Banners Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage dynamic banners displayed on customer home screen slider',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddBannerDialog(),
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text('Add Banner', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content Grid Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error loading banners: $_errorMessage', style: const TextStyle(color: Colors.redAccent)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchBanners,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _banners.isEmpty
                          ? const Center(
                              child: Text(
                                'No banners found. Click "+ Add Banner" to add a new banner!',
                                style: TextStyle(color: Colors.white54, fontSize: 16),
                              ),
                            )
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 380,
                                mainAxisExtent: 220,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _banners.length,
                              itemBuilder: (context, index) {
                                final banner = _banners[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16161E),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: banner.isActive ? const Color(0xFF00C853).withOpacity(0.3) : Colors.white10,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                              child: _buildBannerImageCard(banner),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: banner.isActive
                                                      ? const Color(0xFF00C853).withOpacity(0.9)
                                                      : Colors.grey.withOpacity(0.9),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  banner.isActive ? 'Active' : 'Inactive',
                                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                banner.title,
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    banner.isActive ? Icons.visibility : Icons.visibility_off,
                                                    color: banner.isActive ? const Color(0xFF00C853) : Colors.white38,
                                                    size: 20,
                                                  ),
                                                  onPressed: () => _toggleActive(banner),
                                                  tooltip: banner.isActive ? 'Deactivate Banner' : 'Activate Banner',
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                                                  onPressed: () => _showAddBannerDialog(existingBanner: banner),
                                                  tooltip: 'Edit Banner',
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                                  onPressed: () => _deleteBanner(banner.id),
                                                  tooltip: 'Delete Banner',
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
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
    );
  }
}
