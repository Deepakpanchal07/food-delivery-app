
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/auth/services/auth_service.dart';

class AdminCustomerService {
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> getCustomers({
    String search = '',
  }) async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please sign in again.');
    }

    final query = search.trim();

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/auth/customers',
    ).replace(
      queryParameters: query.isEmpty
          ? null
          : {'search': query},
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
            'Unable to load customers.',
      );
    }

    final data = decoded['data'];

    if (data is! List) {
      throw Exception('Invalid customers data.');
    }

    return data
        .whereType<Map>()
        .map(
          (customer) => Map<String, dynamic>.from(customer),
        )
        .toList();
  }
}
