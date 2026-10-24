
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/core/constants/api_constants.dart';

class ReviewService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String get _baseUrl => '${ApiConstants.baseUrl}/reviews';

  Future<Map<String, dynamic>> getReviews(String restaurantId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/restaurant/$restaurantId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['message'] ?? 'Unable to load reviews');
  }

  Future<Map<String, dynamic>> submitReview({
    required String restaurantId,
    required int rating,
    required String comment,
  }) async {
    final token = await _storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Please sign in to submit a review.');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'restaurantId': restaurantId,
        'rating': rating,
        'comment': comment,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['message'] ?? 'Unable to submit review');
  }
}
