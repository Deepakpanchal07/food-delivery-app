
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'features/auth/screens/auth_gate.dart';
import 'features/auth/screens/reset_password_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;
  String? _lastHandledToken;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        _handleResetLink(initialUri);
      }
    } catch (e) {
      debugPrint('Initial link error: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleResetLink,
      onError: (Object error) {
        debugPrint('Deep link error: $error');
      },
    );
  }

  void _handleResetLink(Uri uri) {
    if (uri.scheme != 'fooddelivery' ||
        uri.host != 'reset-password') {
      return;
    }

    final token = uri.queryParameters['token'];

    if (token == null || token.isEmpty) {
      debugPrint('Reset token missing from link');
      return;
    }

    if (_lastHandledToken == token) return;
    _lastHandledToken = token;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = appNavigatorKey.currentState;

      if (navigator == null) {
        _lastHandledToken = null;
        return;
      }

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(token: token),
        ),
      );
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Food Delivery',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFAF6),
      ),
      home: const AuthGate(),
    );
  }
}
