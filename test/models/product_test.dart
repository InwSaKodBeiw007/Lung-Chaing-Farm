import 'package:flutter_test/flutter_test.dart';
import 'package:lung_chaing_farm/models/product.dart';

void main() {
  group('Product', () {
    test('fromJson should correctly parse all fields including category', () {
      final jsonMap = {
        'id': 1,
        'name': 'Organic Carrot',
        'price': 2.5,
        'stock': 50.0,
        'owner_id': 101,
        'category': 'Vegetable',
        'low_stock_threshold': 10.0,
        'farm_name': 'Green Fields',
        'image_urls': 'uploads/carrot.jpg,uploads/carrot2.jpg',
        'low_stock_since_date': 1678886400,
      };

      final product = Product.fromJson(jsonMap);

      expect(product.id, 1);
      expect(product.name, 'Organic Carrot');
      expect(product.price, 2.5);
      expect(product.stock, 50.0);
      expect(product.ownerId, 101);
      expect(product.category, 'Vegetable');
      expect(product.lowStockThreshold, 10.0);
      expect(product.farmName, 'Green Fields');
      expect(product.imageUrls.length, 2);
      expect(
        product.imageUrls[0],
        contains('http://10.0.2.2:3000/uploads/carrot.jpg'),
      );
      expect(product.lowStockSinceDate, 1678886400);
    });

    test('fromJson should handle null category gracefully', () {
      final jsonMap = {
        'id': 2,
        'name': 'Fresh Milk',
        'price': 3.0,
        'stock': 20.0,
        'owner_id': 102,
        'category': null,
        'low_stock_threshold': 5.0,
        'farm_name': 'Dairy Farm',
        'image_urls': '',
        'low_stock_since_date': null,
      };

      final product = Product.fromJson(jsonMap);

      expect(product.category, isNull);
    });

    test('toJson should correctly serialize all fields including category', () {
      final product = Product(
        id: 3,
        name: 'Red Tomato',
        price: 1.8,
        stock: 75.0,
        ownerId: 103,
        category: 'Fruit',
        lowStockThreshold: 15.0,
        farmName: 'Sunny Farm',
        imageUrls: ['http://10.0.2.2:3000/uploads/tomato.jpg'],
        lowStockSinceDate: 1678887000,
      );

      final jsonMap = product.toJson();

      expect(jsonMap['id'], 3);
      expect(jsonMap['name'], 'Red Tomato');
      expect(jsonMap['price'], 1.8);
      expect(jsonMap['stock'], 75.0);
      expect(jsonMap['owner_id'], 103);
      expect(jsonMap['category'], 'Fruit');
      expect(jsonMap['low_stock_threshold'], 15.0);
      expect(jsonMap['farm_name'], 'Sunny Farm');
      expect(
        jsonMap['image_urls'],
        'http://10.0.2.2:3000/uploads/tomato.jpg',
      ); // Should join back
      expect(jsonMap['low_stock_since_date'], 1678887000);
    });

    test('toJson should handle null category gracefully', () {
      final product = Product(
        id: 4,
        name: 'Plain Yogurt',
        price: 4.0,
        stock: 30.0,
        ownerId: 104,
        category: null,
        lowStockThreshold: 8.0,
        farmName: 'Yogurt Co.',
        imageUrls: [],
        lowStockSinceDate: null,
      );

      final jsonMap = product.toJson();

      expect(jsonMap['category'], isNull);
    });
  });
}
