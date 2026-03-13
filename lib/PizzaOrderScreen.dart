import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/selected_pizza_manager.dart';
import 'core/utils/navigation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PizzaOrderScreen extends StatefulWidget {
  const PizzaOrderScreen({super.key});

  @override
  State<PizzaOrderScreen> createState() => _PizzaOrderScreenState();
}

class _PizzaOrderScreenState extends State<PizzaOrderScreen>
    with TickerProviderStateMixin {
  String _selectedSize = 'M';
  int _quantity = 1;

  final List<String> _sizes = ['S', 'M', 'L'];
  final List<IconData> _ingredients = [
    Icons.local_pizza,
    Icons.circle,
    Icons.local_florist,
    Icons.grass,
    Icons.rice_bowl,
    Icons.set_meal,
  ];

  late Map<String, String> _selectedPizza;

  // Animation controllers for success popup
  late AnimationController _successController;
  late Animation<double> _successAnimation;
  bool _showSuccessPopup = false;

  @override
  void initState() {
    super.initState();
    _selectedPizza = {
      'name': 'Pepperoni Pizza',
      'image': 'assets/images/pizza_icon.png',
      'desc':
          'Pepperoni pizza, Margherita Pizza Margherita Italian cuisine Tomato',
      'price': '1200',
    };

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
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double width = size.width;
    final double height = size.height;

    final double hPad = width * 0.06;
    final double vGap = height * 0.025;
    final double pizzaRadius = width * 0.28;
    final double sizeBox = width * 0.12;
    final double ingPad = width * 0.025;
    final double btnHeight = width * 0.14;
    final double btnRadius = width * 0.08;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(bottom: btnHeight + vGap),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: vGap * 0.5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: () =>
                                NavigationHelper.safeGo(context, '/product'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined),
                            onPressed: () =>
                                NavigationHelper.safePush(context, '/cart'),
                          ),
                        ],
                      ),
                    ),

                    // Pizza Image
                    SizedBox(
                      height: pizzaRadius * 2 + 60,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            top: -30,
                            child: Transform.rotate(
                              angle: -0.4,
                              child: Opacity(
                                opacity: 0.4,
                                child: Image.asset(
                                  'assets/images/pizza bg.jpg',
                                  width: pizzaRadius * 1.6,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: pizzaRadius * 0.15),
                            child: CircleAvatar(
                              radius: pizzaRadius,
                              backgroundImage: AssetImage(
                                _selectedPizza['image'] ??
                                    'assets/images/pizza bg.jpg',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: vGap),

                    // Size Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _sizes.map((s) {
                        final bool selected = s == _selectedSize;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSize = s),
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: width * 0.03,
                            ),
                            width: sizeBox,
                            height: sizeBox,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? Colors.orange : Colors.white,
                              border: Border.all(
                                color: Colors.orange,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: sizeBox * 0.45,
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : Colors.orange,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: vGap * 0.8),

                    // Title
                    Text(
                      _selectedPizza['name'] ?? 'Pepperoni Pizza',
                      style: TextStyle(
                        fontSize: width * 0.065,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: vGap * 0.3),

                    // Subtitle
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Text(
                        _selectedPizza['desc'] ??
                            'Delicious pizza with fresh ingredients',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: width * 0.038,
                        ),
                      ),
                    ),
                    SizedBox(height: vGap * 0.4),

                    // Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: width * 0.055,
                        ),
                        SizedBox(width: width * 0.01),
                        Text(
                          '5/5',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: width * 0.045,
                          ),
                        ),
                        SizedBox(width: width * 0.02),
                        Text(
                          '100%',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: width * 0.045,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: vGap),

                    // Ingredients
                    Text(
                      'Ingredients (Customizable)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.045,
                      ),
                    ),
                    SizedBox(height: vGap * 0.6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _ingredients.map((icon) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: width * 0.015,
                          ),
                          padding: EdgeInsets.all(ingPad),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFFFCC80),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.orange,
                            size: width * 0.06,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: vGap),

                    // Quantity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline,
                            size: width * 0.08,
                            color: Colors.orange,
                          ),
                          onPressed: () => setState(
                            () => _quantity = _quantity > 1 ? _quantity - 1 : 1,
                          ),
                        ),
                        Text(
                          '$_quantity',
                          style: TextStyle(
                            fontSize: width * 0.06,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            size: width * 0.08,
                            color: Colors.orange,
                          ),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Success Animation Overlay
            if (_showSuccessPopup) _buildSuccessAnimation(),
          ],
        ),
      ),

      // Order Button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vGap * 0.5),
          child: SizedBox(
            height: btnHeight,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(btnRadius),
                ),
              ),
              onPressed: _orderNow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontSize: width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Text(
                    'Rs. ${_calculateTotalPrice()}',
                    style: TextStyle(
                      fontSize: width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _orderNow() {
    // Get the cart manager and add the item
    final cartManager = CartManager();

    // Calculate the actual price based on size and quantity
    var basePrice = int.parse(
      (_selectedPizza['price'] ?? '1200').replaceAll(RegExp(r'[^\d]'), ''),
    ).toDouble();

    if (basePrice < 1) {
      basePrice *= 10000;
    }

    // Apply size multiplier
    double sizeMultiplier = 1.0;
    switch (_selectedSize) {
      case 'S':
        sizeMultiplier = 0.8;
        break;
      case 'M':
        sizeMultiplier = 1.0;
        break;
      case 'L':
        sizeMultiplier = 1.3;
        break;
    }

    final finalPrice = basePrice * sizeMultiplier;

    // Add item to cart with calculated price and quantity
    cartManager.addItem(
      id: '${_selectedPizza['name']}_$_selectedSize',
      name: '${_selectedPizza['name']} ($_selectedSize)',
      image: _selectedPizza['image'] ?? 'assets/images/pizza_icon.png',
      description: _selectedPizza['desc'] ?? 'Delicious pizza',
      price: finalPrice,
      quantity: _quantity,
      category: 'Pizza',
    );

    // Show success animation
    _showSuccessPopupWithAnimation();

    // Navigate to cart after a delay
    Future.delayed(const Duration(seconds: 2), () {
      NavigationHelper.safePush(context, '/cart');
    });
  }

  void _showSuccessPopupWithAnimation() {
    if (mounted) {
      setState(() {
        _showSuccessPopup = true;
      });
      _successController.forward();
    }
  }

  // Success Animation Widget
  Widget _buildSuccessAnimation() {
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.6 * _successAnimation.value),
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(
                      0.3 * _successAnimation.value,
                    ),
                    blurRadius: 30 * _successAnimation.value,
                    spreadRadius: 10 * _successAnimation.value,
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
                        size: 100,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Transform.scale(
                      scale: _successAnimation.value,
                      child: Text(
                        'Added to Cart!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Transform.scale(
                      scale: _successAnimation.value,
                      child: Text(
                        '${_selectedPizza['name']} added successfully',
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

  String _calculateTotalPrice() {
    var basePrice = double.parse(
      (_selectedPizza['price'] ?? '1299').replaceAll(RegExp(r'[^\d.]'), ''),
    );

    if (basePrice < 1) {
      basePrice *= 10000;
    }

    // Apply size multiplier
    double sizeMultiplier = 1.0;
    switch (_selectedSize) {
      case 'S':
        sizeMultiplier = 0.8;
        break;
      case 'M':
        sizeMultiplier = 1.0;
        break;
      case 'L':
        sizeMultiplier = 1.3;
        break;
    }

    final total = basePrice * sizeMultiplier * _quantity;
    return total.toStringAsFixed(0);
  }
}
