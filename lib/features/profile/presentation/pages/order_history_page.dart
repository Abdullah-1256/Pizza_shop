import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/realtime_service.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  StreamSubscription? _orderUpdatesSubscription;
  String? _currentUserId;

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
    _loadOrderHistory();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _orderUpdatesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderHistory() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await Supabase.instance.client
          .from('orders')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading order history: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _currentUserId = user.id;

    _orderUpdatesSubscription = RealtimeService.ordersStream.listen((orders) {
      print('📢 Realtime Orders Updated: ${orders.length} total orders');

      // Filter orders for current user and update the list
      final userOrders = orders
          .where((order) => order['user_id'] == _currentUserId)
          .toList();

      setState(() {
        _orders = userOrders;
        _isLoading = false;
      });

      print('✅ Updated user order history: ${_orders.length} orders');
    });
  }

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
          "Order History",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
              onRefresh: _loadOrderHistory,
              color: Colors.orange,
              child: _orders.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Text(
                            'Your Orders',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Orders List
                          ..._orders.map((order) => _buildOrderCard(order)),

                          const SizedBox(height: 20),

                          // Summary
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
                                  'Order Summary',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Orders',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      '${_orders.length}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Spent',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      'Rs. ${_calculateTotalSpent().toStringAsFixed(0)}',
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
                          ),
                        ],
                      ),
                    ),
            ),
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
              Icons.receipt_long,
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
            'Your order history will appear here',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Start Ordering',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
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
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: const AssetImage('assets/images/pizza_icon.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          order['order_number'] ?? 'Order #${order['id']}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Row(
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
                const Spacer(),
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
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.black38,
          size: 16,
        ),
        onTap: () => _showOrderDetails(order),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final createdAt = DateTime.parse(order['created_at']);
    final formattedDate =
        '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Details',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Order ID: ${order['order_number'] ?? 'Order #${order['id']}'}',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                'Date: $formattedDate',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // Order Status Stepper
              Text(
                'Order Status',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildOrderStatusStepper(order['status'], order['id']),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Rs. ${(order['total_amount'] ?? order['total_price'] ?? 0).toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
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

  Widget _buildOrderStatusStepper(String currentStatus, String orderId) {
    final currentIndex = _orderStatuses.indexOf(currentStatus);

    return Column(
      children: [
        Stepper(
          currentStep: currentIndex,
          physics: const NeverScrollableScrollPhysics(),
          controlsBuilder: (context, details) {
            return const SizedBox.shrink(); // Hide default controls
          },
          steps: _orderStatuses.map((status) {
            final stepIndex = _orderStatuses.indexOf(status);
            final isCompleted = stepIndex < currentIndex;
            final isCurrent = stepIndex == currentIndex;

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
              subtitle: stepIndex == currentIndex
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

        // Cancel Order Button (only for cancellable orders)
        if (_canCancelOrder(currentStatus))
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
      ],
    );
  }

  String _formatStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'preparing':
        return 'Preparing Food';
      case 'ready':
        return 'Ready for Pickup/Delivery';
      case 'on the way':
        return 'On the Way';
      case 'delivered':
        return 'Delivered';
      default:
        return status.toUpperCase();
    }
  }

  double _calculateTotalSpent() {
    return _orders
        .where((order) => order['status'] == 'delivered')
        .fold(
          0.0,
          (sum, order) =>
              sum +
              ((order['total_amount'] ?? order['total_price'] ?? 0) as num)
                  .toDouble(),
        );
  }

  bool _canCancelOrder(String status) {
    // Allow cancellation only for pending and confirmed orders
    return status == 'pending' || status == 'confirmed';
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
      await Supabase.instance.client
          .from('orders')
          .update({'status': 'cancelled'})
          .eq('id', orderId);

      // Reload orders to reflect the update
      await _loadOrderHistory();

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
          const SnackBar(
            content: Text('Failed to cancel order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
