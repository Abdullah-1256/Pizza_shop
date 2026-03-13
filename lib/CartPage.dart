import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/location_service.dart';
import 'core/utils/selected_pizza_manager.dart';
import 'core/utils/navigation_helper.dart';
import 'core/utils/shared_preferences_helper.dart';
import 'features/order_tracking/presentation/pages/order_tracking_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _paymentMethod = 'Cash on Delivery';
  String _currentLocation = 'Getting location...';
  bool _isLocationLoading = true;

  // Animation controller for success popup
  late AnimationController _successController;
  late Animation<double> _successAnimation;
  bool _showSuccessPopup = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadCartItems();

    // Initialize success animation
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Future<bool> onWillPop() async {
    // Handle system back button properly
    return await NavigationHelper.handleBackButton(
      context,
      fallbackRoute: '/product',
    );
  }

  Future<void> _getCurrentLocation() async {
    final locationService = LocationService();
    if (mounted) {
      setState(() {
        _isLocationLoading = true;
      });
    }

    final address = await locationService.getDeliveryAddress();
    if (mounted) {
      setState(() {
        _currentLocation = address;
        _addressController.text = address;
        _isLocationLoading = false;
      });
    }

    // If location fetch failed, show option to select saved address
    if (address ==
            'Please enable location services for accurate delivery address' ||
        address == 'Unable to get address') {
      _showAddressSelectionDialog();
    }
  }

  void _loadCartItems() {
    // Cart items are managed by CartManager
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cartManager = CartManager();
    final cartItems = cartManager.getCartItems();
    final isEmpty = cartManager.isEmpty;

    // Debug: Print cart items and total price
    print('Cart Items: ${cartItems.length}');
    print('Total Price: ${cartManager.totalPrice}');
    for (var item in cartItems) {
      print(
        'Item: ${item.name}, Price: ${item.price}, Quantity: ${item.quantity}, Total: ${item.totalPrice}',
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationHelper.handleBackButton(
            context,
            fallbackRoute: '/product',
          ),
        ),
        title: Text(
          "🛒 My Cart (${cartManager.totalItems})",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showClearCartDialog(),
            ),
        ],
      ),
      body: isEmpty ? _buildEmptyCart() : _buildCartWithItems(cartManager),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some delicious items to get started!',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => NavigationHelper.safePush(context, '/product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Browse Menu',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartWithItems(CartManager cartManager) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cart Items
                Text(
                  'Your Order (${cartManager.totalItems} items)',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCartItems(cartManager),

                const SizedBox(height: 24),

                // Delivery Details Section
                Text(
                  'Delivery Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Number
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+92 300 1234567',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Delivery Address
                TextField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Delivery Address',
                    hintText: 'Enter your delivery address',
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.edit_location_alt,
                        color: Colors.orange,
                      ),
                      onPressed: _showOrderAddressSelectionDialog,
                      tooltip: 'Choose delivery address',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Current Location Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      if (_isLocationLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        )
                      else
                        const Icon(Icons.my_location, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isLocationLoading
                              ? 'Getting current location...'
                              : 'Current Location: $_currentLocation',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (!_isLocationLoading &&
                          (_currentLocation ==
                                  'Please enable location services for accurate delivery address' ||
                              _currentLocation == 'Unable to get address'))
                        IconButton(
                          onPressed: _showAddressSelectionDialog,
                          icon: const Icon(
                            Icons.edit_location_alt,
                            color: Colors.orange,
                          ),
                          tooltip: 'Select saved address',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Method Section
                Text(
                  'Payment Method',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Options
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildPaymentOption('Cash on Delivery', Icons.money),
                      _buildPaymentOption('Credit Card', Icons.credit_card),
                      _buildPaymentOption(
                        'JazzCash',
                        Icons.account_balance_wallet,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Order Summary and Place Order Button
        _buildOrderSummary(cartManager),
      ],
    );
  }

  Widget _buildCartItems(CartManager cartManager) {
    final items = cartManager.getCartItems();

    return Column(
      children: items.map((item) => _buildCartItem(item, cartManager)).toList(),
    );
  }

  Widget _buildCartItem(CartItem item, CartManager cartManager) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          // Product Image
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(item.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs. ${item.price.toStringAsFixed(0)} each',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls and Total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          cartManager.decreaseQuantity(item.id);
                        });
                      },
                      icon: const Icon(
                        Icons.remove,
                        color: Colors.white,
                        size: 16,
                      ),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          cartManager.increaseQuantity(item.id);
                        });
                      },
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Item Total
              Text(
                'Rs. ${item.totalPrice.round()}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon) {
    final isSelected = _paymentMethod == method;
    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade300,
              width: method == 'JazzCash' ? 0 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.orange : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                method,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: isSelected ? Colors.orange : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartManager cartManager) {
    final items = cartManager.getCartItems();
    double subtotal = 0.0;

    // Calculate subtotal by summing all item total prices
    for (var item in items) {
      subtotal += item.totalPrice;
    }

    final deliveryFee = 150.0;
    final total = subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
          // Itemized breakdown
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} x${item.quantity}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Text(
                    'Rs. ${item.totalPrice.round()}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.black12),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
              ),
              Text(
                'Rs. ${subtotal.round()}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fee',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
              ),
              Text(
                'Rs. ${deliveryFee.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.black12),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Rs. ${total.round()}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placeOrder,
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
                'Place Order',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _placeOrder() async {
    // Check if user is authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showAuthenticationRequiredDialog();
      return;
    }

    // Get user profile data for order
    final userProfile = await SharedPreferencesHelper.getUserProfile();
    print('📋 Placing order for user: ${userProfile?['email'] ?? user.email}');

    if (_phoneController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all delivery details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Calculate total price
    final cartManager = CartManager();
    final cartItems = cartManager.getCartItems();
    double totalPrice = 0.0;
    for (var item in cartItems) {
      totalPrice += item.totalPrice;
    }
    final deliveryFee = 150.0;
    final finalTotal = totalPrice + deliveryFee;

    // Generate order number
    final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

    // Convert cart items to order items format
    final orderItems = cartItems
        .map(
          (item) => {
            'name': item.name,
            'quantity': item.quantity,
            'price': item.price,
          },
        )
        .toList();

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Processing your order...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Fetch current GPS location for order details
      final locationService = LocationService();
      final currentPosition = await locationService.getCurrentPosition();
      final locationDetails = await locationService.getFullAddressDetails();

      // First, create the order
      final orderData = {
        'user_id': user.id,
        'order_number': orderNumber,
        'total_amount': finalTotal,
        'status': 'pending',
        'delivery_address': _addressController.text,
        'phone_number': _phoneController.text,
        'payment_method': _paymentMethod,
        // Add GPS location data
        'city': locationDetails?['city'] ?? null,
        'postal_code': locationDetails?['postal_code'] ?? null,
        'latitude': currentPosition?.latitude,
        'longitude': currentPosition?.longitude,
      };

      final orderResponse = await Supabase.instance.client
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'];
      print('✅ Order created successfully: $orderId');

      // Then, create order items for each cart item
      for (final cartItem in cartItems) {
        final orderItemData = {
          'order_id': orderId,
          'product_id': cartItem.id, // Assuming cart item id is the product id
          'product_name': cartItem.name,
          'quantity': cartItem.quantity,
          'price': cartItem.price,
          'total': cartItem.totalPrice,
        };

        await Supabase.instance.client
            .from('order_items')
            .insert(orderItemData);
      }

      print('✅ Order items created successfully');

      // Show success message and navigate back to product screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order placed successfully! Order #${orderData['order_number'] ?? orderId.substring(0, 8)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to product screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            NavigationHelper.safePush(context, '/product');
          }
        });
      }
    } catch (e) {
      print('❌ Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessPopupWithAnimation() {
    if (mounted) {
      setState(() {
        _showSuccessPopup = true;
      });
      _successController.forward();
    }
  }

  void _showAuthenticationRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Authentication Required',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'You need to sign in to place an order. Would you like to sign in now?',
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
            onPressed: () {
              Navigator.pop(context);
              NavigationHelper.safePush(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Sign In', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Cart',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove all items from your cart?',
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
            onPressed: () {
              Navigator.pop(context);
              CartManager().clearCart();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showOrderSuccessDialog(String orderId, Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Order Confirmed!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order has been placed successfully.\nOrder #${orderData['order_number'] ?? orderId.substring(0, 8)}',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.delivery_dining,
                    color: Colors.orange,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Track Your Order',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Get live updates with map',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      // Navigate to order tracking page
                      context
                          .push(
                            '/order-tracking',
                            extra: {'orderId': orderId, 'orderData': orderData},
                          )
                          .then((_) {
                            // Clear cart when returning from tracking page
                            CartManager().clearCart();
                            if (mounted) {
                              setState(() {});
                            }
                          });
                    },
                    icon: const Icon(Icons.arrow_forward, color: Colors.orange),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear cart and go back to home
              CartManager().clearCart();
              if (mounted) {
                NavigationHelper.safePush(context, '/product');
              }
            },
            child: Text(
              'Continue Shopping',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressSelectionDialog() async {
    // Try to get current city from GPS first
    final locationService = LocationService();
    final currentCity = await locationService.getCurrentCity();

    // Mock saved addresses filtered by current city - in real app, this would come from database
    final List<Map<String, String>> savedAddresses = [];

    if (currentCity != null) {
      // Filter addresses by current city
      if (currentCity.toLowerCase().contains('karachi')) {
        savedAddresses.addAll([
          {'label': 'Home', 'address': '123 Main Street, Karachi, Pakistan'},
          {
            'label': 'Office',
            'address': '456 Business Avenue, Karachi, Pakistan',
          },
          {
            'label': 'Friend\'s Place',
            'address': '789 Residential Area, Karachi, Pakistan',
          },
        ]);
      } else if (currentCity.toLowerCase().contains('lahore')) {
        savedAddresses.addAll([
          {'label': 'Home', 'address': '456 Model Town, Lahore, Pakistan'},
          {'label': 'Office', 'address': '789 Gulberg, Lahore, Pakistan'},
        ]);
      } else if (currentCity.toLowerCase().contains('islamabad')) {
        savedAddresses.addAll([
          {'label': 'Home', 'address': '321 F-10, Islamabad, Pakistan'},
          {'label': 'Office', 'address': '654 Blue Area, Islamabad, Pakistan'},
        ]);
      }
    }

    // Add fallback addresses if no city-specific ones found
    if (savedAddresses.isEmpty) {
      savedAddresses.addAll([
        {
          'label': 'Default Address',
          'address': 'Enter your delivery address manually',
        },
      ]);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Delivery Address',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentCity != null
                  ? 'GPS detected you\'re in $currentCity. Select a saved address or enter manually.'
                  : 'GPS location not available. Please select a saved address or enter manually.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...savedAddresses.map(
              (address) => ListTile(
                leading: const Icon(Icons.location_on, color: Colors.orange),
                title: Text(
                  address['label']!,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  address['address']!,
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                onTap: () {
                  setState(() {
                    _addressController.text = address['address']!;
                    _currentLocation = address['address']!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Enter Manually',
              style: GoogleFonts.poppins(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderAddressSelectionDialog() async {
    // Add current location option
    final List<Map<String, dynamic>> addressOptions = [
      {
        'id': 'current_location',
        'label': 'Current Location',
        'address': _currentLocation,
        'is_current': true,
      },
    ];

    // Try to get saved addresses from Supabase
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final addressesResponse = await Supabase.instance.client
            .from('delivery_addresses')
            .select()
            .eq('user_id', user.id)
            .order('created_at');

        final List<Map<String, dynamic>> savedAddresses =
            List<Map<String, dynamic>>.from(addressesResponse);

        // Add saved addresses with proper formatting
        addressOptions.addAll(
          savedAddresses.map(
            (addr) => {
              'id': addr['id'],
              'label': addr['label'] ?? 'Saved Address',
              'address':
                  '${addr['address_line1'] ?? ''}${addr['address_line2'] != null && addr['address_line2'].toString().isNotEmpty ? '\n${addr['address_line2']}' : ''}\n${addr['city'] ?? ''}',
              'is_saved': true,
            },
          ),
        );
      }
    } catch (e) {
      print('Error loading saved addresses: $e');
      // Add fallback mock addresses if database fails
      addressOptions.addAll([
        {
          'id': 'home_mock',
          'label': 'Home',
          'address': '123 Main Street, Karachi, Pakistan',
          'is_saved': true,
        },
        {
          'id': 'office_mock',
          'label': 'Office',
          'address': '456 Business Avenue, Karachi, Pakistan',
          'is_saved': true,
        },
      ]);
    }

    // Always add manual entry option at the end
    addressOptions.add({
      'id': 'manual_entry',
      'label': 'Enter Manually',
      'address': 'Enter a new delivery address',
      'is_manual': true,
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Choose Delivery Address',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select where you want your order delivered:',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...addressOptions.map(
                (address) => ListTile(
                  leading: Icon(
                    address['is_current'] == true
                        ? Icons.my_location
                        : address['is_manual'] == true
                        ? Icons.edit
                        : Icons.location_on,
                    color: Colors.orange,
                  ),
                  title: Text(
                    address['label'] as String,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    address['address'] as String,
                    style: GoogleFonts.poppins(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    if (address['is_manual'] == true) {
                      // For manual entry, just close dialog and let user edit the text field
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _addressController.text = address['address'] as String;
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // Success Animation Widget
  Widget _buildSuccessAnimation() {
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: _successAnimation.value * 20,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: _successAnimation.value,
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Transform.scale(
                    scale: _successAnimation.value,
                    child: Text(
                      'Order Placed!',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom widget to show success popup
class SuccessPopup extends StatelessWidget {
  final bool show;
  final AnimationController controller;
  final Animation<double> animation;

  const SuccessPopup({
    super.key,
    required this.show,
    required this.controller,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.6 * animation.value),
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3 * animation.value),
                    blurRadius: 30 * animation.value,
                    spreadRadius: 10 * animation.value,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: animation.value,
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 100,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Transform.scale(
                      scale: animation.value,
                      child: Text(
                        'Order Placed!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Transform.scale(
                      scale: animation.value,
                      child: Text(
                        'Thank you for your order!',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
