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
    String raw = product.weight.trim().toLowerCase();
    if (raw.isEmpty) {
      raw = '500g';
    }

    // Check if kg: e.g. "1kg", "1 kg", "1.5kg", "2kg"
    final kgRegex = RegExp(r'^([0-9]+(?:\.[0-9]+)?)\s*k(?:g|gs)?$');
    final kgMatch = kgRegex.firstMatch(raw);
    if (kgMatch != null) {
      double baseKg = double.tryParse(kgMatch.group(1)!) ?? 1.0;
      List<Map<String, dynamic>> list = [];
      for (int i = 1; i <= 10; i++) {
        double currentKg = baseKg * i;
        String label = (currentKg % 1 == 0) ? '${currentKg.toInt()} Kg' : '${currentKg.toStringAsFixed(1)} Kg';
        list.add({'label': label, 'qty': i});
      }
      return list;
    }

    // Check if grams: e.g. "250g", "500g", "750g"
    final gRegex = RegExp(r'^([0-9]+(?:\.[0-9]+)?)\s*g(?:ms|ram|rams)?$');
    final gMatch = gRegex.firstMatch(raw);
    if (gMatch != null) {
      double baseG = double.tryParse(gMatch.group(1)!) ?? 500.0;
      List<Map<String, dynamic>> list = [];
      for (int i = 1; i <= 10; i++) {
        double currentG = baseG * i;
        String label;
        if (currentG >= 1000) {
          double kg = currentG / 1000.0;
          label = (kg % 1 == 0) ? '${kg.toInt()} Kg' : '${kg.toStringAsFixed(1)} Kg';
        } else {
          label = (currentG % 1 == 0) ? '${currentG.toInt()}g' : '${currentG.toStringAsFixed(0)}g';
        }
        list.add({'label': label, 'qty': i});
      }
      return list;
    }

    // Fallback for custom labels (e.g. "1 Pack", "Piece")
    return List.generate(10, (index) {
      int q = index + 1;
      return {
        'label': q == 1 ? product.weight : '$q × ${product.weight}',
        'qty': q,
      };
    });
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
