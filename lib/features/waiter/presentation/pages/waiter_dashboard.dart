import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/navigation_helper.dart';

class WaiterDashboard extends StatelessWidget {
  const WaiterDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5EE),
        elevation: 0,
        title: Text(
          "Waiter Panel",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.black87),
          onPressed: () => NavigationHelper.safeGo(context, '/login'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: Colors.orange,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome to Waiter Panel",
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Take orders from customers efficiently",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Quick Actions
              Text(
                "Quick Actions",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.add_shopping_cart,
                      title: "New Order",
                      subtitle: "Take customer order",
                      onTap: () => NavigationHelper.safeGo(
                        context,
                        '/waiter-take-order',
                      ),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.list_alt,
                      title: "View Orders",
                      subtitle: "Current orders",
                      onTap: () =>
                          NavigationHelper.safeGo(context, '/waiter-orders'),
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.table_restaurant,
                      title: "Tables",
                      subtitle: "Manage tables",
                      onTap: () =>
                          NavigationHelper.safeGo(context, '/waiter-tables'),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.receipt_long,
                      title: "Bills",
                      subtitle: "Print bills",
                      onTap: () =>
                          NavigationHelper.safeGo(context, '/waiter-bills'),
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
