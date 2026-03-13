import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/shared_preferences_helper.dart';

class AdminSidebar extends StatefulWidget {
  final String currentRoute;

  const AdminSidebar({super.key, required this.currentRoute});

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Dashboard',
      'icon': Icons.dashboard,
      'route': '/admin-dashboard',
    },
    {'title': 'Orders', 'icon': Icons.shopping_cart, 'route': '/admin-orders'},
    {'title': 'Analytics', 'icon': Icons.payments, 'route': '/admin-analytics'},
    {
      'title': 'Complaints',
      'icon': Icons.feedback,
      'route': '/admin-complaints',
    },
    {'title': 'Menu', 'icon': Icons.restaurant_menu, 'route': '/admin-menu'},
    {'title': 'Customers', 'icon': Icons.people, 'route': '/admin-customers'},
    {'title': 'Reports', 'icon': Icons.analytics, 'route': '/admin-reports'},
    {
      'title': 'Delivery',
      'icon': Icons.delivery_dining,
      'route': '/admin-delivery',
    },
    {'title': 'Settings', 'icon': Icons.settings, 'route': '/admin-settings'},
  ];

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    // For mobile/tablet, use full width in drawer
    // For desktop, use fixed width sidebar
    final sidebarWidth = isMobile || isTablet ? double.infinity : 280.0;

    return Container(
      width: sidebarWidth,
      color: Colors.white,
      child: Column(
        children: [
          // Header - responsive padding
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.orange.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Panel',
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Pizza Management',
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button for mobile drawer
                if (isMobile || isTablet)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _menuItems.map((item) {
                final isSelected = widget.currentRoute == item['route'];
                return _buildMenuItem(
                  title: item['title'],
                  icon: item['icon'],
                  route: item['route'],
                  isSelected: isSelected,
                  isMobile: isMobile,
                );
              }).toList(),
            ),
          ),

          // Footer - responsive padding
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.logout, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: _logout,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required String route,
    required bool isSelected,
    required bool isMobile,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.orange : Colors.black54,
          size: isMobile ? 18 : 20,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 13 : 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.orange : Colors.black87,
          ),
        ),
        onTap: () {
          // Close drawer on mobile/tablet after navigation
          if (isMobile) {
            Navigator.of(context).pop();
          }
          context.go(route);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isSelected,
        selectedTileColor: Colors.orange.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      await SharedPreferencesHelper.clearAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );

        context.go('/login');
      }
    } catch (e) {
      print('❌ Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error logging out'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
