
import 'package:flutter/material.dart';
import 'package:frontend/features/admin/screens/admin_analytics_screen.dart';
import 'package:frontend/features/admin/screens/admin_customers_screen.dart';
import 'package:frontend/features/admin/screens/admin_menu_screen.dart';
import 'package:frontend/features/admin/screens/admin_restaurants_screen.dart';
import 'package:frontend/features/admin/screens/admin_settings_screen.dart';
import 'package:frontend/features/auth/screens/sign_in_screen.dart';
import 'package:frontend/features/auth/services/auth_service.dart';
import 'admin_dashboard_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  static const Color primary = Color(0xFFFF6B35);
  static const Color background = Color(0xFFFFF9F5);

  Future<void> _logout(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Logout'),
      content: const Text(
        'Are you sure you want to logout?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext, false);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext, true);
          },
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  if (shouldLogout != true) return;

  await AuthService().logout();

  if (!context.mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const SignInScreen(),
    ),
    (route) => false,
  );
}

  void _openSection(BuildContext context, String section) {
  switch (section) {
    case 'Orders':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboardScreen(),
        ),
      );
      break;
            case 'Menu':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminMenuScreen(),
          ),
        );
        break;

    case 'Restaurants':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminRestaurantsScreen(),
        ),
      );
      break;
      case 'Users':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminCustomersScreen(),
        ),
      );
      break;
      case 'Analytics':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminAnalyticsScreen(),
          ),
        );
        break;
        case 'Settings':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminSettingsScreen(),
            ),
          );
          break;

    default:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$section management will be connected next.',
          ),
        ),
      );
  }
}

  
Widget _sectionCard({
  required BuildContext context,
  required String title,
  required String description,
  required IconData icon,
}) {
  return Card(
    color: Colors.white,
    elevation: 2,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    child: InkWell(
      onTap: () => _openSection(context, title),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.arrow_forward_rounded,
                color: primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    final sections = [
      (
        title: 'Orders',
        description: 'View orders and update delivery status.',
        icon: Icons.receipt_long_rounded,
      ),
      (
        title: 'Restaurants',
        description: 'Manage restaurant listings and details.',
        icon: Icons.storefront_rounded,
      ),
      (
        title: 'Menu',
        description: 'Manage food items, prices and availability.',
        icon: Icons.restaurant_menu_rounded,
      ),
      (
        title: 'Users',
        description: 'View registered customer accounts.',
        icon: Icons.people_alt_rounded,
      ),
      (
        title: 'Analytics',
        description: 'Review orders and business performance.',
        icon: Icons.bar_chart_rounded,
      ),
      (
        title: 'Settings',
        description: 'Manage administrative settings.',
        icon: Icons.settings_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: background,
     appBar: AppBar(
          title: const Text(
            'Admin Panel',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _logout(context),
            ),
          ],
        ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6B35),
                  Color(0xFFFF8A50),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 40,
                ),
                SizedBox(height: 14),
                Text(
                  'Welcome, Admin!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Manage your Foodie application from one place.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Management',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF292321),
            ),
          ),
          const SizedBox(height: 14),
          
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sections.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isSmallScreen ? 1 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: isSmallScreen ? 155 : 150,
                  ),
                  itemBuilder: (context, index) {
                    final section = sections[index];

                    return _sectionCard(
                      context: context,
                      title: section.title,
                      description: section.description,
                      icon: section.icon,
                    );
                  },
                );
              },
            ),

        ],
      ),
    );
  }
}
