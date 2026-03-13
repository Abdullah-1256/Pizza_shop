class UserNotifications {
  final String id;
  final String userId;
  bool orderUpdates;
  bool promotionalOffers;
  bool newArrivals;
  bool deliveryAlerts;
  bool accountActivity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserNotifications({
    required this.id,
    required this.userId,
    this.orderUpdates = true,
    this.promotionalOffers = false,
    this.newArrivals = true,
    this.deliveryAlerts = true,
    this.accountActivity = false,
    this.createdAt,
    this.updatedAt,
  });

  UserNotifications copyWith({
    String? id,
    String? userId,
    bool? orderUpdates,
    bool? promotionalOffers,
    bool? newArrivals,
    bool? deliveryAlerts,
    bool? accountActivity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserNotifications(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotionalOffers: promotionalOffers ?? this.promotionalOffers,
      newArrivals: newArrivals ?? this.newArrivals,
      deliveryAlerts: deliveryAlerts ?? this.deliveryAlerts,
      accountActivity: accountActivity ?? this.accountActivity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_updates': orderUpdates,
      'promotional_offers': promotionalOffers,
      'new_arrivals': newArrivals,
      'delivery_alerts': deliveryAlerts,
      'account_activity': accountActivity,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserNotifications.fromJson(Map<String, dynamic> json) {
    return UserNotifications(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orderUpdates: json['order_updates'] as bool? ?? true,
      promotionalOffers: json['promotional_offers'] as bool? ?? false,
      newArrivals: json['new_arrivals'] as bool? ?? true,
      deliveryAlerts: json['delivery_alerts'] as bool? ?? true,
      accountActivity: json['account_activity'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  factory UserNotifications.create({
    required String userId,
    bool orderUpdates = true,
    bool promotionalOffers = false,
    bool newArrivals = true,
    bool deliveryAlerts = true,
    bool accountActivity = false,
  }) {
    return UserNotifications(
      id: '', // Will be set by database
      userId: userId,
      orderUpdates: orderUpdates,
      promotionalOffers: promotionalOffers,
      newArrivals: newArrivals,
      deliveryAlerts: deliveryAlerts,
      accountActivity: accountActivity,
    );
  }
}
