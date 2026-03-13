import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/navigation_helper.dart';

class WaiterOrdersPage extends StatefulWidget {
  const WaiterOrdersPage({super.key});

  @override
  State<WaiterOrdersPage> createState() => _WaiterOrdersPageState();
}

class _WaiterOrdersPageState extends State<WaiterOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

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
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      // Load recent orders (dine-in and recent delivery orders)
      final orders = await Supabase.instance.client
          .from('orders')
          .select('*, order_items(*)')
          .or('status.eq.confirmed,status.eq.preparing,status.eq.ready')
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      // Reload orders
      await _loadOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update order status'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          onPressed: () =>
              NavigationHelper.safeGo(context, '/waiter-dashboard'),
        ),
        title: Text(
          "Current Orders",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            : _orders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active orders',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return _buildOrderCard(order);
                },
              ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderItems = order['order_items'] as List<dynamic>? ?? [];
    final totalItems = orderItems.length;
    final orderNumber =
        order['order_number'] ?? order['id'].toString().substring(0, 8);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$orderNumber',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order['status'].toString().toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(order['status']),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Order Details
          Text(
            '$totalItems item${totalItems != 1 ? 's' : ''} • Rs. ${order['total_amount']}',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),

          const SizedBox(height: 12),

          // Status Update Buttons
          if (order['status'] != 'delivered')
            Row(
              children: [
                if (order['status'] == 'confirmed')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _updateOrderStatus(order['id'], 'preparing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Start Preparing',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ),
                if (order['status'] == 'preparing')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(order['id'], 'ready'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Mark Ready',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'on the way':
        return Colors.purple;
      case 'delivered':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
