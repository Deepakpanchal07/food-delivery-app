
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/constants/api_constants.dart';

import 'cart_service.dart';

class OrderService {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  Future<Map<String, dynamic>> placeOrder({
    required String customerName,
    required String phone,
    required String address,
    required String city,
    required String pincode,
  }) async {
    final cart = CartService.instance;

    if (cart.items.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    final token = await _storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Please sign in before placing an order.');
    }

    final restaurantId = cart.items.first.item.restaurantId;

    final url = Uri.parse('${ApiConstants.baseUrl}/orders');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'city': city,
        'pincode': pincode,
        'restaurantId': restaurantId,
        'items': cart.items.map((entry) {
          return {
            'menuItemId': entry.item.id,
            'quantity': entry.quantity,
          };
        }).toList(),
      }),
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201 && data['success'] == true) {
      cart.clearCart();
      return data;
    }

    throw Exception(
      data['message'] ?? data['error'] ?? 'Failed to place order',
    );
  }

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final token = await _storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Please sign in to view your orders.');
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/orders/my-orders',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      final orders = data['orders'] as List<dynamic>? ?? [];

      return orders
          .map((order) => Map<String, dynamic>.from(order as Map))
          .toList();
    }

    throw Exception(
      data['message'] ?? data['error'] ?? 'Failed to fetch orders',
    );
  }


  
Future<Map<String, dynamic>> trackOrder(String orderId) async {
  final token = await _storage.read(key: 'auth_token');

  if (token == null || token.isEmpty) {
    throw Exception('Please sign in to track your order.');
  }

  final url = Uri.parse(
    '${ApiConstants.baseUrl}/orders/track/$orderId',
  );

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  final Map<String, dynamic> data =
      jsonDecode(response.body) as Map<String, dynamic>;

  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data['order'] as Map);
  }

  throw Exception(
    data['message'] ?? 'Unable to track this order.',
  );
}


Future<Map<String, dynamic>> cancelOrder(String orderId) async {
  final token = await _storage.read(key: 'auth_token');

  if (token == null || token.isEmpty) {
    throw Exception('Please sign in to cancel your order.');
  }

  final url = Uri.parse(
    '${ApiConstants.baseUrl}/orders/$orderId/cancel',
  );

  final response = await http.patch(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  final Map<String, dynamic> data =
      jsonDecode(response.body) as Map<String, dynamic>;

  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data['order'] as Map);
  }

  throw Exception(
    data['message'] ?? 'Unable to cancel order.',
  );
}


Future<void> deleteCancelledOrder(String orderId) async {
  final token = await _storage.read(key: 'auth_token');

  if (token == null || token.isEmpty) {
    throw Exception('Please sign in to delete this order.');
  }

  final url = Uri.parse(
    '${ApiConstants.baseUrl}/orders/$orderId',
  );

  final response = await http.delete(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  final Map<String, dynamic> data =
      jsonDecode(response.body) as Map<String, dynamic>;

  if (response.statusCode == 200 && data['success'] == true) {
    return;
  }

  throw Exception(
    data['message'] ?? 'Unable to delete order.',
  );
}



}
