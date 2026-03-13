import 'dart:convert';

class CartItem {
  final String id;
  final String name;
  final String image;
  final String description;
  final double price;
  int quantity;
  final String category;

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.price,
    this.quantity = 1,
    required this.category,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'description': description,
      'price': price,
      'quantity': quantity,
      'category': category,
      'totalPrice': totalPrice,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] ?? 1,
      category: map['category'] ?? '',
    );
  }
}

class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _cartItems = [];

  // Add item to cart
  void addItem({
    required String id,
    required String name,
    required String image,
    required String description,
    required double price,
    int quantity = 1,
    required String category,
  }) {
    // Check if item already exists in cart
    final existingIndex = _cartItems.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      // Item exists, increase quantity
      _cartItems[existingIndex].quantity += quantity;
    } else {
      // Item doesn't exist, add new item
      _cartItems.add(
        CartItem(
          id: id,
          name: name,
          image: image,
          description: description,
          price: price,
          quantity: quantity,
          category: category,
        ),
      );
    }
  }

  // Remove item from cart
  void removeItem(String id) {
    _cartItems.removeWhere((item) => item.id == id);
  }

  // Update item quantity
  void updateQuantity(String id, int quantity) {
    final item = _cartItems.firstWhere(
      (item) => item.id == id,
      orElse: () => throw Exception('Item not found'),
    );

    if (quantity <= 0) {
      removeItem(id);
    } else {
      item.quantity = quantity;
    }
  }

  // Increase quantity
  void increaseQuantity(String id) {
    final item = _cartItems.firstWhere(
      (item) => item.id == id,
      orElse: () => throw Exception('Item not found'),
    );
    item.quantity++;
  }

  // Decrease quantity
  void decreaseQuantity(String id) {
    final item = _cartItems.firstWhere(
      (item) => item.id == id,
      orElse: () => throw Exception('Item not found'),
    );

    if (item.quantity > 1) {
      item.quantity--;
    } else {
      removeItem(id);
    }
  }

  // Get all cart items
  List<CartItem> getCartItems() {
    return List.unmodifiable(_cartItems);
  }

  // Get cart item by ID
  CartItem? getItem(String id) {
    try {
      return _cartItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if item is in cart
  bool isInCart(String id) {
    return _cartItems.any((item) => item.id == id);
  }

  // Get total items count
  int get totalItems {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get total price
  double get totalPrice {
    double total = 0.0;
    for (var item in _cartItems) {
      total += item.totalPrice;
    }
    return total;
  }

  // Clear cart
  void clearCart() {
    _cartItems.clear();
  }

  // Check if cart is empty
  bool get isEmpty => _cartItems.isEmpty;
}
