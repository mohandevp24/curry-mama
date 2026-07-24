import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  // Custom API key header for data security validation
  static const Map<String, String> _headers = {
    'X-API-Key': 'CurryMamaSecret2026',
  };

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'X-API-Key': 'CurryMamaSecret2026',
  };

  // Upload Product Image (Local file)
  static Future<String> uploadImage(List<int> bytes, String filename) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.headers.addAll(_headers);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);
      return jsonResponse['url'] ?? '';
    } else {
      throw Exception('Image upload failed');
    }
  }

  // 1. Fetch Analytics
  static Future<DashboardAnalytics> getAnalytics() async {
    final response = await http.get(Uri.parse('$baseUrl/analytics'), headers: _headers);
    if (response.statusCode == 200) {
      return DashboardAnalytics.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load dashboard analytics');
    }
  }

  // 2. Products API
  static Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'), headers: _headers);
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<Product> createProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: _jsonHeaders,
      body: json.encode(productData),
    );
    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create product');
    }
  }

  static Future<Product> updateProduct(int id, Map<String, dynamic> productData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: _jsonHeaders,
      body: json.encode(productData),
    );
    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update product');
    }
  }

  static Future<void> deleteProduct(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/products/$id'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }

  // 3. Orders API
  static Future<List<Order>> getOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/orders'), headers: _headers);
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => Order.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  static Future<Order> updateOrderStatus(int id, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$id'),
      headers: _jsonHeaders,
      body: json.encode({'status': status}),
    );
    if (response.statusCode == 200) {
      return Order.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update order status');
    }
  }

  static Future<Order> updatePaymentStatus(int id, String paymentStatus) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$id/payment_status'),
      headers: _jsonHeaders,
      body: json.encode({'payment_status': paymentStatus}),
    );
    if (response.statusCode == 200) {
      return Order.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update payment status');
    }
  }

  // 4. Shops API
  static Future<List<ShopPartner>> getShops() async {
    final response = await http.get(Uri.parse('$baseUrl/shops'), headers: _headers);
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => ShopPartner.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load shops');
    }
  }

  static Future<ShopPartner> createShop(Map<String, dynamic> shopData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shops'),
      headers: _jsonHeaders,
      body: json.encode(shopData),
    );
    if (response.statusCode == 200) {
      return ShopPartner.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create shop partner');
    }
  }

  static Future<ShopPartner> updateShop(int id, Map<String, dynamic> shopData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/shops/$id'),
      headers: _jsonHeaders,
      body: json.encode(shopData),
    );
    if (response.statusCode == 200) {
      return ShopPartner.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update shop partner');
    }
  }

  static Future<void> deleteShop(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/shops/$id'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete shop partner');
    }
  }

  // 5. Delivery Partners API
  static Future<List<DeliveryPartner>> getDeliveryPartners() async {
    final response = await http.get(Uri.parse('$baseUrl/delivery'), headers: _headers);
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => DeliveryPartner.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load delivery partners');
    }
  }

  static Future<DeliveryPartner> createDeliveryPartner(Map<String, dynamic> deliveryData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delivery'),
      headers: _jsonHeaders,
      body: json.encode(deliveryData),
    );
    if (response.statusCode == 200) {
      return DeliveryPartner.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create delivery partner');
    }
  }

  static Future<void> deleteDeliveryPartner(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/delivery/$id'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete delivery partner');
    }
  }

  // 6. Banners API
  static Future<List<BannerModel>> getBanners() async {
    final response = await http.get(Uri.parse('$baseUrl/banners'), headers: _headers);
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => BannerModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load banners');
    }
  }

  static Future<BannerModel> createBanner(Map<String, dynamic> bannerData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/banners'),
      headers: _jsonHeaders,
      body: json.encode(bannerData),
    );
    if (response.statusCode == 200) {
      return BannerModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create banner');
    }
  }

  static Future<BannerModel> updateBanner(int id, Map<String, dynamic> bannerData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/banners/$id'),
      headers: _jsonHeaders,
      body: json.encode(bannerData),
    );
    if (response.statusCode == 200) {
      return BannerModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update banner');
    }
  }

  static Future<void> deleteBanner(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/banners/$id'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete banner');
    }
  }
}
