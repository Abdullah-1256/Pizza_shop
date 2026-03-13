class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String image;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.image,
    required this.isAvailable,
    this.createdAt,
    this.updatedAt,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? image,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      image: image ?? this.image,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image': image,
      'is_available': isAvailable,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      image: json['image'] as String,
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, category: $category, isAvailable: $isAvailable)';
  }
}
