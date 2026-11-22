import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_service.dart';
import '../models.dart';
import '../providers/cart_provider.dart';
import '../providers/language_provider.dart';
import 'checkout_screen.dart';
import 'track_order_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _products = [];
  List<String> _bannerImages = [];
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  bool _isLoading = true;
  String _error = '';
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Chicken', 'Mutton', 'Seafood', 'Eggs'];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchBanners();
    _startBannerLoop();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _startBannerLoop() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _bannerImages.isNotEmpty) {
        setState(() {
          _currentBannerIndex = (_currentBannerIndex + 1) % _bannerImages.length;
        });
      }
    });
  }

  Future<void> _fetchBanners() async {
    try {
      final banners = await ApiService.getBanners();
      setState(() {
        _bannerImages = banners.where((b) => b.isActive).map((b) => b.imageUrl).toList();
        _currentBannerIndex = 0;
      });
    } catch (_) {
      // Backend error or offline
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final products = await ApiService.getProducts();
      setState(() {
        _products = products.where((p) => p.stock > 0).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final lang = context.watch<LanguageProvider>();
    final isMobile = MediaQuery.of(context).size.width < 800;

    List<Product> displayedProducts = _selectedCategory == 'All'
        ? _products
        : _products.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isMobile, lang),
          SliverToBoxAdapter(
            child: _buildCategoryChips(isMobile, lang),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
            )
          else if (_error.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text('Error loading menu: $_error', style: const TextStyle(color: Colors.redAccent)),
              ),
            )
          else if (displayedProducts.isEmpty)
             SliverFillRemaining(
              child: Center(
                child: Text(
                  lang.t('No products found in this category.', 'இந்த பிரிவில் பொருட்கள் இல்லை.'),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : MediaQuery.of(context).size.width * 0.15,
                vertical: 16.0,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = displayedProducts[index];
                    return _buildModernProductCard(context, product, cart, lang, isMobile);
                  },
                  childCount: displayedProducts.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: _buildBottomCartBar(context, cart, lang, isMobile),
    );
  }

  Widget _buildSliverAppBar(bool isMobile, LanguageProvider lang) {
    return SliverAppBar(
      expandedHeight: isMobile ? 180 : 260,
      toolbarHeight: isMobile ? 60 : 72,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 6,
      title: Row(
        children: [
          // Static Prominent Brand Logo (High Resolution & Clear)
          Container(
            width: isMobile ? 36 : 56,
            height: isMobile ? 36 : 56,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E28),
              borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
              border: Border.all(color: const Color(0xFF00E676), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
              child: Image.asset(
                'assets/images/logo_hd.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Static Prominent Brand Title & Subtitle (Never Hides on Scroll)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Curry Mama',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 16 : 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  lang.t('Fresh Raw Meat Delivery', 'பிரஷ் ஆட்டுக்கறி, கோழி & மீன்'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF00E676),
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Track Order Button
        IconButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackOrderScreen()));
          },
          icon: const Icon(Icons.location_on, color: Color(0xFF00E676)),
          iconSize: isMobile ? 20 : 24,
          tooltip: lang.t('Track Order', 'ஆர்டரைத் தேடு'),
        ),
        // Language Icon Button
        Padding(
          padding: EdgeInsets.only(right: isMobile ? 8.0 : 12.0),
          child: InkWell(
            onTap: () => lang.toggleLanguage(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 4 : 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E28),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, color: const Color(0xFF00E676), size: isMobile ? 15 : 18),
                  const SizedBox(width: 4),
                  Text(
                    lang.isTamil ? 'தமிழ்' : 'ENG',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_bannerImages.isNotEmpty)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: Builder(
                  key: ValueKey<int>(_currentBannerIndex),
                  builder: (context) {
                    final bannerUrl = _bannerImages[_currentBannerIndex % _bannerImages.length];
                    if (bannerUrl.startsWith('data:image')) {
                      return Image.memory(
                        base64Decode(bannerUrl.substring(bannerUrl.indexOf(',') + 1)),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                      );
                    }
                    return Image.network(
                      bannerUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                    );
                  },
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A192F), Color(0xFF172A45), Color(0xFF0F0F12)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant_menu, color: Color(0xFF00E676), size: 44),
                      const SizedBox(height: 8),
                      Text(
                        'CURRY MAMA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 22 : 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang.t('100% Fresh & Antibiotic-Free Meat', '100% பிரஷ் & சுகாதாரமான இறைச்சி'),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: isMobile ? 16 : MediaQuery.of(context).size.width * 0.15,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: Color(0xFF00E676), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          lang.t('100% Fresh & Antibiotic-Free Meat', '100% பிரஷ் & சுகாதாரமான இறைச்சி'),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(bool isMobile, LanguageProvider lang) {
    return Container(
      height: isMobile ? 50 : 60,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : MediaQuery.of(context).size.width * 0.15),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;

          // Simple translations for categories
          String displayCat = cat;
          if (lang.isTamil) {
            switch (cat) {
              case 'All': displayCat = 'எல்லாம்'; break;
              case 'Chicken': displayCat = 'கோழி'; break;
              case 'Mutton': displayCat = 'மட்டன்'; break;
              case 'Seafood': displayCat = 'கடல் உணவு'; break;
              case 'Eggs': displayCat = 'முட்டை'; break;
            }
          }

          return Padding(
            padding: EdgeInsets.only(right: isMobile ? 8.0 : 12.0, top: isMobile ? 6 : 10, bottom: isMobile ? 6 : 10),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00E676) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00E676) : Colors.white12,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  displayCat,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 15,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernProductCard(BuildContext context, Product product, CartProvider cart, LanguageProvider lang, bool isMobile) {
    final qty = cart.getQuantity(product.id);
    final options = cart.getWeightOptions(product);

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildModernProductImage(product, isMobile: true),
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: _buildModernProductDetails(product, cart, lang, qty, options, isMobile),
                ),
              ],
            )
          : Row(
              children: [
                SizedBox(
                  width: 260,
                  child: _buildModernProductImage(product, isMobile: false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildModernProductDetails(product, cart, lang, qty, options, isMobile),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildModernProductImage(Product product, {double? height, double? width, bool isMobile = true}) {
    return AspectRatio(
      aspectRatio: 4 / 3, // Locked strictly to 4:3 ratio
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: isMobile
                ? const BorderRadius.vertical(top: Radius.circular(18))
                : const BorderRadius.horizontal(left: Radius.circular(18)),
            child: product.imageUrl.startsWith('data:image')
                ? Image.memory(
                    base64Decode(product.imageUrl.substring(product.imageUrl.indexOf(',') + 1)),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.restaurant, color: Colors.white24, size: 40),
                    ),
                  )
                : Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.restaurant, color: Colors.white24, size: 40),
                    ),
                  ),
          ),
          // Glassmorphic tag
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Color(0xFF00E676), size: 12),
                  SizedBox(width: 4),
                  Text(
                    'PREMIUM',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProductDetails(Product product, CartProvider cart, LanguageProvider lang, int qty, List<Map<String, dynamic>> options, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 17 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: TextStyle(
                color: const Color(0xFF00E676),
                fontSize: isMobile ? 18 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${product.category} • ${product.weight}',
          style: TextStyle(color: Colors.white54, fontSize: isMobile ? 12 : 14),
        ),
        SizedBox(height: isMobile ? 14 : 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Dropdown
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: qty > 0 ? qty : options.first['qty'],
                  dropdownColor: const Color(0xFF1A1A1A),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00E676), size: 18),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14),
                  onChanged: (int? newQty) {
                    if (newQty != null) cart.updateQuantity(product, newQty);
                  },
                  items: options.map<DropdownMenuItem<int>>((opt) {
                    String label = opt['label'];
                    if (lang.isTamil) {
                      label = label.replaceAll('Kg', 'கிலோ').replaceAll('g', 'கிராம்');
                    }
                    return DropdownMenuItem<int>(
                      value: opt['qty'],
                      child: Text(label),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Add Button
            qty > 0
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00E676)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => cart.updateQuantity(product, qty - 1),
                          icon: const Icon(Icons.remove, color: Colors.white),
                          iconSize: isMobile ? 16 : 20,
                          padding: EdgeInsets.all(isMobile ? 6 : 8),
                          constraints: const BoxConstraints(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '$qty',
                            style: TextStyle(color: const Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16),
                          ),
                        ),
                        IconButton(
                          onPressed: () => cart.updateQuantity(product, qty + 1),
                          icon: const Icon(Icons.add, color: Colors.white),
                          iconSize: isMobile ? 16 : 20,
                          padding: EdgeInsets.all(isMobile ? 6 : 8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => cart.updateQuantity(product, options.first['qty']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32, vertical: isMobile ? 10 : 14),
                    ),
                    child: Text(
                      lang.t('ADD', 'சேர்'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 16),
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomCartBar(BuildContext context, CartProvider cart, LanguageProvider lang, bool isMobile) {
    if (cart.itemCount == 0) return const SizedBox.shrink();

    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(isMobile ? 16 : 24),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF00E676)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cart.items.length} ${lang.t('ITEM', 'பொருள்')}${cart.items.length > 1 ? (lang.isTamil ? 'கள்' : 'S') : ''}',
                      style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹${cart.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      lang.t('Checkout', 'செக்-அவுட்'),
                      style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 22),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
