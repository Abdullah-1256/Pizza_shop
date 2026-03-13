import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../widgets/admin_sidebar.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';
  String _searchQuery = '';
  StreamSubscription? _orderUpdatesSubscription;

  final List<String> _statusOptions = [
    'All',
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'on the way',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminPermissions();
    _loadOrders();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _orderUpdatesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAdminPermissions() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ No admin user logged in');
        return;
      }

      print('👤 Admin User ID: ${user.id}');
      print('📧 Admin Email: ${user.email}');

      final profile = await SupabaseService.getUserProfile(user.id);
      print('👤 Admin Profile: $profile');
      print('🔑 Admin Role: ${profile?['role']}');

      if (profile?['role'] != 'admin') {
        print(
          '⚠️  WARNING: User does not have admin role! Current role: ${profile?['role']}',
        );
        print(
          '💡 Run this SQL to fix: UPDATE profiles SET role = \'admin\' WHERE id = \'${user.id}\';',
        );
      } else {
        print('✅ Admin permissions verified');
      }
    } catch (e) {
      print('❌ Error checking admin permissions: $e');
    }
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);

      print('🔄 Loading admin orders...');

      // Load all orders (admin can see all)
      final orders = await SupabaseService.getOrders();

      // For each order, get the customer email
      final ordersWithCustomerData = <Map<String, dynamic>>[];

      for (final order in orders) {
        final orderMap = Map<String, dynamic>.from(order);

        // Get customer email from profiles table
        try {
          final profile = await SupabaseService.getUserProfile(
            order['user_id'],
          );
          orderMap['customer_email'] = profile?['email'] ?? 'Unknown Customer';
        } catch (e) {
          orderMap['customer_email'] = 'Unknown Customer';
          print('⚠️ Could not load customer data for order ${order['id']}: $e');
        }

        ordersWithCustomerData.add(orderMap);
      }

      setState(() {
        _orders = ordersWithCustomerData;
        _applyFilters();
        _isLoading = false;
      });

      print(
        '✅ Loaded ${ordersWithCustomerData.length} orders successfully for admin',
      );
    } catch (e) {
      print('❌ Error loading admin orders: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _setupRealtimeSubscription() {
    _orderUpdatesSubscription = RealtimeService.ordersStream.listen((orders) {
      print(
        '📢 Realtime Orders Updated: ${orders.length} total orders for admin',
      );

      // Update the orders list with the latest data
      setState(() {
        _orders = orders;
        _applyFilters();
        _isLoading = false;
      });

      print('✅ Admin orders list updated with realtime data');
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _orders.where((order) {
        // Status filter
        final statusMatch =
            _selectedStatus == 'All' || order['status'] == _selectedStatus;

        // Search filter
        final searchMatch =
            _searchQuery.isEmpty ||
            (order['customer_email']?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            (order['id'].toString().contains(_searchQuery));

        return statusMatch && searchMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              child: const AdminSidebar(currentRoute: '/admin-orders'),
            )
          : null,
      appBar: isMobile || isTablet
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              title: Text(
                "📦 Orders Management",
                style: GoogleFonts.poppins(
                  fontSize: 18,
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
                  onPressed: _loadOrders,
                  tooltip: 'Refresh Orders',
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
        const AdminSidebar(currentRoute: '/admin-orders'),

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
                      "📦 Orders Management",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      onPressed: _loadOrders,
                      tooltip: 'Refresh Orders',
                    ),
                  ],
                ),
              ),

              // Filters and Search
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Row(
                  children: [
                    // Status Filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_formatStatusText(status)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedStatus = value!);
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Search
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Search by Order ID or Customer Email',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Bulk Actions
                    ElevatedButton.icon(
                      onPressed: _markAllPendingAsOnTheWay,
                      icon: const Icon(Icons.fast_forward),
                      label: const Text('Mark All Pending → On The Way'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Orders List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
                    : _filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        color: Colors.orange,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(_filteredOrders[index]);
                          },
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
    return Column(
      children: [
        // Filters and Search - responsive layout
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Status Filter
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Filter by Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_formatStatusText(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedStatus = value!);
                  _applyFilters();
                },
              ),
              const SizedBox(height: 12),

              // Search
              TextField(
                decoration: InputDecoration(
                  labelText: 'Search by Order ID or Customer Email',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _applyFilters();
                },
              ),
              const SizedBox(height: 12),

              // Bulk Actions - responsive button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _markAllPendingAsOnTheWay,
                  icon: const Icon(Icons.fast_forward),
                  label: const Text('Mark All Pending → On The Way'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Orders List
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                )
              : _filteredOrders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: Colors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_filteredOrders[index]);
                    },
                  ),
                ),
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
              Icons.shopping_cart_outlined,
              color: Colors.orange,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or check back later',
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

    final createdAt = DateTime.parse(order['created_at']);
    final formattedDate =
        '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';

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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shopping_cart, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
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
                    order['customer_email'] ?? 'Unknown Customer',
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
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatStatusText(order['status']),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${(order['total_amount'] ?? order['total_price'] ?? 0).toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            formattedDate,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Details
                _buildOrderDetails(order),

                const SizedBox(height: 16),

                // Status Update Section
                Text(
                  'Update Order Status',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusUpdateStepper(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Details',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Customer',
                  order['customer_email'] ?? 'Unknown',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Total Amount',
                  'Rs. ${(order['total_amount'] ?? order['total_price'] ?? 0).toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Order Date',
                  _formatDate(order['created_at']),
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Status',
                  _formatStatusText(order['status']),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusUpdateStepper(Map<String, dynamic> order) {
    final currentIndex = _statusOptions.indexOf(order['status']);
    // Adjust index for stepper since it skips 'All' option
    final stepperCurrentIndex = currentIndex > 0 ? currentIndex - 1 : 0;
    final orderId = order['id'].toString();
    final currentStatus = order['status'];

    // Check if order can still be modified
    final canModifyOrder = _canModifyOrder(currentStatus);
    final canCancelOrder = _canCancelOrder(currentStatus);

    return Column(
      children: [
        Stepper(
          currentStep: stepperCurrentIndex,
          physics: const NeverScrollableScrollPhysics(),
          controlsBuilder: (context, details) {
            return const SizedBox.shrink(); // Hide default controls
          },
          steps: _statusOptions.skip(1).map((status) {
            // Skip 'All' option
            final stepIndex = _statusOptions.indexOf(status);
            final adjustedStepIndex = stepIndex - 1; // Adjust for skipped 'All'
            final isCompleted = adjustedStepIndex < stepperCurrentIndex;
            final isCurrent = adjustedStepIndex == stepperCurrentIndex;

            return Step(
              title: Text(
                _formatStatusText(status),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  color: isCompleted || isCurrent
                      ? Colors.black87
                      : Colors.black54,
                ),
              ),
              subtitle: adjustedStepIndex == stepperCurrentIndex
                  ? Text(
                      'Current Status',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    )
                  : null,
              content: const SizedBox.shrink(),
              isActive: isCompleted || isCurrent,
              state: isCompleted
                  ? StepState.complete
                  : isCurrent
                  ? StepState.editing
                  : StepState.indexed,
            );
          }).toList(),
        ),

        // Status Update Controls - Only show if order can still be modified
        if (canModifyOrder)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                // Show next step button
                if (currentIndex < _statusOptions.length - 1)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final nextStatus = _statusOptions[currentIndex + 1];
                        await _updateOrderStatusDirect(orderId, nextStatus);
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        'Mark as ${_formatStatusText(_statusOptions[currentIndex + 1])}',
                        style: GoogleFonts.poppins(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Show all status options for direct selection
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _statusOptions.skip(1).map((status) {
                    final statusIndex = _statusOptions.indexOf(status);
                    final isCurrent = statusIndex == currentIndex;
                    final isCompleted = statusIndex < currentIndex;

                    // Special handling for cancelled status - only allow if order can be cancelled
                    final canChangeToStatus = status == 'cancelled'
                        ? _canCancelOrder(currentStatus)
                        : true;

                    return ElevatedButton(
                      onPressed: (isCurrent || !canChangeToStatus)
                          ? null
                          : () async =>
                                await _updateOrderStatusDirect(orderId, status),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrent
                            ? Colors.grey
                            : !canChangeToStatus
                            ? Colors.grey.withOpacity(0.5)
                            : isCompleted
                            ? Colors.green
                            : Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        _formatStatusText(status),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        // Cancel Order Button - Only show if order can be cancelled
        if (canCancelOrder)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCancelOrderConfirmation(orderId),
                    icon: const Icon(Icons.cancel),
                    label: Text('Cancel Order', style: GoogleFonts.poppins()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Show completion message for delivered orders
        if (currentStatus == 'delivered')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order completed successfully!',
                      style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Show cancellation message for cancelled orders
        if (currentStatus == 'cancelled')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order has been cancelled',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
        return 'On The Way';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  bool _canModifyOrder(String status) {
    // Allow modification only for orders that are not delivered or cancelled
    return status != 'delivered' && status != 'cancelled';
  }

  bool _canCancelOrder(String status) {
    // Allow cancellation only for pending and confirmed orders
    // Never allow cancellation of delivered or already cancelled orders
    return (status == 'pending' || status == 'confirmed') &&
        status != 'delivered' &&
        status != 'cancelled';
  }

  void _showCancelOrderConfirmation(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Order',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep Order',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              await _cancelOrder(orderId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Cancel Order', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      // Get current order status to validate the cancellation
      final currentOrder = _orders.firstWhere(
        (order) => order['id'].toString() == orderId,
        orElse: () => <String, dynamic>{},
      );

      if (currentOrder.isEmpty) {
        throw Exception('Order not found');
      }

      final currentStatus = currentOrder['status'] as String;

      // Validate that order can be cancelled
      if (!_canCancelOrder(currentStatus)) {
        throw Exception('Cannot cancel a ${currentStatus} order');
      }

      await SupabaseService.updateOrderStatus(orderId, 'cancelled');

      // Reload orders to reflect the update
      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error cancelling order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateOrderStatusDirect(
    String orderId,
    String newStatus,
  ) async {
    try {
      print('🔄 Updating order $orderId to status: $newStatus');

      // Get current order status to validate the change
      final currentOrder = _orders.firstWhere(
        (order) => order['id'].toString() == orderId,
        orElse: () => <String, dynamic>{},
      );

      if (currentOrder.isEmpty) {
        throw Exception('Order not found');
      }

      final currentStatus = currentOrder['status'] as String;

      // Validate status change
      if (newStatus == 'cancelled' && !_canCancelOrder(currentStatus)) {
        throw Exception('Cannot cancel a ${currentStatus} order');
      }

      if (currentStatus == 'delivered' && newStatus != 'delivered') {
        throw Exception('Cannot change status of a delivered order');
      }

      if (currentStatus == 'cancelled' && newStatus != 'cancelled') {
        throw Exception('Cannot change status of a cancelled order');
      }

      await SupabaseService.updateOrderStatus(orderId, newStatus);

      // If order status changed to 'confirmed', assign a delivery person
      if (newStatus == 'confirmed') {
        await SupabaseService.assignDeliveryPerson(orderId);
      }

      // Reload orders to reflect the update
      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order status updated to ${_formatStatusText(newStatus)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating order status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      await SupabaseService.updateOrderStatus(orderId.toString(), newStatus);

      // If order status changed to 'confirmed', assign a delivery person
      if (newStatus == 'confirmed') {
        await SupabaseService.assignDeliveryPerson(orderId.toString());
      }

      // Reload orders to reflect the update
      await _loadOrders();

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

  void _showStatusUpdateConfirmation(
    int orderId,
    String currentStatus,
    String newStatus,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Order Status',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Change Order #${orderId} status from "${_formatStatusText(currentStatus)}" to "${_formatStatusText(newStatus)}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              await _updateOrderStatus(orderId, newStatus);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Update', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllPendingAsOnTheWay() async {
    try {
      final pendingOrders = _orders
          .where((order) => order['status'] == 'pending')
          .toList();

      if (pendingOrders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pending orders to update'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Update all pending orders to "on the way"
      for (final order in pendingOrders) {
        await SupabaseService.updateOrderStatus(
          order['id'].toString(),
          'on the way',
        );
      }

      // Reload orders
      await _loadOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated ${pendingOrders.length} orders to "On The Way"',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error bulk updating orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update orders'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
