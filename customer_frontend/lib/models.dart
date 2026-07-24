class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final String weight;
  final int stock;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.weight,
    required this.stock,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      weight: json['weight'] ?? '',
      stock: json['stock'] ?? 0,
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}

class BannerData {
  final int id;
  final String imageUrl;
  final String title;
  final bool isActive;

  BannerData({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.isActive,
  });

  factory BannerData.fromJson(Map<String, dynamic> json) {
    return BannerData(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      title: json['title'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}
