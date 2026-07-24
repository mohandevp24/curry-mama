import 'package:flutter/material.dart';
import '../models.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get totalPrice {
    return _items.fold(0, (total, current) => total + (current.product.price * current.quantity));
  }

  int get itemCount {
    return _items.fold(0, (total, current) => total + current.quantity);
  }

  void updateQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      _items.removeWhere((item) => item.product.id == product.id);
    } else {
      final index = _items.indexWhere((item) => item.product.id == product.id);
      if (index >= 0) {
        _items[index].quantity = quantity;
      } else {
        _items.add(CartItem(product: product, quantity: quantity));
      }
    }
    notifyListeners();
  }

  int getQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      return _items[index].quantity;
    }
    return 0;
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> getWeightOptions(Product product) {
    if (product.category.toLowerCase() == 'chicken') {
      return [
        {'label': '500g', 'qty': 1},
        {'label': '1 Kg', 'qty': 2},
        {'label': '1.5 Kg', 'qty': 3},
        {'label': '2 Kg', 'qty': 4},
        {'label': '2.5 Kg', 'qty': 5},
        {'label': '3 Kg', 'qty': 6},
        {'label': '3.5 Kg', 'qty': 7},
        {'label': '4 Kg', 'qty': 8},
        {'label': '4.5 Kg', 'qty': 9},
        {'label': '5 Kg', 'qty': 10},
      ];
    } else {
      return [
        {'label': '250g', 'qty': 1},
        {'label': '500g', 'qty': 2},
        {'label': '750g', 'qty': 3},
        {'label': '1 Kg', 'qty': 4},
        {'label': '1.25 Kg', 'qty': 5},
        {'label': '1.5 Kg', 'qty': 6},
        {'label': '1.75 Kg', 'qty': 7},
        {'label': '2 Kg', 'qty': 8},
      ];
    }
  }

  String getFormattedTotalWeight(CartItem item) {
    final options = getWeightOptions(item.product);
    final selectedOption = options.firstWhere(
      (opt) => opt['qty'] == item.quantity,
      orElse: () => options.first,
    );
    return selectedOption['label'] as String;
  }
}
