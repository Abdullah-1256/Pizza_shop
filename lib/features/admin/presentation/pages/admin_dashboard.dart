import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/shared_preferences_helper.dart';
import '../../../../core/network/supabase_client.dart';
import '../widgets/admin_sidebar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  bool? _isAdmin;

  final List<String> _orderStatuses = [
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'on the way',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ Admin check: No authenticated user');
        setState(() => _isLoading = false);
        return;
      }

      print(
        '🔍 Admin dashboard: Checking admin status for user: ${user.email}',
      );

      // Check if user is admin
      bool isAdmin = false;
      try {
        final adminCheck = await Supabase.instance.client.rpc('is_admin');
        isAdmin = adminCheck as bool? ?? false;
        print('🔐 Admin dashboard: RPC response: $adminCheck');
      } catch (rpcError) {
        print('⚠️ RPC function not found, checking profiles table');
        // Fallback: check profiles table for admin role
        try {
          final profile = await SupabaseService.getUserProfile(user.id);
          isAdmin = profile?['role'] == 'admin';
          print(
            '👤 Profile role check: ${profile?['role']} == "admin" = $isAdmin',
          );
        } catch (profileError) {
          print('⚠️ Profile check failed: $profileError');
          // Last resort: check if email is admin email
          isAdmin = user.email == 'abdullahmubashar280@gmail.com';
          print('📧 Email fallback result: $isAdmin');
        }
      }

      print('🔐 Admin dashboard: Final result: $isAdmin');

      setState(() {
        _isAdmin = isAdmin;
      });

      if (_isAdmin == true) {
        print('✅ Admin access granted - loading data');
        await _loadAllOrders();
        await _loadAllComplaints();
      } else {
        print('❌ Admin access denied - redirecting to order history');
        setState(() => _isLoading = false);
        // Redirect to regular order history if not admin
        context.go('/order-history');
      }
    } catch (e) {
      print('❌ Admin check error: $e');
      print('❌ Admin check error details: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllOrders() async {
    try {
      // Load orders from the vw_admin_orders view which combines orders with user data
      final orders = await SupabaseService.getAdminOrdersView();

      setState(() {
        _orders = orders;
        _isLoading = false;
      });

      print('✅ Loaded ${_orders.length} orders from vw_admin_orders view');
    } catch (e) {
      print('❌ Error loading orders from view: $e');
      setState(() => _isLoading = false);

      // Fallback to direct orders table if view doesn't exist
      try {
        print('🔄 Trying fallback to orders table...');
        final orders = await SupabaseService.getOrders();

        setState(() {
          _orders = orders;
          _isLoading = false;
        });
        print('✅ Loaded ${_orders.length} orders from fallback table');
      } catch (fallbackError) {
        print('❌ Fallback also failed: $fallbackError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load orders: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadAllComplaints() async {
    try {
      final complaints = await SupabaseService.getComplaints();

      setState(() {
        _complaints = complaints;
      });

      print('✅ Loaded ${_complaints.length} complaints successfully');
    } catch (e) {
      print('❌ Error loading complaints: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking admin status
    if (_isAdmin == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF5EE),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    if (!_isAdmin!) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF5EE),
        body: const Center(
          child: Text(
            'Access Denied: Admin Only',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EE),
      // Use drawer for mobile/tablet, sidebar for desktop
      drawer: isMobile || isTablet
          ? Drawer(
              backgroundColor: Colors.white,
              child: AdminSidebar(currentRoute: '/admin-dashboard'),
            )
          : null,
      appBar: isMobile || isTablet
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              title: Text(
                "🍕 Admin Dashboard",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.orange),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.orange),
                  onPressed: () async {
                    await _loadAllOrders();
                    await _loadAllComplaints();
                  },
                  tooltip: 'Refresh Data',
                ),
              ],
            )
          : null,
      body: isMobile || isTablet
          ? _buildMobileTabletContent()
          : _buildDesktopContent(),
    );
  }

  Widget _buildDesktopContent() {
    return Row(
      children: [
        // Sidebar for desktop
        AdminSidebar(currentRoute: '/admin-dashboard'),

        // Main Content
        Expanded(
          child: Column(
            children: [
              // Top Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      "🍕 Dashboard Overview",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      onPressed: () async {
                        await _loadAllOrders();
                        await _loadAllComplaints();
                      },
                      tooltip: 'Refresh Data',
                    ),
                  ],
                ),
              ),

              // Main Content Area
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadAllOrders();
                          await _loadAllComplaints();
                        },
                        color: Colors.orange,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stats Header
                              _buildStatsHeader(),

                              const SizedBox(height: 32),

                              // Recent Orders Section
                              _buildRecentOrdersSection(),

                              const SizedBox(height: 32),

                              // Recent Complaints Section
                              _buildRecentComplaintsSection(),

                              const SizedBox(height: 32),

                              // Quick Actions
                              _buildQuickActions(),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletContent() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : RefreshIndicator(
            onRefresh: () async {
              await _loadAllOrders();
              await _loadAllComplaints();
            },
            color: Colors.orange,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Header
                  _buildStatsHeader(),

                  const SizedBox(height: 24),

                  // Recent Orders Section
                  _buildRecentOrdersSection(),

                  const SizedBox(height: 24),

                  // Recent Complaints Section
                  _buildRecentComplaintsSection(),

                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(),
                ],
              ),
            ),
          );
  }

  Widget _buildStatsHeader() {
    final totalOrders = _orders.length;
    final pendingOrders = _orders.where((o) => o['status'] == 'pending').length;
    final deliveredOrders = _orders
        .where((o) => o['status'] == 'delivered')
        .length;

    final totalComplaints = _complaints.length;
    final pendingComplaints = _complaints
        .where((c) => c['status'] == 'pending')
        .length;
    final resolvedComplaints = _complaints
        .where((c) => c['status'] == 'resolved')
        .length;

    return Column(
      children: [
        // Order Statistics
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            children: [
              Text(
                'Order Statistics',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total Orders',
                    totalOrders.toString(),
                    Colors.blue,
                  ),
                  _buildStatItem(
                    'Pending',
                    pendingOrders.toString(),
                    Colors.orange,
                  ),
                  _buildStatItem(
                    'Delivered',
                    deliveredOrders.toString(),
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Complaints Statistics
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            children: [
              Text(
                'Complaints Statistics',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total Complaints',
                    totalComplaints.toString(),
                    Colors.purple,
                  ),
                  _buildStatItem(
                    'Pending',
                    pendingComplaints.toString(),
                    Colors.red,
                  ),
                  _buildStatItem(
                    'Resolved',
                    resolvedComplaints.toString(),
                    Colors.teal,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.orange,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All customer orders will appear here',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    Color statusColor;
    switch (order['status']) {
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    // Format date
    final createdAt = DateTime.parse(order['created_at']);
    final formattedDate =
        '${createdAt.day}/${createdAt.month}/${createdAt.year}';

    // Get customer email
    final customerEmail = order['customer_email'] ?? 'Unknown';

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
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order['id']}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    customerEmail,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order['status'].toString().toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'Rs. ${(order['total_amount'] ?? order['total_price'] ?? 0).toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Text(
          formattedDate,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Update Section
                Text(
                  'Update Status',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusUpdateButtons(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateButtons(Map<String, dynamic> order) {
    final currentIndex = _orderStatuses.indexOf(order['status']);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _orderStatuses.map((status) {
        final statusIndex = _orderStatuses.indexOf(status);
        final isCurrent = statusIndex == currentIndex;
        final isCompleted = statusIndex < currentIndex;

        return ElevatedButton(
          onPressed: isCurrent
              ? null
              : () => _updateOrderStatus(order['id'], status),
          style: ElevatedButton.styleFrom(
            backgroundColor: isCurrent
                ? Colors.grey
                : isCompleted
                ? Colors.green
                : Colors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(
            _formatStatusText(status),
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  String _formatStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'on the way':
        return 'On the Way';
      case 'delivered':
        return 'Delivered';
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      await SupabaseService.updateOrderStatus(orderId.toString(), newStatus);

      // Reload orders to reflect the update
      await _loadAllOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order #${orderId} status updated to ${_formatStatusText(newStatus)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating order status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update order status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRecentOrdersSection() {
    final recentOrders = _orders.take(5).toList();

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Recent Orders',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/admin-orders'),
                  child: Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (recentOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No orders yet',
                  style: GoogleFonts.poppins(color: Colors.black54),
                ),
              ),
            )
          else
            ...recentOrders.map((order) => _buildRecentOrderItem(order)),
        ],
      ),
    );
  }

  Widget _buildRecentComplaintsSection() {
    final recentComplaints = _complaints.take(5).toList();

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Recent Complaints',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/admin-complaints'),
                  child: Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (recentComplaints.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No complaints yet',
                  style: GoogleFonts.poppins(color: Colors.black54),
                ),
              ),
            )
          else
            ...recentComplaints.map(
              (complaint) => _buildRecentComplaintItem(complaint),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentOrderItem(Map<String, dynamic> order) {
    Color statusColor;
    switch (order['status']) {
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    final createdAt = DateTime.parse(order['created_at']);
    final timeAgo = _getTimeAgo(createdAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.shopping_cart, color: statusColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  order['customer_email'] ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${(order['total_amount'] ?? order['total_price'] ?? 0).toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                timeAgo,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentComplaintItem(Map<String, dynamic> complaint) {
    Color statusColor;
    switch (complaint['status']) {
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'closed':
        statusColor = Colors.grey;
        break;
      case 'in_review':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    final createdAt = DateTime.parse(complaint['created_at']);
    final timeAgo = _getTimeAgo(createdAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.feedback, color: statusColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint['subject'] ?? 'No Subject',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  complaint['user_email'] ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatComplaintStatusText(complaint['status']),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                timeAgo,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatComplaintStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_review':
        return 'In Review';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildQuickActions() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildQuickActionButton(
                  icon: Icons.add,
                  label: 'Add Pizza',
                  onTap: () => context.go('/admin-menu'),
                ),
                const SizedBox(width: 12),
                _buildQuickActionButton(
                  icon: Icons.feedback,
                  label: 'View Complaints',
                  onTap: () => context.go('/admin-complaints'),
                ),
                const SizedBox(width: 12),
                _buildQuickActionButton(
                  icon: Icons.people,
                  label: 'View Customers',
                  onTap: () => context.go('/admin-customers'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQuickActionButton(
                  icon: Icons.analytics,
                  label: 'View Reports',
                  onTap: () => context.go('/admin-reports'),
                ),
                const SizedBox(width: 12),
                _buildQuickActionButton(
                  icon: Icons.delivery_dining,
                  label: 'Manage Delivery',
                  onTap: () => context.go('/admin-delivery'),
                ),
                const SizedBox(width: 12),
                _buildQuickActionButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () => context.go('/admin-settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200, width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.orange, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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

        // Navigate to login page
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
