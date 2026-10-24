
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../models/restaurant.dart';

class RestaurantService {
  Future<List<Restaurant>> getRestaurants() async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.restaurants}',
    );

    final response = await http
        .get(url)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load restaurants: ${response.statusCode}',
      );
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(
        body['message'] ?? 'Unable to load restaurants',
      );
    }

    final List<dynamic> data = body['data'] as List<dynamic>;

    return data
        .map(
          (item) => Restaurant.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<bool> checkBackend() async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.health}',
    );

    final response = await http
        .get(url)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return false;
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;

    return body['success'] == true;
  }

  
  Future<Restaurant> addRestaurant({
    required String name,
    required String cuisine,
    String description = '',
    String imageUrl = '',
    double rating = 0,
    int deliveryTime = 30,
    double deliveryFee = 0,
    bool isOpen = true,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.restaurants}',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'cuisine': cuisine,
        'description': description,
        'imageUrl': imageUrl,
        'rating': rating,
        'deliveryTime': '$deliveryTime min',
        'deliveryFee': deliveryFee,
        'isOpen': isOpen,
      }),
    ).timeout(const Duration(seconds: 15));

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201 || body['success'] != true) {
      throw Exception(
        body['message'] ?? 'Failed to add restaurant',
      );
    }

    return Restaurant.fromJson(
      body['data'] as Map<String, dynamic>,
    );
  }

  Future<Restaurant> updateRestaurant({
    required String id,
    required String name,
    required String cuisine,
    required String description,
    required String imageUrl,
    required double rating,
    required int deliveryTime,
    required double deliveryFee,
    required bool isOpen,
    })async{
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.restaurants}/$id');
      
      final response = await http.put(url,
      headers: {'Content-Type': 'application/json'},
       body: jsonEncode({
      'name': name,
      'cuisine': cuisine,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'deliveryTime': '$deliveryTime min',
      'deliveryFee': deliveryFee,
      'isOpen': isOpen,
    }),
  ).timeout(const Duration(seconds: 15));

  final Map<String, dynamic> body =
      jsonDecode(response.body) as Map<String, dynamic>;

  if (response.statusCode != 200 || body['success'] != true) {
    throw Exception(body['message'] ?? 'Failed to update restaurant');
  }

  return Restaurant.fromJson(
    body['data'] as Map<String, dynamic>,
  );
}
Future<void> deleteRestaurant(String id) async {
  final url = Uri.parse(
    '${ApiConstants.baseUrl}${ApiConstants.restaurants}/$id',
  );

  final response = await http.delete(url).timeout(
    const Duration(seconds: 15),
  );

  final Map<String, dynamic> body =
      jsonDecode(response.body) as Map<String, dynamic>;

  if (response.statusCode != 200 || body['success'] != true) {
    throw Exception(
      body['message'] ?? 'Failed to delete restaurant',
    );
  }
}
}




