import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _orderUpdates = true;
  bool _promotionalOffers = false;
  bool _newArrivals = true;
  bool _deliveryAlerts = true;
  bool _accountActivity = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Notification Preferences',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose what notifications you want to receive',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 30),

            // Notification Settings
            _buildNotificationSetting(
              icon: Icons.shopping_bag,
              title: 'Order Updates',
              subtitle: 'Get notified about your order status',
              value: _orderUpdates,
              onChanged: (value) => setState(() => _orderUpdates = value),
            ),

            _buildNotificationSetting(
              icon: Icons.local_offer,
              title: 'Promotional Offers',
              subtitle: 'Receive special deals and discounts',
              value: _promotionalOffers,
              onChanged: (value) => setState(() => _promotionalOffers = value),
            ),

            _buildNotificationSetting(
              icon: Icons.new_releases,
              title: 'New Arrivals',
              subtitle: 'Be the first to know about new menu items',
              value: _newArrivals,
              onChanged: (value) => setState(() => _newArrivals = value),
            ),

            _buildNotificationSetting(
              icon: Icons.delivery_dining,
              title: 'Delivery Alerts',
              subtitle: 'Notifications about delivery status',
              value: _deliveryAlerts,
              onChanged: (value) => setState(() => _deliveryAlerts = value),
            ),

            _buildNotificationSetting(
              icon: Icons.account_circle,
              title: 'Account Activity',
              subtitle: 'Security and account-related notifications',
              value: _accountActivity,
              onChanged: (value) => setState(() => _accountActivity = value),
            ),

            const SizedBox(height: 30),

            // Notification Methods
            Text(
              'Notification Methods',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            _buildNotificationMethod(
              icon: Icons.notifications,
              title: 'Push Notifications',
              subtitle: 'Receive notifications on your device',
              isEnabled: true,
            ),

            _buildNotificationMethod(
              icon: Icons.email,
              title: 'Email Notifications',
              subtitle: 'Get updates via email',
              isEnabled: true,
            ),

            _buildNotificationMethod(
              icon: Icons.sms,
              title: 'SMS Notifications',
              subtitle: 'Receive text messages for important updates',
              isEnabled: false,
            ),

            const SizedBox(height: 30),

            // Save Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveNotificationSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Save Preferences',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can change these settings anytime. Important security notifications cannot be disabled.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.orange, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.orange,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildNotificationMethod({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isEnabled
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isEnabled ? Colors.green : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isEnabled
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isEnabled ? 'Enabled' : 'Disabled',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isEnabled ? Colors.green : Colors.grey,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _saveNotificationSettings() {
    // TODO: Implement save logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification preferences saved successfully!'),
      ),
    );
    context.go('/profile');
  }
}
