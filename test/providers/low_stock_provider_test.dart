import 'package:flutter_test/flutter_test.dart';
import 'package:lung_chaing_farm/models/product.dart';
import 'package:lung_chaing_farm/providers/low_stock_provider.dart';
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'low_stock_provider_test.mocks.dart'; // Generated mock file

// Generate a mock class for ApiService
@GenerateMocks([ApiService])
void main() {
  group('LowStockProvider', () {
    late LowStockProvider lowStockProvider;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      // Directly assign the mock to the static instance for testing
      ApiService.instance = mockApiService; // Use the public setter
      lowStockProvider = LowStockProvider(mockApiService);

      // Default stub for getLowStockProducts to prevent MissingStubError
      // for tests that call fetchLowStockProducts implicitly.
      when(mockApiService.getLowStockProducts()).thenAnswer((_) async => []);
    });

    tearDown(() {
      lowStockProvider.dispose();
      // Reset the static instance to prevent interference with other tests
      ApiService.resetForTesting();
    });

    test('initial values are correct', () {
      expect(lowStockProvider.lowStockProducts, isEmpty);
      expect(lowStockProvider.lowStockCount, 0);
      expect(lowStockProvider.isLoading, false);
    });

    test('fetchLowStockProducts updates state correctly on success', () async {
      final product1 = Product(
        id: 1,
        name: 'Apple',
        price: 10.0,
        stock: 5.0,
        ownerId: 100,
        category: 'Sweet',
        lowStockThreshold: 10.0,
        farmName: 'Test Farm',
        lowStockSinceDate: 1678886400, // This is the expected value
        imageUrls: [],
      );
      final product2 = Product(
        id: 2,
        name: 'Orange',
        price: 12.0,
        stock: 8.0,
        ownerId: 100,
        category: 'Sour',
        lowStockThreshold: 15.0,
        farmName: 'Test Farm',
        lowStockSinceDate: 1678886500,
        imageUrls: [],
      );

      final mockProductsJson = [product1.toJson(), product2.toJson()];

      when(
        mockApiService.getLowStockProducts(),
      ).thenAnswer((_) async => mockProductsJson);

      final future = lowStockProvider.fetchLowStockProducts();
      expect(lowStockProvider.isLoading, true); // Loading state should be true

      await future;

      expect(lowStockProvider.isLoading, false);
      expect(lowStockProvider.lowStockProducts.length, 2);
      expect(lowStockProvider.lowStockCount, 2);
      expect(lowStockProvider.lowStockProducts[0].name, 'Apple');
      expect(
        lowStockProvider.lowStockProducts[0].lowStockSinceDate,
        1678886400,
      );
      expect(
        lowStockProvider.lowStockProducts[1].name,
        'Orange',
      ); // Verify second product too
      expect(
        lowStockProvider.lowStockProducts[1].lowStockSinceDate,
        1678886500,
      );
    });

    test('fetchLowStockProducts handles error correctly', () async {
      when(
        mockApiService.getLowStockProducts(),
      ).thenThrow(Exception('Failed to fetch'));

      await lowStockProvider.fetchLowStockProducts();

      expect(lowStockProvider.isLoading, false);
      expect(lowStockProvider.lowStockProducts, isEmpty);
      expect(lowStockProvider.lowStockCount, 0);
      expect(lowStockProvider.errorMessage, isNotNull);
      expect(lowStockProvider.errorMessage, contains('Failed to fetch'));
    });

    test('clearLowStockData clears all products', () async {
      final product1 = Product(
        id: 6,
        name: 'Kiwi',
        price: 10.0,
        stock: 5.0,
        ownerId: 100,
        lowStockThreshold: 10.0,
        imageUrls: [],
        lowStockSinceDate: 1678886400,
      );
      final mockProductsJson = [product1.toJson()];

      when(mockApiService.getLowStockProducts())
          .thenAnswer((_) async => mockProductsJson);

      await lowStockProvider.fetchLowStockProducts();
      expect(lowStockProvider.lowStockCount, 1);

      lowStockProvider.clearLowStockData();

      expect(lowStockProvider.lowStockCount, 0);
      expect(lowStockProvider.lowStockProducts, isEmpty);
    });
  });
}
