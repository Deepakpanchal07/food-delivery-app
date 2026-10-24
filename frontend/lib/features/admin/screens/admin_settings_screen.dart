
import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState
    extends State<AdminSettingsScreen> {
  static const Color primary = Color(0xFFFF6B35);
  static const Color background = Color(0xFFFFF9F5);

  bool _orderNotifications = true;
  bool _statusNotifications = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Account & Security'),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: _iconBox(
                    Icons.admin_panel_settings_rounded,
                  ),
                  title: const Text(
                    'Administrator',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Foodie Admin Panel',
                  ),
                  trailing: const Icon(
                    Icons.verified_user_outlined,
                    color: Colors.green,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: _iconBox(Icons.lock_outline_rounded),
                  title: const Text('Account security'),
                  subtitle: const Text(
                    'Keep your administrator account secure',
                  ),
                  trailing: const Icon(
                    Icons.info_outline_rounded,
                  ),
                  onTap: () {
                    _showInfo(
                      'Account Security',
                      'Use a strong password and never share '
                          'your administrator login details.',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          _sectionTitle('Notification Preferences'),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: _iconBox(
                    Icons.shopping_bag_outlined,
                  ),
                  title: const Text('Order notifications'),
                  subtitle: const Text(
                    'Preferences for new order alerts',
                  ),
                  value: _orderNotifications,
                  activeTrackColor: primary,
                  onChanged: (value) {
                    setState(() {
                      _orderNotifications = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: _iconBox(
                    Icons.local_shipping_outlined,
                  ),
                  title: const Text('Order status updates'),
                  subtitle: const Text(
                    'Preferences for delivery status alerts',
                  ),
                  value: _statusNotifications,
                  activeTrackColor: primary,
                  onChanged: (value) {
                    setState(() {
                      _statusNotifications = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: _iconBox(
                    Icons.volume_up_outlined,
                  ),
                  title: const Text('Sound preference'),
                  subtitle: const Text(
                    'Enable or disable the sound preference',
                  ),
                  value: _soundEnabled,
                  activeTrackColor: primary,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          _sectionTitle('Application'),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: _iconBox(Icons.restaurant_rounded),
                  title: const Text(
                    'Foodie',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Food Delivery Management App',
                  ),
                  trailing: const Icon(
                    Icons.info_outline_rounded,
                  ),
                  onTap: () {
                    _showInfo(
                      'About Foodie',
                      'Foodie is a food delivery application '
                          'with restaurant, menu, order and '
                          'administration features.',
                    );
                  },
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(
                    Icons.code_rounded,
                    color: primary,
                  ),
                  title: Text('Application version'),
                  subtitle: Text(
                    'Version information is not configured yet.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Center(
            child: Text(
              'Foodie Admin Settings',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Color(0xFF292321),
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: primary,
      ),
    );
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Close',
              style: TextStyle(color: primary),
            ),
          ),
        ],
      ),
    );
  }
}
