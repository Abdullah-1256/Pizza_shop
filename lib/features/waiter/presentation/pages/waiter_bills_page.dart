import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/navigation_helper.dart';

class WaiterBillsPage extends StatefulWidget {
  const WaiterBillsPage({super.key});

  @override
  State<WaiterBillsPage> createState() => _WaiterBillsPageState();
}

class _WaiterBillsPageState extends State<WaiterBillsPage> {
  List<Map<String, dynamic>> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    try {
      // Load completed orders that can be billed
      final bills = await Supabase.instance.client
          .from('orders')
          .select('*, order_items(*)')
          .or('status.eq.ready,status.eq.delivered')
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _bills = bills;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bills: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _printBill(Map<String, dynamic> bill) async {
    // Mock bill printing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Printing bill for Order #${bill['order_number'] ?? bill['id'].toString().substring(0, 8)}',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _markAsPaid(Map<String, dynamic> bill) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': 'completed'})
          .eq('id', bill['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill marked as paid'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload bills
      await _loadBills();
    } catch (e) {
      print('Error marking bill as paid: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark bill as paid'),
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
          "Bill Management",
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
            : _bills.isEmpty
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
                      'No bills available',
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
                itemCount: _bills.length,
                itemBuilder: (context, index) {
                  final bill = _bills[index];
                  return _buildBillCard(bill);
                },
              ),
      ),
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    final orderItems = bill['order_items'] as List<dynamic>? ?? [];
    final totalItems = orderItems.length;
    final orderNumber =
        bill['order_number'] ?? bill['id'].toString().substring(0, 8);
    final isPaid = bill['status'] == 'completed';

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
          // Bill Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bill #$orderNumber',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPaid ? 'PAID' : 'PENDING',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Bill Details
          Text(
            '$totalItems item${totalItems != 1 ? 's' : ''} • Rs. ${bill['total_amount']}',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),

          Text(
            'Order Time: ${_formatDateTime(bill['created_at'])}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _printBill(bill),
                  icon: const Icon(Icons.print, size: 16),
                  label: Text(
                    'Print Bill',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!isPaid)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _markAsPaid(bill),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Mark Paid',
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

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
