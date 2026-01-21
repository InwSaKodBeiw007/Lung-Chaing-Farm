// lib/models/product.dart
class Product {
  final int id;
  final String name;
  final double price;
  final double stock;
  final int ownerId;
  final String? category;
  final double? lowStockThreshold;
  final String? farmName;
  final List<String> imageUrls;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.ownerId,
    this.category,
    this.lowStockThreshold,
    this.farmName,
    this.imageUrls = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // The images will need to be constructed from the joined table
    // This is a placeholder for now and will be updated when the API service is updated
    final List<String> images =
        (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [];

    return Product(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toDouble(),
      ownerId: json['owner_id'] ?? 0, // Handle potential null
      category: json['category'],
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toDouble(),
      farmName: json['farm_name'],
      imageUrls: images,
    );
  }
}
