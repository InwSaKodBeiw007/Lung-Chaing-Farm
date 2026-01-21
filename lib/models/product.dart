import 'package:flutter/foundation.dart';

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
  final int? lowStockSinceDate; // New field

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
    this.lowStockSinceDate,
  });

  Product copyWith({
    int? id,
    String? name,
    double? price,
    double? stock,
    int? ownerId,
    String? category,
    double? lowStockThreshold,
    String? farmName,
    List<String>? imageUrls,
    int? lowStockSinceDate,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      ownerId: ownerId ?? this.ownerId,
      category: category ?? this.category,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      farmName: farmName ?? this.farmName,
      imageUrls: imageUrls ?? this.imageUrls,
      lowStockSinceDate: lowStockSinceDate ?? this.lowStockSinceDate,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // The images will need to be constructed from the joined table
    // This is a placeholder for now and will be updated when the API service is updated
    final List<String> images = (json['image_urls'] as String?)
        ?.split(',')
        .where((s) => s.isNotEmpty) // Filter out empty strings
        .map((image) {
          final String fullImageUrl = image.startsWith('uploads/')
              ? 'http://10.0.2.2:3000/${image}' // For Android emulator
              : 'http://localhost:3000/${image}'; // For web
          return fullImageUrl;
        })
        .toList() ??
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
      lowStockSinceDate: json['low_stock_since_date'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'owner_id': ownerId,
      'category': category,
      'low_stock_threshold': lowStockThreshold,
      'farm_name': farmName,
      'image_urls': imageUrls.join(','), // Convert list back to comma-separated string for backend
      'low_stock_since_date': lowStockSinceDate,
    };
  }
}
