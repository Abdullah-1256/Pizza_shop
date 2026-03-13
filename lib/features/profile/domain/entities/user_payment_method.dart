enum PaymentMethodType { card, paypal, cash }

class UserPaymentMethod {
  final String id;
  final String userId;
  final PaymentMethodType type;
  final String? cardLastFour;
  final String? cardBrand;
  final String? paypalEmail;
  bool isDefault;
  final DateTime? createdAt;

  UserPaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    this.cardLastFour,
    this.cardBrand,
    this.paypalEmail,
    this.isDefault = false,
    this.createdAt,
  });

  String get displayName {
    switch (type) {
      case PaymentMethodType.card:
        return cardBrand != null && cardLastFour != null
            ? '$cardBrand **** $cardLastFour'
            : 'Credit/Debit Card';
      case PaymentMethodType.paypal:
        return paypalEmail ?? 'PayPal';
      case PaymentMethodType.cash:
        return 'Cash on Delivery';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case PaymentMethodType.card:
        return 'Credit/Debit Card';
      case PaymentMethodType.paypal:
        return 'PayPal';
      case PaymentMethodType.cash:
        return 'Cash on Delivery';
    }
  }

  String get iconName {
    switch (type) {
      case PaymentMethodType.card:
        return 'credit_card';
      case PaymentMethodType.paypal:
        return 'account_balance_wallet';
      case PaymentMethodType.cash:
        return 'money';
    }
  }

  UserPaymentMethod copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    String? cardLastFour,
    String? cardBrand,
    String? paypalEmail,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return UserPaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      cardLastFour: cardLastFour ?? this.cardLastFour,
      cardBrand: cardBrand ?? this.cardBrand,
      paypalEmail: paypalEmail ?? this.paypalEmail,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'card_last_four': cardLastFour,
      'card_brand': cardBrand,
      'paypal_email': paypalEmail,
      'is_default': isDefault,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory UserPaymentMethod.fromJson(Map<String, dynamic> json) {
    return UserPaymentMethod(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: PaymentMethodType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentMethodType.card,
      ),
      cardLastFour: json['card_last_four'] as String?,
      cardBrand: json['card_brand'] as String?,
      paypalEmail: json['paypal_email'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  factory UserPaymentMethod.create({
    required String userId,
    required PaymentMethodType type,
    String? cardLastFour,
    String? cardBrand,
    String? paypalEmail,
    bool isDefault = false,
  }) {
    return UserPaymentMethod(
      id: '', // Will be set by database
      userId: userId,
      type: type,
      cardLastFour: cardLastFour,
      cardBrand: cardBrand,
      paypalEmail: paypalEmail,
      isDefault: isDefault,
    );
  }
}
