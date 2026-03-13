import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  String _selectedPaymentMethod = 'card';

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'card',
      'type': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'details': '**** **** **** 1234',
      'isDefault': true,
    },
    {
      'id': 'paypal',
      'type': 'PayPal',
      'icon': Icons.account_balance_wallet,
      'details': 'john.doe@email.com',
      'isDefault': false,
    },
    {
      'id': 'cash',
      'type': 'Cash on Delivery',
      'icon': Icons.money,
      'details': 'Pay when you receive',
      'isDefault': false,
    },
  ];

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
          "Payment Methods",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewPaymentMethod,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Select Payment Method',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Payment Methods List
            ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)),

            const SizedBox(height: 30),

            // Add New Payment Method Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              child: OutlinedButton.icon(
                onPressed: _addNewPaymentMethod,
                icon: const Icon(Icons.add, color: Colors.orange),
                label: Text(
                  'Add New Payment Method',
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            // Security Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment information is encrypted and secure. We never store your full card details.',
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

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.orange : Colors.transparent,
          width: 2,
        ),
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
          child: Icon(method['icon'], color: Colors.orange, size: 24),
        ),
        title: Text(
          method['type'],
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              method['details'],
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            ),
            if (method['isDefault'])
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Default',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: Radio<String>(
          value: method['id'],
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
          activeColor: Colors.orange,
        ),
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method['id'];
          });
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _addNewPaymentMethod() {
    // TODO: Implement add new payment method functionality
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Payment Method',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.orange),
              title: Text(
                'Credit/Debit Card',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to add card screen
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Colors.blue,
              ),
              title: Text(
                'PayPal',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to add PayPal screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
