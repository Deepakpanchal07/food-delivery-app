
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';

class AuthService {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';


  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );

    final result = _handleResponse(response);
    // await _saveToken(result);

    return result;
  }


  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final result = _handleResponse(response);
    await _saveToken(result);

    return result;
  }

        Future<Map<String, dynamic>> verifyEmailOtp({
  required String email,
  required String otp,
}) async {
  final response = await http.post(
    Uri.parse(
      '${ApiConstants.baseUrl}/auth/verify-email-otp',
    ),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
    }),
  );

  return _handleResponse(response);
}



  Future<void> _saveToken(
    Map<String, dynamic> result,
  ) async {
    final data = result['data'];

    final token = data is Map
        ? data['token']?.toString()
        : null;

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token was not received',
      );
    }

    await _storage.write(
      key: _tokenKey,
      value: token,
    );
  }



  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }


  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Please sign in to view your profile',
      );
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return _handleResponse(response);
  }


  Future<String?> getUserRole() async {
    final result = await getProfile();

    final data = result['data'];

    Map<String, dynamic>? userData;

    if (data is Map) {
      if (data['user'] is Map) {
        userData = Map<String, dynamic>.from(
          data['user'] as Map,
        );
      } else {
        userData = Map<String, dynamic>.from(data);
      }
    } else if (result['user'] is Map) {
      userData = Map<String, dynamic>.from(
        result['user'] as Map,
      );
    }

    final role = userData?['role']
        ?.toString()
        .trim()
        .toLowerCase();

    return role;
  }


  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Please sign in to update your profile',
      );
    }

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/auth/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
      }),
    );

    return _handleResponse(response);
  }


  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Please sign in to change your password',
      );
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/auth/change-password',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/auth/forgot-password',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
      }),
    );

    return _handleResponse(response);
  }


  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/auth/verify-otp',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'otp': otp.trim(),
      }),
    );

    return _handleResponse(response);
  }



  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/auth/reset-password',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'token': token.trim(),
        'newPassword': newPassword,
      }),
    );

    return _handleResponse(response);
  }

  

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }


  Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid response received from server',
      );
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return decoded;
    }

    throw Exception(
      decoded['message']?.toString() ??
          'Something went wrong',
    );
  }
}
