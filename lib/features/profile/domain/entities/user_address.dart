class UserAddress {
  final String id;
  final String userId;
  final String label;
  final String streetAddress;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserAddress({
    required this.id,
    required this.userId,
    required this.label,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  String get fullAddress => '$streetAddress\n$city, $state $zipCode\n$country';

  UserAddress copyWith({
    String? id,
    String? userId,
    String? label,
    String? streetAddress,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'label': label,
      'street_address': streetAddress,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'is_default': isDefault,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      label: json['label'] as String,
      streetAddress: json['street_address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zip_code'] as String,
      country: json['country'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  factory UserAddress.create({
    required String userId,
    required String label,
    required String streetAddress,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    bool isDefault = false,
  }) {
    return UserAddress(
      id: '', // Will be set by database
      userId: userId,
      label: label,
      streetAddress: streetAddress,
      city: city,
      state: state,
      zipCode: zipCode,
      country: country,
      isDefault: isDefault,
    );
  }
}
