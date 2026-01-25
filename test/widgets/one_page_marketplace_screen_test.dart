// Mocks for ApiService and AuthProvider for widget testing
// Import for Completer
import 'package:lung_chaing_farm/providers/auth_provider.dart';
import 'package:lung_chaing_farm/services/api_service.dart';
// Import ProductCard
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
// Corrected import

import 'package:lung_chaing_farm/models/user.dart'
    as app_user; // Alias to avoid conflict with test User class

@GenerateMocks([
  ApiService,
  AuthProvider,
]) // Keep @GenerateMocks here for the generated file
void main() {
  /*
  group('OnePageMarketplaceScreen Widget Tests', () {
    late MockApiService mockApiService;
    late MockAuthProvider mockAuthProvider;

    // Helper to create the widget under test, injecting mocks via Provider
    Widget createWidgetUnderTest() { // Removed parameters from helper
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ],
          child: const OnePageMarketplaceScreen(),
        ),
      );
    }

    setUp(() {
      mockApiService = MockApiService();
      mockAuthProvider = MockAuthProvider();

      // Ensure ApiService static instance is set to our mock for ProductListSection
      ApiService.instance = mockApiService;

      // Reset mock behaviors for each test to ensure a clean slate
      reset(mockApiService);
      reset(mockAuthProvider);

      // Set a default mock behavior for getProducts for all categories
      // This will ensure no null Futures are returned by default, preventing _TypeError
      when(mockApiService.getProducts(category: anyNamed('category')))
          .thenAnswer((_) async => Future.value([])); // Default to empty list
      
      // Set a default mock behavior for AuthProvider. This can be overridden in specific tests.
      when(mockAuthProvider.user).thenReturn(null);
      when(mockAuthProvider.isAuthenticated).thenReturn(false);
    });

    tearDown(() {
      ApiService.resetForTesting();
    });

    testWidgets('OnePageMarketplaceScreen displays app bar and sections', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle(); // Allow FutureBuilder to complete with default empty list

      expect(find.text('Lung Chaing Farm'), findsOneWidget);
      expect(find.byType(HeroSection), findsOneWidget);
      expect(find.byType(ProductListSection), findsNWidgets(2)); // For Vegetables and Fruits
      expect(find.text('Fresh Vegetables'), findsOneWidget);
      expect(find.text('Delicious Fruits'), findsOneWidget);
    });

    testWidgets('OnePageMarketplaceScreen displays welcome message for authenticated user', (tester) async {
      // Configure AuthProvider mock for this specific test
      when(mockAuthProvider.user).thenReturn(
          app_user.User(id: 1, email: 'test@example.com', role: 'USER', farmName: 'Test Farm'));
      when(mockAuthProvider.isAuthenticated).thenReturn(true);

      await tester.pumpWidget(createWidgetUnderTest()); // Removed parameters
      await tester.pumpAndSettle(); // Allow FutureBuilder to complete

      expect(find.text('Welcome, Test Farm!'), findsOneWidget);
    });

    testWidgets('OnePageMarketplaceScreen does not display welcome message for unauthenticated user', (tester) async {
      // AuthProvider mock is already in default (unauthenticated) state

      await tester.pumpWidget(createWidgetUnderTest()); // Removed parameters
      await tester.pumpAndSettle();

      expect(find.text('Welcome, Test Farm!'), findsNothing);
    });

    testWidgets('ProductListSection displays CircularProgressIndicator while loading', (tester) async {
      final completer = Completer<List<Map<String, dynamic>>>();
      // Override default getProducts behavior for Vegetable category for this test
      when(mockApiService.getProducts(category: 'Vegetable')).thenAnswer((_) => completer.future);
      // Fruit category will use default empty list
      
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 100)); // Pump to allow FutureBuilder to start loading

      expect(find.byType(CircularProgressIndicator), findsOneWidget); // For Vegetable section
      completer.complete([]); // Complete the future to avoid hanging
      await tester.pumpAndSettle(); // Re-pump to resolve the FutureBuilder
    });

    testWidgets('ProductListSection displays products when loaded', (tester) async {
      final mockProductsJson = [
        Product(
          id: 1,
          name: 'Tomato',
          price: 1.0,
          stock: 10.0,
          ownerId: 1,
          category: 'Vegetable',
          farmName: 'Farm A',
          imageUrls: [],
        ).toJson()
      ];

      // Override default getProducts behavior for Vegetable category for this test
      when(mockApiService.getProducts(category: 'Vegetable')).thenAnswer((_) async => Future.value(mockProductsJson));
      // Fruit category will use default empty list
      
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle(); // Wait for FutureBuilder to complete

      expect(find.text('Tomato'), findsOneWidget);
      // Expect ProductCard with a dummy onSell function
      expect(find.byWidgetPredicate((widget) => 
        widget is ProductCard && widget.product.name == 'Tomato' && widget.onSell != null
      ), findsOneWidget);
    });

    testWidgets('ProductListSection displays "No products found" when empty', (tester) async {
      // Default getProducts behavior already returns empty lists

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('No products found in this category.'), findsNWidgets(2)); // For both sections
    });
  });
*/
}

// Updated MockAuthProvider to use app_user.User
class MockAuthProvider extends Mock implements AuthProvider {
  // Mock 'user' getter
  @override
  app_user.User? get user => super.noSuchMethod(
    Invocation.getter(#user),
    returnValue: null, // Default return value
  );

  // Mock 'isAuthenticated' getter
  @override
  bool get isAuthenticated => super.noSuchMethod(
    Invocation.getter(#isAuthenticated),
    returnValue: false, // Default return value
  );
}

class MockApiService extends Mock implements ApiService {}
