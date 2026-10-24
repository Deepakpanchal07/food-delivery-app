
import 'dart:convert';

import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/restaurants/models/menu_item.dart';
import 'package:http/http.dart' as http;

class MenuService {
  final String baseUrl = ApiConstants.baseUrl;

  // Get all menu items for a restaurant
  Future<List<MenuItem>> getMenu(String restaurantId) async {
    final url = Uri.parse(
      '$baseUrl/menu/restaurant/$restaurantId',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
      },
    );

    print('GET MENU URL: $url');
    print('GET MENU STATUS: ${response.statusCode}');
    print('GET MENU RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);

      List<dynamic> items;

      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final dynamic result =
            decoded['menuItems'] ?? decoded['data'];

        if (result is List) {
          items = result;
        } else {
          throw Exception(
            'Unexpected menu response: ${response.body}',
          );
        }
      } else {
        throw Exception('Invalid menu response format');
      }

      return items.map((item) {
        return MenuItem.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();
    }

    throw Exception(
      'Failed to load menu: '
      '${response.statusCode} ${response.body}',
    );
  }

  // Add a new food item
  Future<MenuItem> addMenuItem({
    required String restaurantId,
    required String name,
    required String description,
    required double price,
    String imageUrl = '',
    String category = 'Main Course',
  }) async {
    final url = Uri.parse('$baseUrl/menu');

    final Map<String, dynamic> requestBody = {
      'restaurantId': restaurantId,
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'imageUrl': imageUrl.trim(),
      'category': category,
      'isAvailable': true,
    };

    final String encodedBody = jsonEncode(requestBody);

    print('========== ADD FOOD REQUEST ==========');
    print('URL: $url');
    print('METHOD: POST');
    print('CONTENT TYPE: application/json');
    print('REQUEST BODY: $encodedBody');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: encodedBody,
    );

    print('========== ADD FOOD RESPONSE ==========');
    print('STATUS CODE: ${response.statusCode}');
    print('RESPONSE BODY: ${response.body}');

    if (response.statusCode == 201) {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final dynamic itemData =
            decoded['menuItem'] ?? decoded['data'];

        if (itemData is Map) {
          return MenuItem.fromJson(
            Map<String, dynamic>.from(itemData),
          );
        }

        // If the API directly returns the created menu item.
        if (decoded.containsKey('_id') ||
            decoded.containsKey('id')) {
          return MenuItem.fromJson(decoded);
        }
      }

      throw Exception(
        'Food was created, but response format is unexpected: '
        '${response.body}',
      );
    }

    throw Exception(
      'Failed to add food item: '
      '${response.statusCode} ${response.body}',
    );
  }

  
  Future<MenuItem> updateMenuItem({
    required String id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    bool? isAvailable,
  }) async {
    final url = Uri.parse('$baseUrl/menu/$id');

    final Map<String, dynamic> body = {};

    if (name != null) body['name'] = name.trim();
    if (description != null) body['description'] = description.trim();
    if (price != null) body['price'] = price;
    if (imageUrl != null) body['imageUrl'] = imageUrl.trim();
    if (category != null) body['category'] = category;
    if (isAvailable != null) body['isAvailable'] = isAvailable;

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final item = decoded['menuItem'] ?? decoded['data'];

      if (item is Map) {
        return MenuItem.fromJson(Map<String, dynamic>.from(item));
      }

      throw Exception('Unexpected update response: ${response.body}');
    }

    throw Exception(
      'Failed to update food item: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> deleteMenuItem(String id) async {
    final url = Uri.parse('$baseUrl/menu/$id');

    final response = await http.delete(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete food item: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<MenuItem> updateAvailability({
    required String id,
    required bool isAvailable,
  }) async {
    final url = Uri.parse('$baseUrl/menu/$id/availability');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'isAvailable': isAvailable}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final item = decoded['menuItem'] ?? decoded['data'];

      if (item is Map) {
        return MenuItem.fromJson(Map<String, dynamic>.from(item));
      }

      throw Exception('Unexpected availability response: ${response.body}');
    }

    throw Exception(
      'Failed to update availability: ${response.statusCode} ${response.body}',
    );
  }

}
