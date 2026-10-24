
import 'package:flutter/material.dart';

import 'package:frontend/features/auth/screens/sign_in_screen.dart';
import 'package:frontend/features/auth/services/auth_service.dart';
import 'package:frontend/features/home/screens/home_screen.dart';

// Apne admin dashboard ki file ka import add karna.
import 'package:frontend/features/admin/screens/admin_dashboard_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();

  late Future<String?> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = _loadRole();
  }

  Future<String?> _loadRole() async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    final result = await _authService.getProfile();
    final data = result['data'] as Map<String, dynamic>?;
    final user = data?['user'] as Map<String, dynamic>?;

    return user?['role']?.toString() ?? 'customer';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load your account.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _roleFuture = _loadRole();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _authService.logout();

                      if (!context.mounted) return;

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const SignInScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          );
        }

        final role = snapshot.data;

        if (role == null) {
          return const SignInScreen();
        }

        if (role == 'admin') {
          return const AdminDashboardScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
