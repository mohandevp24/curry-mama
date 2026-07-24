import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Custom API key header for database protection
  static const Map<String, String> _headers = {
    'X-API-Key': 'CurryMamaSecret2026',
  };

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'X-API-Key': 'CurryMamaSecret2026',
  };

  // 1. Fetch live products from backend
  static Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'), headers: _headers);
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  // 2. Submit customer checkout order
  static Future<void> placeOrder({
    required String customerName,
    required String mobileNumber,
    required String address,
    required String paymentMethod,
    required List<CartItem> cartItems,
    required double totalPrice,
    String paymentStatus = 'Unpaid',
    String transactionId = '',
  }) async {
    final List<Map<String, dynamic>> itemsList = cartItems.map((item) => {
      'name': item.product.name,
      'quantity': item.quantity,
      'price': item.product.price,
    }).toList();

    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: _jsonHeaders,
      body: json.encode({
        'customer_name': customerName,
        'mobile_number': mobileNumber,
        'address': address,
        'payment_method': paymentMethod,
        'items': itemsList,
        'total_price': totalPrice,
        'status': 'Pending', // Initial state is Pending for admin action
        'payment_status': paymentStatus,
        'transaction_id': transactionId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to place your order. Please try again!');
    }
  }

  // 3. Track orders by mobile number
  static Future<List<dynamic>> trackOrders(String mobileNumber) async {
    final response = await http.get(Uri.parse('$baseUrl/orders/track?mobile_number=$mobileNumber'), headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch tracking details');
    }
  }
}
