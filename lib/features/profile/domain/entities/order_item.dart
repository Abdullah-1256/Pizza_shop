class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double total;
  final DateTime? createdAt;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
    this.createdAt,
  });

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    double? total,
    DateTime? createdAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'total': total,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'OrderItem(id: $id, productName: $productName, quantity: $quantity, total: $total)';
  }
}
