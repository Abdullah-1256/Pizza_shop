enum OrderStatus { pending, confirmed, preparing, ready, delivered, cancelled }

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;

  Map<String, dynamic> toJson() {
    return {'name': name, 'quantity': quantity, 'price': price};
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }
}

class Order {
  final String id;
  final String userId;
  final String orderNumber;
  final OrderStatus status;
  final double totalAmount;
  final String? deliveryAddressId;
  final String? paymentMethodId;
  final List<OrderItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    this.deliveryAddressId,
    this.paymentMethodId,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get itemsSummary {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first.name;
    return '${items.first.name} + ${items.length - 1} more';
  }

  Order copyWith({
    String? id,
    String? userId,
    String? orderNumber,
    OrderStatus? status,
    double? totalAmount,
    String? deliveryAddressId,
    String? paymentMethodId,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddressId: deliveryAddressId ?? this.deliveryAddressId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_number': orderNumber,
      'status': status.name,
      'total_amount': totalAmount,
      'delivery_address_id': deliveryAddressId,
      'payment_method_id': paymentMethodId,
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orderNumber: json['order_number'] as String,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryAddressId: json['delivery_address_id'] as String?,
      paymentMethodId: json['payment_method_id'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
