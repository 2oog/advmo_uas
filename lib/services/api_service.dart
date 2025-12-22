import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import '../models/menu_item.dart';
import '../models/order.dart';

class ApiService {
  static const String appName = 'advweb-uas';

  // Dynamic base URL based on platform
  static String get _baseUrlDomain {
    if (kIsWeb) {
      return 'http://localhost';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.1.54';
    } else {
      return 'http://localhost';
    }
  }

  static String get baseUrl => '$_baseUrlDomain/$appName/api';
  static String get imageBaseUrl => '$_baseUrlDomain/$appName';

  void _logResponse(http.Response response) {
    String body = response.body;
    try {
      final jsonBody = jsonDecode(body);
      const encoder = JsonEncoder.withIndent('  ');
      body = encoder.convert(jsonBody);
    } catch (_) {
      // Body is not JSON, keep as string
    }

    dev.log(
      '''${response.request?.method} ${response.request?.url}, [Status]: ${response.statusCode}, [Body]: $body
''',
      name: 'ApiService',
    );
  }

  Future<List<MenuItem>> getAllMenuItems() async {
    final response = await http.get(Uri.parse('$baseUrl/menu-items'));
    _logResponse(response);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((e) => MenuItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load menu items');
    }
  }

  Future<MenuItem> getMenuItem(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/menu-items/$id'));
    _logResponse(response);

    if (response.statusCode == 200) {
      return MenuItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load menu item');
    }
  }

  Future<List<Order>> getAllOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/orders'));
    _logResponse(response);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<Order> getOrder(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/orders/$id'));
    _logResponse(response);

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load order');
    }
  }

  Future<Order> createOrder(
    String paymentMethod,
    String tableNumber,
    List<Map<String, dynamic>> items,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'payment_method': paymentMethod,
        'table_number': tableNumber,
        'items': items,
      }),
    );
    _logResponse(response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      // API documentation says 201, but checking 200 just in case
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create order: ${response.body}');
    }
  }

  Future<Order> updateOrderStatus(int id, String paymentStatus) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'payment_status': paymentStatus}),
    );
    _logResponse(response);

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update order status');
    }
  }

  Future<bool> printOrder(int id) async {
    final response = await http.post(Uri.parse('$baseUrl/orders/$id/print'));
    _logResponse(response);

    if (response.statusCode == 200) {
      return true;
    } else {
      // Could throw an exception with the error message if needed
      // Map<String, dynamic> error = jsonDecode(response.body);
      return false;
    }
  }
}
