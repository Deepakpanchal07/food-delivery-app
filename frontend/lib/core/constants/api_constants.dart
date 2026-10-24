import 'package:flutter/foundation.dart';

class ApiConstants{
  static String get baseUrl {
    if(kIsWeb) {
      return 'http://localhost:5000/api';
    }
    return 'http://10.0.2.2:5000/api';
  }
  static const String restaurants = '/restaurants';
  static const String health = '/health';
}