import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/favorite_manager.dart';
import '../../../../core/utils/location_service.dart';
import '../../../../core/utils/selected_pizza_manager.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/utils/shared_preferences_helper.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/delivery_location_service.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _currentLocation = 'Getting location...';
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

  // Order tracking state
  Map<String, dynamic>? _activeOrder;
  StreamSubscription? _orderUpdatesSubscription;
  String? _currentUserId;
  bool _showTrackingBox = false;

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
    _getCurrentLocation();
    _loadUserProfile();
    _loadProducts();
    _setupRealtimeSubscription();
  }

  Future<void> _loadUserProfile() async {
    final userProfile = await SharedPreferencesHelper.getUserProfile();
    if (userProfile != null) {
      print('👤 User profile loaded: ${userProfile['email']}');
      _currentUserId = userProfile['id'];
      setState(() {
        // You can use this data to personalize the UI
        // For example, show user name in header, etc.
      });
      // Load active orders after getting user profile
      _loadActiveOrder();
    }
  }

  Future<void> _loadActiveOrder() async {
    if (_currentUserId == null) return;

    try {
      // Get orders that are not delivered
      final ordersResponse = await Supabase.instance.client
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', _currentUserId!)
          .neq('status', 'delivered')
          .order('created_at', ascending: false)
          .limit(1);

      if (ordersResponse.isNotEmpty && mounted) {
        final order = ordersResponse.first;
        setState(() {
          _activeOrder = order;
          _showTrackingBox = true;
        });
        print('📦 Active order found: ${order['order_number']}');
      } else {
        setState(() {
          _activeOrder = null;
          _showTrackingBox = false;
        });
      }
    } catch (e) {
      print('❌ Error loading active order: $e');
      setState(() {
        _activeOrder = null;
        _showTrackingBox = false;
      });
    }
  }

  void _setupRealtimeSubscription() {
    // Listen for order status changes
    _orderUpdatesSubscription = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
          if (_currentUserId != null && mounted) {
            // Check if any of the updated orders belong to current user and are not delivered
            final userOrders = data.where(
              (order) =>
                  order['user_id'] == _currentUserId &&
                  order['status'] != 'delivered',
            );

            if (userOrders.isNotEmpty) {
              // Update active order if it's different
              final latestOrder = userOrders.first;
              if (_activeOrder == null ||
                  _activeOrder!['id'] != latestOrder['id']) {
                setState(() {
                  _activeOrder = latestOrder;
                  _showTrackingBox = true;
                });
              }
            } else {
              // No active orders, hide tracking box
              setState(() {
                _activeOrder = null;
                _showTrackingBox = false;
              });
            }
          }
        });
  }

  Future<void> _loadProducts() async {
    try {
      print('🔄 Starting to load products...');
      final products = await SupabaseService.getProducts();
      print('📦 Raw products response: ${products.length} items');

      setState(() {
        _allProducts = products.map((product) {
          print('🔄 Processing product: ${product['name']}');
          // Convert database product to UI format
          final priceValue = product['price'];
          final price = priceValue is int
              ? priceValue.toDouble()
              : (priceValue as double? ?? 0.0);
          final formattedPrice =
              'Rs. ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

          return {
            'id': product['id'] as String? ?? '',
            'name': product['name'] as String? ?? 'Unknown Product',
            'desc': product['description'] as String? ?? '',
            'price': formattedPrice,
            'image':
                product['image_url'] as String? ??
                product['image'] as String? ??
                'assets/images/pizza_icon.png',
            'category': product['category'] as String? ?? 'Pizza',
          };
        }).toList();
        _isLoading = false;
      });
      print(
        '✅ Successfully loaded ${_allProducts.length} products from database',
      );
    } catch (e, stackTrace) {
      print('❌ Error loading products: $e');
      print('❌ Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load products: ${e.toString()}. Please check your connection and try again.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      @override
      void dispose() {
        _orderUpdatesSubscription?.cancel();
        super.dispose();
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final locationService = LocationService();
    final address = await locationService.getDeliveryAddress();
    if (mounted) {
      setState(() {
        _currentLocation = address;
      });
    }
  }

  /// Show quantity selector modal
  void _showQuantitySelector(
    BuildContext context, {
    required String name,
    required String image,
    required String desc,
    required String price,
    required String category,
    required String itemId,
  }) {
    int selectedQuantity = 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Info
                  Row(
                    children: [
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: _getImageProvider(image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              price,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quantity Selector
                  Text(
                    'Select Quantity',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (selectedQuantity > 1) {
                              setModalState(() {
                                selectedQuantity--;
                              });
                            }
                          },
                          icon: const Icon(Icons.remove, color: Colors.orange),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Text(
                            '$selectedQuantity',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setModalState(() {
                              selectedQuantity++;
                            });
                          },
                          icon: const Icon(Icons.add, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Total and Add to Cart Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '${_calculateTotal(price, selectedQuantity)}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final cartManager = CartManager();

                          // Extract numeric price
                          var numericPrice = double.parse(
                            price.replaceAll(RegExp(r'[^\d.]'), ''),
                          );
                          if (numericPrice < 1) {
                            numericPrice *= 10000;
                          }

                          cartManager.addItem(
                            id: itemId,
                            name: name,
                            image: image,
                            description: desc,
                            price: numericPrice,
                            quantity: selectedQuantity,
                            category: category,
                          );

                          Navigator.pop(context);
                          setState(() {}); // Refresh the UI

                          // Show success feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$name added to cart!'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Add to Cart',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Calculate total price for given quantity
  String _calculateTotal(String price, int quantity) {
    var numericPrice = double.parse(price.replaceAll(RegExp(r'[^\d.]'), ''));
    if (numericPrice < 1) {
      numericPrice *= 10000;
    }
    final total = numericPrice * quantity;
    return 'Rs. ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EE),
      body: SafeArea(
        child: Column(
          children: [
            /// 🔹 Top App Bar Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// 🔹 Left side: logo + text
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Image.asset('assets/images/pizza_icon.png', height: 24),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pizza Time',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// 🔹 Right side: location + fav icon
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _currentLocation,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),

                        /// 🔹 Favorite Button with Route
                        GestureDetector(
                          onTap: () {
                            NavigationHelper.safePush(context, '/favorite');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.favorite_border,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// 🔹 Banner Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                width: double.infinity, // ✅ full width
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Image.asset(
                        'assets/images/chef.jpg',
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "🍕 Eat Fresh Pizza",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "🚀 Fast Delivery\n📍 Near For You",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// 🔹 Order Tracking Box (shown when there's an active order)
            if (_showTrackingBox && _activeOrder != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: GestureDetector(
                  onTap: () {
                    // Navigate to order tracking page
                    NavigationHelper.safePush(
                      context,
                      '/order-tracking',
                      extra: {
                        'orderId': _activeOrder!['id'],
                        'orderData': _activeOrder,
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delivery_dining,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
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
                                'Order #${_activeOrder!['order_number'] ?? _activeOrder!['id'].substring(0, 8)} • ${_getOrderStatusText(_activeOrder!['status'])}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            /// 🔹 Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search for favorite pizza",
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black45,
                        ),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _showCategoryFilter(context),
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.filter_list),
                    ),
                  ),
                ],
              ),
            ),

            /// 🔹 Pizza List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                        ),
                      )
                    : _allProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'No products available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: (_filteredProducts.length / 2).ceil(),
                        itemBuilder: (context, index) {
                          final startIndex = index * 2;
                          final endIndex = (startIndex + 2).clamp(
                            0,
                            _filteredProducts.length,
                          );
                          final rowProducts = _filteredProducts.sublist(
                            startIndex,
                            endIndex,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: rowProducts.map((product) {
                                final originalIndex = _allProducts.indexOf(
                                  product,
                                );
                                return pizzaCard(
                                  image: product['image']!,
                                  name: product['name']!,
                                  desc: product['desc']!,
                                  price: product['price']!,
                                  category: product['category']!,
                                  index: originalIndex,
                                  productId: product['id']!,
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),

      /// 🔹 Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 70,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.orange, size: 28),
              onPressed: () => NavigationHelper.safePush(context, '/home'),
            ),
            IconButton(
              icon: const Icon(
                Icons.favorite_border,
                color: Colors.black54,
                size: 26,
              ),
              onPressed: () => NavigationHelper.safePush(context, '/favorite'),
            ),
            IconButton(
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.black54,
                size: 26,
              ),
              onPressed: () => NavigationHelper.safePush(context, '/cart'),
            ),
            IconButton(
              icon: const Icon(
                Icons.person_outline,
                color: Colors.black54,
                size: 26,
              ),
              onPressed: () => NavigationHelper.safePush(context, '/profile'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Category',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orange
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.orange
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// Helper to get appropriate ImageProvider
  ImageProvider _getImageProvider(String? imagePath) {
    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
        return NetworkImage(imagePath);
      } else {
        return AssetImage(imagePath);
      }
    }
    return const AssetImage('assets/images/pizza_icon.png');
  }

  /// Helper to get human-readable order status text
  String _getOrderStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'Order Confirmed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'preparing':
        return 'Preparing Food';
      case 'ready':
        return 'Ready for Delivery';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Processing';
    }
  }

  /// 🔹 Reusable Pizza Card Widget with Quantity Selection
  Widget pizzaCard({
    required String image,
    required String name,
    required String desc,
    required String price,
    required String category,
    required int index,
    required String productId,
  }) {
    final favoriteManager = FavoriteManager();
    final cartManager = CartManager();

    // Check if item is in cart
    final itemId = productId;
    final isInCart = cartManager.isInCart(itemId);
    final cartItem = cartManager.getItem(itemId);

    return Container(
      width: MediaQuery.of(context).size.width * 0.42, // Responsive width
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          Center(
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: _getImageProvider(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final wasFavorite = await favoriteManager.isFavorite(name);
                    await favoriteManager.toggleFavorite(name);

                    // If it was not favorite (meaning we just added it), add to cart
                    if (!wasFavorite) {
                      // Parse price and add to cart
                      var numericPrice = double.parse(
                        price.replaceAll(RegExp(r'[^\d.]'), ''),
                      );
                      if (numericPrice < 1) {
                        numericPrice *= 10000;
                      }

                      cartManager.addItem(
                        id: productId,
                        name: name,
                        image: image,
                        description: desc,
                        price: numericPrice,
                        quantity: 1,
                        category: category,
                      );
                    }

                    setState(() {}); // Refresh UI
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      favoriteManager.isFavoriteSync(name)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.orange,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          // Add to Cart / Quantity Controls
          if (!isInCart) ...[
            // Add to Cart Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showQuantitySelector(
                  context,
                  name: name,
                  image: image,
                  desc: desc,
                  price: price,
                  category: category,
                  itemId: itemId,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC23C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Add to Cart",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Quantity Controls
            Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decrease Button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        cartManager.decreaseQuantity(itemId);
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

                  // Quantity Display
                  Text(
                    '${cartItem?.quantity ?? 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  // Increase Button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        cartManager.increaseQuantity(itemId);
                      });
                    },
                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
