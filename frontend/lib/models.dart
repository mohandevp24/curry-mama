import 'dart:convert';

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'weight': weight,
      'stock': stock,
      'image_url': imageUrl,
    };
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}

class Order {
  final int id;
  final String customerName;
  final String mobileNumber;
  final String address;
  final String paymentMethod;
  final List<OrderItem> items;
  final double totalPrice;
  final String status;
  final String date;
  final String paymentStatus;
  final String transactionId;

  Order({
    required this.id,
    required this.customerName,
    required this.mobileNumber,
    required this.address,
    required this.paymentMethod,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.date,
    required this.paymentStatus,
    required this.transactionId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<OrderItem> parsedItems = itemsList.map((i) => OrderItem.fromJson(i)).toList();

    return Order(
      id: json['id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      address: json['address'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      items: parsedItems,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Pending',
      date: json['date'] ?? '',
      paymentStatus: json['payment_status'] ?? 'Unpaid',
      transactionId: json['transaction_id'] ?? '',
    );
  }
}

class DailySale {
  final String date;
  final double revenue;
  final int orders;

  DailySale({
    required this.date,
    required this.revenue,
    required this.orders,
  });

  factory DailySale.fromJson(Map<String, dynamic> json) {
    return DailySale(
      date: json['date'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      orders: json['orders'] ?? 0,
    );
  }
}

class DashboardAnalytics {
  final double totalRevenue;
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final List<DailySale> dailySales;

  DashboardAnalytics({
    required this.totalRevenue,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
    required this.dailySales,
  });

  factory DashboardAnalytics.fromJson(Map<String, dynamic> json) {
    var list = json['daily_sales'] as List? ?? [];
    List<DailySale> parsedSales = list.map((i) => DailySale.fromJson(i)).toList();

    return DashboardAnalytics(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      dailySales: parsedSales,
    );
  }
}

class ShopPartner {
  final int id;
  final String name;
  final String ownerName;
  final String workers;
  final String workersMobile;
  final String location;
  final String phoneNumber;

  ShopPartner({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.workers,
    required this.workersMobile,
    required this.location,
    required this.phoneNumber,
  });

  factory ShopPartner.fromJson(Map<String, dynamic> json) {
    return ShopPartner(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      ownerName: json['owner_name'] ?? '',
      workers: json['workers'] ?? '',
      workersMobile: json['workers_mobile'] ?? '',
      location: json['location'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_name': ownerName,
      'workers': workers,
      'workers_mobile': workersMobile,
      'location': location,
      'phone_number': phoneNumber,
    };
  }
}

class DeliveryPartner {
  final int id;
  final String name;
  final String mobileNumber;
  final String location;

  DeliveryPartner({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.location,
  });

  factory DeliveryPartner.fromJson(Map<String, dynamic> json) {
    return DeliveryPartner(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      location: json['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile_number': mobileNumber,
      'location': location,
    };
  }
}

class BannerModel {
  final int id;
  final String imageUrl;
  final String title;
  final bool isActive;
  final String createdAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.isActive,
    required this.createdAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      title: json['title'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'title': title,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}
