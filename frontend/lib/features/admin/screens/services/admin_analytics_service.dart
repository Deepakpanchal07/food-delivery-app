
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/auth/services/auth_service.dart';

class AdminAnalyticsService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getAnalytics() async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please sign in again.');
    }

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/orders/admin/analytics',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response from server.');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        decoded['message']?.toString() ??
            'Unable to load analytics.',
      );
    }

    final analytics = decoded['analytics'];

    if (analytics is! Map) {
      throw Exception('Invalid analytics data.');
    }

    return Map<String, dynamic>.from(analytics);
  }
}
