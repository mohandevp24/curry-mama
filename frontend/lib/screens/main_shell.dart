import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'orders_screen.dart';
import 'shop_partners_screen.dart';
import 'delivery_partners_screen.dart';
import 'banners_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _isAuthenticated = false;
  String _enteredPin = '';
  String _errorMessage = '';

  final List<Widget> _pages = [
    const DashboardScreen(),
    const ProductsScreen(),
    const OrdersScreen(),
    const ShopPartnersScreen(),
    const DeliveryPartnersScreen(),
    const BannersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _buildPinLockScreen();
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 850;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF16161E),
              title: Text(
                'CURRY MAMA ADMIN',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white70),
            )
          : null,
      drawer: isMobile ? _buildDrawer() : null,
      body: Row(
        children: [
          if (!isMobile) ...[
            _buildSidebar(),
            const VerticalDivider(width: 1, color: Color(0xFF20202E)),
          ],
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFF16161E),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo & Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/logo_hd.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/logo.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRY MAMA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'ADMIN PANEL',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 48),
          // Navigation Items
          Expanded(
            child: Column(
              children: [
                _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined, Icons.dashboard),
                const SizedBox(height: 8),
                _buildNavItem(1, 'Meat Items', Icons.shopping_bag_outlined, Icons.shopping_bag),
                const SizedBox(height: 8),
                _buildNavItem(2, 'Orders Log', Icons.receipt_long_outlined, Icons.receipt_long),
                const SizedBox(height: 8),
                _buildNavItem(3, 'Shop Partners', Icons.storefront_outlined, Icons.storefront),
                const SizedBox(height: 8),
                _buildNavItem(4, 'Delivery Partners', Icons.local_shipping_outlined, Icons.local_shipping),
                const SizedBox(height: 8),
                _buildNavItem(5, 'Banners', Icons.view_carousel_outlined, Icons.view_carousel),
              ],
            ),
          ),
          // Footer / Version
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Curry Mama Admin v1.0.0',
              style: TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData outlineIcon, IconData filledIcon) {
    final bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? filledIcon : outlineIcon,
                color: isSelected ? Theme.of(context).primaryColor : Colors.white54,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF16161E),
      child: Column(
        children: [
          const SizedBox(height: 48),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/logo.png',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              isAntiAlias: true,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/images/logo.jpeg',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'CURRY MAMA',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: Icon(
              _selectedIndex == 0 ? Icons.dashboard : Icons.dashboard_outlined,
              color: _selectedIndex == 0 ? Theme.of(context).primaryColor : Colors.white60,
            ),
            title: Text(
              'Dashboard',
              style: TextStyle(color: _selectedIndex == 0 ? Colors.white : Colors.white60),
            ),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              _selectedIndex == 1 ? Icons.shopping_bag : Icons.shopping_bag_outlined,
              color: _selectedIndex == 1 ? Theme.of(context).primaryColor : Colors.white60,
            ),
            title: Text(
              'Meat Items',
              style: TextStyle(color: _selectedIndex == 1 ? Colors.white : Colors.white60),
            ),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              _selectedIndex == 2 ? Icons.receipt_long : Icons.receipt_long_outlined,
              color: _selectedIndex == 2 ? Theme.of(context).primaryColor : Colors.white60,
            ),
            title: Text(
              'Orders Log',
              style: TextStyle(color: _selectedIndex == 2 ? Colors.white : Colors.white60),
            ),
            selected: _selectedIndex == 2,
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              _selectedIndex == 3 ? Icons.storefront : Icons.storefront_outlined,
              color: _selectedIndex == 3 ? Theme.of(context).primaryColor : Colors.white60,
            ),
            title: Text(
              'Shop Partners',
              style: TextStyle(color: _selectedIndex == 3 ? Colors.white : Colors.white60),
            ),
            selected: _selectedIndex == 3,
            onTap: () {
              setState(() {
                _selectedIndex = 3;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              _selectedIndex == 4 ? Icons.local_shipping : Icons.local_shipping_outlined,
              color: _selectedIndex == 4 ? Theme.of(context).primaryColor : Colors.white60,
            ),
            title: Text(
              'Delivery Partners',
              style: TextStyle(color: _selectedIndex == 4 ? Colors.white : Colors.white60),
            ),
            selected: _selectedIndex == 4,
            onTap: () {
              setState(() {
                _selectedIndex = 4;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              _selectedIndex == 5 ? Icons.view_carousel : Icons.view_carousel_outlined,
              color: _selectedIndex == 5 ? Theme.of(context).primaryColor : Colors.white60,
            ),
            title: Text(
              'Banners',
              style: TextStyle(color: _selectedIndex == 5 ? Colors.white : Colors.white60),
            ),
            selected: _selectedIndex == 5,
            onTap: () {
              setState(() {
                _selectedIndex = 5;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPinLockScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 380,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF16161E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF20202E), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00C853).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _errorMessage.isNotEmpty ? Icons.lock_open_outlined : Icons.lock_outline_rounded,
                    color: _errorMessage.isNotEmpty ? Colors.redAccent : const Color(0xFF00C853),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CURRY MAMA ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage.isNotEmpty
                      ? _errorMessage
                      : 'Enter Security PIN to Unlock',
                  style: TextStyle(
                    color: _errorMessage.isNotEmpty ? Colors.redAccent : Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final isFilled = index < _enteredPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? const Color(0xFF00C853)
                            : Colors.white10,
                        border: Border.all(
                          color: isFilled
                              ? const Color(0xFF00C853)
                              : Colors.white30,
                          width: 1.5,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00C853).withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    Widget keyWidget;
                    if (index == 9) {
                      keyWidget = _buildKeypadButton(
                        child: const Text(
                          'CLEAR',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _enteredPin = '';
                            _errorMessage = '';
                          });
                        },
                      );
                    } else if (index == 10) {
                      keyWidget = _buildKeypadButton(
                        child: const Text(
                          '0',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => _handleKeyPress('0'),
                      );
                    } else if (index == 11) {
                      keyWidget = _buildKeypadButton(
                        child: const Icon(
                          Icons.backspace_outlined,
                          color: Colors.white60,
                          size: 18,
                        ),
                        onTap: () {
                          setState(() {
                            if (_enteredPin.isNotEmpty) {
                              _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
                            }
                            _errorMessage = '';
                          });
                        },
                      );
                    } else {
                      final number = (index + 1).toString();
                      keyWidget = _buildKeypadButton(
                        child: Text(
                          number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => _handleKeyPress(number),
                      );
                    }
                    return keyWidget;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton({required Widget child, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.white.withOpacity(0.05),
        splashColor: const Color(0xFF00C853).withOpacity(0.15),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF20202E).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2F2F42).withOpacity(0.5),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  void _handleKeyPress(String value) {
    if (_enteredPin.length >= 6) return;
    setState(() {
      _errorMessage = '';
      _enteredPin += value;
    });

    if (_enteredPin.length == 6) {
      if (_enteredPin == '576576') {
        setState(() {
          _isAuthenticated = true;
        });
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN! Please try again.';
          _enteredPin = '';
        });
      }
    }
  }
}
