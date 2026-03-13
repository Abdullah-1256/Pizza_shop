import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/network/supabase_client.dart';

class WaiterTakeOrderPage extends StatefulWidget {
  const WaiterTakeOrderPage({super.key});

  @override
  State<WaiterTakeOrderPage> createState() => _WaiterTakeOrderPageState();
}

class _WaiterTakeOrderPageState extends State<WaiterTakeOrderPage> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Pizza',
    'Burger',
    'Shawarma',
    'Pasta',
    'Drinks',
  ];

  // Dynamic products data loaded from database
  List<Map<String, String>> _allProducts = [];
  bool _isLoading = true;

  // Cart for current order
  Map<String, int> _cartItems = {};
  double _totalAmount = 0.0;

  List<Map<String, String>> get _filteredProducts {
    if (_selectedCategory == 'All') {
      return _allProducts;
    }
    return _allProducts
        .where((product) => product['category'] == _selectedCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await Supabase.instance.client
          .from('products')
          .select('id, name, description, price, category, image_url')
          .eq('is_available', true)
          .order('name');

      setState(() {
        _allProducts = products
            .map(
              (product) => {
                'id': product['id'].toString(),
                'name': product['name'].toString(),
                'desc': product['description'].toString(),
                'price': product['price'].toString(),
                'category': product['category'].toString(),
                'image': product['image_url'].toString(),
              },
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  void _addToCart(String productId, String name, String price) {
    setState(() {
      _cartItems[productId] = (_cartItems[productId] ?? 0) + 1;
      _totalAmount += double.parse(price.replaceAll(RegExp(r'[^\d.]'), ''));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added to order!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(String productId, String price) {
    if (_cartItems[productId] != null && _cartItems[productId]! > 0) {
      setState(() {
        _cartItems[productId] = _cartItems[productId]! - 1;
        _totalAmount -= double.parse(price.replaceAll(RegExp(r'[^\d.]'), ''));
        if (_cartItems[productId] == 0) {
          _cartItems.remove(productId);
        }
      });
    }
  }

  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Current Order',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _cartItems.isEmpty
              ? Text(
                  'No items in order!',
                  style: GoogleFonts.poppins(),
                  textAlign: TextAlign.center,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._cartItems.entries.map((entry) {
                      final product = _allProducts.firstWhere(
                        (p) => p['id'] == entry.key,
                      );
                      return ListTile(
                        title: Text(
                          product['name']!,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        subtitle: Text(
                          'Qty: ${entry.value}',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        trailing: Text(
                          'Rs. ${(double.parse(product['price']!.replaceAll(RegExp(r'[^\d.]'), '')) * entry.value).toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      );
                    }),
                    const Divider(),
                    Text(
                      'Total: Rs. ${_totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue Adding', style: GoogleFonts.poppins()),
          ),
          if (_cartItems.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _placeOrder();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Place Order', style: GoogleFonts.poppins()),
            ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_cartItems.isEmpty) return;

    try {
      // Create order
      // Use the authenticated waiter's user ID for dine-in orders
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final orderResponse = await Supabase.instance.client
          .from('orders')
          .insert({
            'user_id': currentUser.id, // Use waiter's user ID
            'status': 'confirmed',
            'total_amount': _totalAmount,
            'order_type': 'dine_in', // Mark as dine-in order
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final orderId = orderResponse['id'];

      // Add order items
      final orderItems = _cartItems.entries.map((entry) {
        final product = _allProducts.firstWhere((p) => p['id'] == entry.key);
        return {
          'order_id': orderId,
          'product_id': entry.key,
          'quantity': entry.value,
          'price': double.parse(
            product['price']!.replaceAll(RegExp(r'[^\d.]'), ''),
          ),
        };
      }).toList();

      await Supabase.instance.client.from('order_items').insert(orderItems);

      // Clear cart
      setState(() {
        _cartItems.clear();
        _totalAmount = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to dashboard
      NavigationHelper.safeGo(context, '/waiter-dashboard');
    } catch (e) {
      print('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to place order. Please try again.'),
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
          "Take Order",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.orange),
                onPressed: _showCartDialog,
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _cartItems.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        label: Text(
                          category,
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = category);
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.orange,
                        checkmarkColor: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Products Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                        ),
                      )
                    : _filteredProducts.isEmpty
                    ? const Center(child: Text('No products available'))
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, String> product) {
    final quantity = _cartItems[product['id']] ?? 0;

    return Container(
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
          // Product Image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              image: DecorationImage(
                image: NetworkImage(product['image']!),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Product Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name']!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product['desc']!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  product['price']!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),

                // Quantity Controls
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: quantity > 0
                          ? () => _removeFromCart(
                              product['id']!,
                              product['price']!,
                            )
                          : null,
                      icon: Icon(
                        Icons.remove,
                        size: 20,
                        color: quantity > 0 ? Colors.orange : Colors.grey,
                      ),
                    ),
                    Text(
                      quantity.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _addToCart(
                        product['id']!,
                        product['name']!,
                        product['price']!,
                      ),
                      icon: const Icon(
                        Icons.add,
                        size: 20,
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
    );
  }
}
