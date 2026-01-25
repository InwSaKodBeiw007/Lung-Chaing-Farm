import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:lung_chaing_farm/services/api_exception.dart';
import 'package:lung_chaing_farm/models/user.dart'; // Import User model
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'api_service_test.mocks.dart';
import 'jwt_helper.dart'; // Import jwt_helper.dart

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

    group('login', () {
      test('should return a User object on successful login', () async {
        final testToken = generateTestJwt(
          1,
          'test@example.com',
          'USER',
          'Test Farm',
        );
        final mockResponse = jsonEncode({
          'accessToken': testToken,
          'user': {'farm_name': 'Test Farm'},
        });

        when(
          mockClient.post(
            Uri.parse('${ApiService.baseUrl}/auth/login'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(mockResponse, 200));

        final user = await apiService.login('test@example.com', 'password');

        expect(user, isA<User>());
        expect(user.id, 1);
        expect(user.email, 'test@example.com');
        expect(user.role, 'USER');
        expect(user.farmName, 'Test Farm');
        expect(user.token, testToken);
        verify(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).called(1);
      });

      test('should throw ApiException on failed login', () async {
        final mockErrorResponse = jsonEncode({'error': 'Invalid credentials'});
        when(
          mockClient.post(
            Uri.parse('${ApiService.baseUrl}/auth/login'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(mockErrorResponse, 401));

        expect(
          () => apiService.login('wrong@example.com', 'password'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Invalid credentials',
            ),
          ),
        );
      });
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

    group('register', () {
      test('should return a User object on successful registration', () async {
        final mockResponse = jsonEncode({
          'id': 444,
          'message': 'User registered successfully.',
        }); // Simulate backend not returning a token for register

        when(
          mockClient.post(
            Uri.parse('${ApiService.baseUrl}/auth/register'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(mockResponse, 201));

        final user = await apiService.register(
          email: 'new@example.com',
          password: 'password',
          role: 'VILLAGER',
          farmName: 'New Farm',
        );

        expect(user, isA<User>());
        expect(user.id, null); // Expect null as no token is returned
        expect(user.email, 'new@example.com'); // Email is passed directly
        expect(user.role, null); // Expect null as no token is returned
        expect(user.farmName, 'New Farm'); // FarmName is passed directly
        expect(user.token, null); // Expect null as no token is returned
        verify(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).called(1);
      });

      test('should throw ApiException on failed registration', () async {
        final mockErrorResponse = jsonEncode({'error': 'Email already exists'});
        when(
          mockClient.post(
            Uri.parse('${ApiService.baseUrl}/auth/register'),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(mockErrorResponse, 409));

        expect(
          () => apiService.register(
            email: 'existing@example.com',
            password: 'password',
            role: 'USER',
          ),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Email already exists',
            ),
          ),
        );
      });
    });

    group('loadUserFromToken', () {
      test('should return User object for a valid token', () async {
        final testToken = generateTestJwt(
          3,
          'valid@example.com',
          'USER',
          'Valid Farm',
        );
        final user = await apiService.loadUserFromToken(testToken);

        expect(user, isA<User>());
        expect(user!.id, 3);
        expect(user.email, 'valid@example.com');
        expect(user.role, 'USER');
        expect(user.farmName, 'Valid Farm');
        expect(user.token, testToken);
      });

      test('should return null for an expired token', () async {
        final expiredToken = generateExpiredTestJwt(
          4,
          'expired@example.com',
          'USER',
          'Expired Farm',
        );
        final user = await apiService.loadUserFromToken(expiredToken);

        expect(user, isNull);
      });

      test('should return null for a malformed token', () async {
        final malformedToken = 'malformed.jwt.token';
        final user = await apiService.loadUserFromToken(malformedToken);

        expect(user, isNull);
      });
    });
  });
}
