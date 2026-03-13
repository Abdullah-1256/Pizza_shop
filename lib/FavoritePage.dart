import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/utils/favorite_manager.dart';
import '../core/utils/selected_pizza_manager.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<String> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favoriteManager = FavoriteManager();
    final favorites = await favoriteManager.getFavorites();
    if (mounted) {
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF5EE),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF5EE),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/product'),
          ),
          title: Text(
            "❤️ Favorite Items",
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EE),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/product'),
        ),
        title: Text(
          "❤️ Favorite Items",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: _favorites.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No favorite items yet',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some pizzas to your favorites!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final favoriteName = _favorites[index];
                  // For demo, we'll use static data. In real app, you'd have a data source
                  final pizzaData = _getPizzaData(favoriteName);
                  return favoriteCard(
                    image: pizzaData['image']!,
                    name: pizzaData['name']!,
                    desc: pizzaData['desc']!,
                    price: pizzaData['price']!,
                    index: index,
                  );
                },
              ),
      ),
    );
  }

  /// Show quantity selector modal for adding to cart
  void _showQuantitySelector(
    BuildContext context, {
    required String name,
    required String image,
    required String desc,
    required String price,
    required int index,
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
                            image: AssetImage(image),
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
                            _calculateTotal(price, selectedQuantity),
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
                            id: '${name}_${index}', // Use name and index as unique ID
                            name: name,
                            image: image,
                            description: desc,
                            price: numericPrice,
                            quantity: selectedQuantity,
                            category: 'Pizza', // Default category
                          );

                          Navigator.pop(context);

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
    return 'Rs. ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]},')}';
  }

  Map<String, String> _getPizzaData(String name) {
    // Static data for demo. In real app, this would come from a data source
    final pizzaMap = {
      'Pepperoni Pizza': {
        'image': 'assets/images/pizza_icon.png',
        'name': 'Pepperoni Pizza',
        'desc': 'Spicy pepperoni & cheese topping',
        'price': 'Rs. 1,299',
      },
      'Pizza Cheese': {
        'image': 'assets/images/pizza_icon.png',
        'name': 'Pizza Cheese',
        'desc': 'Dish cuisine fast food, flatbread, ingredient',
        'price': 'Rs. 1,099',
      },
      'Mexican Green Wave': {
        'image': 'assets/images/pizza_icon.png',
        'name': 'Mexican Green Wave',
        'desc': 'Crunchy onion, tomato, capsicum, juicy tomatoes',
        'price': 'Rs. 1,499',
      },
      'Peppy Paneer': {
        'image': 'assets/images/pizza_icon.png',
        'name': 'Peppy Paneer',
        'desc': 'Chunky paneer, capsicum, and red pepper',
        'price': 'Rs. 1,399',
      },
    };

    return pizzaMap[name] ??
        {
          'image': 'assets/images/pizza_icon.png',
          'name': name,
          'desc': 'Favorite pizza',
          'price': 'Rs. 1,000',
        };
  }

  /// 🔹 Reusable Favorite Card Widget
  Widget favoriteCard({
    required String image,
    required String name,
    required String desc,
    required String price,
    required int index,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          /// 🔹 Product Image
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),

          /// 🔹 Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
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
              ],
            ),
          ),

          /// 🔹 Action Buttons
          Column(
            children: [
              /// Add to Cart Button
              GestureDetector(
                onTap: () => _showQuantitySelector(
                  context,
                  name: name,
                  image: image,
                  desc: desc,
                  price: price,
                  index: index,
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),

              /// Remove Favorite Icon
              GestureDetector(
                onTap: () async {
                  final favoriteManager = FavoriteManager();
                  await favoriteManager.toggleFavorite(name);
                  await _loadFavorites(); // Reload favorites after removal
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5EE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.orange),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
