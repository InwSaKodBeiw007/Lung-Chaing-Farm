import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:lung_chaing_farm/services/api_exception.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'api_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('ApiService', () {
    late ApiService apiService;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      // Inject the mock client into the ApiService instance
      ApiService.resetForTesting(httpClient: mockClient);
      apiService = ApiService.instance;
    });

    tearDown(() {
      ApiService.resetForTesting();
    });

    group('getProducts', () {
      test(
        'should return a list of products when API call is successful',
        () async {
          final mockResponse = jsonEncode({
            'products': [
              {
                'id': 1,
                'name': 'Sweet Apple',
                'price': 1.0,
                'stock': 100.0,
                'owner_id': 1,
                'category': 'Sweet',
                'low_stock_threshold': 10.0,
                'farm_name': 'Farm A',
                'image_urls': 'uploads/sweet_apple.jpg',
                'low_stock_since_date': null,
              },
              {
                'id': 2,
                'name': 'Sour Grape',
                'price': 2.0,
                'stock': 50.0,
                'owner_id': 1,
                'category': 'Sour',
                'low_stock_threshold': 5.0,
                'farm_name': 'Farm A',
                'image_urls': 'uploads/sour_grape.jpg',
                'low_stock_since_date': null,
              },
            ],
          });

          when(
            mockClient.get(any, headers: anyNamed('headers')),
          ).thenAnswer((_) async => http.Response(mockResponse, 200));

          final products = await apiService.getProducts();

          expect(products.length, 2);
          expect(products[0]['name'], 'Sweet Apple');
          expect(products[0]['category'], 'Sweet');
          expect(products[1]['name'], 'Sour Grape');
          expect(products[1]['category'], 'Sour');
        },
      );

      test('should add category query parameter when provided', () async {
        final mockResponse = jsonEncode({
          'products': [
            {
              'id': 1,
              'name': 'Sweet Apple',
              'price': 1.0,
              'stock': 100.0,
              'owner_id': 1,
              'category': 'Sweet',
              'low_stock_threshold': 10.0,
              'farm_name': 'Farm A',
              'image_urls': 'uploads/sweet_apple.jpg',
              'low_stock_since_date': null,
            },
          ],
        });

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response(mockResponse, 200));

        await apiService.getProducts(category: 'Sweet');

        // Verify that the correct URL with category parameter was called
        verify(
          mockClient.get(
            Uri.parse('${ApiService.baseUrl}/products?category=Sweet'),
            headers: anyNamed('headers'),
          ),
        ).called(1);
      });

      test('should throw ApiException when API call fails', () async {
        final mockErrorResponse = jsonEncode({
          'error': 'Failed to fetch products',
        });
        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response(mockErrorResponse, 500));

        expect(() => apiService.getProducts(), throwsA(isA<ApiException>()));
      });
    });
  });
}
