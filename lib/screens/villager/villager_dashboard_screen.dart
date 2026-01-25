// lib/screens/villager/villager_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges; // Import badges package
import 'package:lung_chaing_farm/providers/auth_provider.dart';
import 'package:lung_chaing_farm/providers/low_stock_provider.dart'; // Import LowStockProvider
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:lung_chaing_farm/widgets/product_card.dart';
import 'package:lung_chaing_farm/screens/add_product_screen.dart';
import 'package:lung_chaing_farm/screens/villager/low_stock_products_screen.dart'; // Import LowStockProductsScreen
import 'package:lung_chaing_farm/services/notification_service.dart'; // Import NotificationService
import 'package:lung_chaing_farm/models/product.dart'; // Import Product model
import 'package:lung_chaing_farm/widgets/refresh_button.dart'; // Import RefreshButton

class VillagerDashboardScreen extends StatefulWidget {
  const VillagerDashboardScreen({super.key});

  @override
  State<VillagerDashboardScreen> createState() =>
      _VillagerDashboardScreenState();
}

class _VillagerDashboardScreenState extends State<VillagerDashboardScreen> {
  late Future<List<Map<String, dynamic>>> _villagerProductsFuture;
  // List<Map<String, dynamic>> _lowStockProducts = []; // Moved to LowStockProvider

  @override
  void initState() {
    super.initState();
    _villagerProductsFuture = Future.value(
      <Map<String, dynamic>>[],
    ); // Initialize here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVillagerProducts();
    });
  }

  void _fetchVillagerProducts() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lowStockProvider = Provider.of<LowStockProvider>(
      context,
      listen: false,
    ); // Get LowStockProvider

    if (authProvider.isAuthenticated && authProvider.user?.role == 'VILLAGER') {
      setState(() {
        _villagerProductsFuture = (() async {
          try {
            final allProducts = await ApiService.instance.getProducts();
            final ownedProducts = allProducts
                .where(
                  (product) => product['owner_id'] == authProvider.user!.id,
                )
                .toList();

            final String? userToken = authProvider.token;
            if (userToken != null) {
              lowStockProvider.fetchLowStockProducts();
            } else {
              NotificationService.showSnackBar(
                'Authentication token is missing. Please log in again.',
                isError: true,
              );
              lowStockProvider.clearLowStockData();
              return <Map<String, dynamic>>[];
            }
            return ownedProducts;
          } catch (e) {
            NotificationService.showSnackBar(
              'Failed to load products: ${e.toString()}',
              isError: true,
            );
            lowStockProvider.clearLowStockData();
            return <Map<String, dynamic>>[];
          }
        })();
      });
    } else {
      // If not authenticated or not a villager, clear products
      setState(() {
        _villagerProductsFuture = Future.value([]);
        lowStockProvider.clearLowStockData(); // Clear low stock data as well
      });
    }
  }

  void _navigateToAddNewProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );
    if (result == true) {
      _fetchVillagerProducts(); // Refresh products if a new one was added
    }
  }

  void _editProduct(int productId) {
    // TODO: Implement navigation to an EditProductScreen
    NotificationService.showSnackBar(
      'Edit product functionality not yet implemented.',
    ); // Use NotificationService
  }

  void _sellProduct(Product product) async {
    final int productId = product.id;
    final double currentStock = product.stock;

    if (currentStock > 0) {
      try {
        // Fetch full product details to get existing image URLs and category
        final productDetails = await ApiService.instance.getProductById(
          productId,
        );
        final List<String> existingImageUrls =
            (productDetails['image_urls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final String? category = productDetails['category'];

        final response = await ApiService.instance.updateProductStock(
          productId,
          currentStock - 1, // Still selling 1kg
          category: category,
          existingImageUrls: existingImageUrls,
        );
        _fetchVillagerProducts(); // Refresh products after selling

        if (response['lowStockAlert'] == true) {
          NotificationService.showSnackBar(
            'Product "${response['productName']}" is low in stock! Current: ${response['currentStock']}kg left.',
            isError: true,
          );
        }
      } catch (e) {
        NotificationService.showSnackBar(
          'Failed to sell product: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _deleteProduct(int productId) async {
    try {
      await ApiService.instance.deleteProduct(productId);
      _fetchVillagerProducts(); // Refresh products after deleting
    } catch (e) {
      NotificationService.showSnackBar(
        'Failed to delete product: ${e.toString()}',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String? currentUserRole = authProvider.user?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Farm Products'),
        backgroundColor: Colors.lightGreen,
        actions: [
          // Low Stock Indicator
          Consumer<LowStockProvider>(
            builder: (context, lowStockProvider, child) {
              // The low stock products are fetched via _fetchVillagerProducts in initState.
              // This Consumer will simply listen and rebuild when lowStockProvider notifies.
              return badges.Badge(
                showBadge: lowStockProvider.lowStockCount > 0,
                badgeContent: Text(
                  lowStockProvider.lowStockCount.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                position: badges.BadgePosition.topEnd(top: 0, end: 3),
                badgeAnimation: const badges.BadgeAnimation.slide(
                  animationDuration: Duration(milliseconds: 200),
                ),
                child: IconButton(
                  icon: Image.asset(
                    'assets/icons/shop-cart.png',
                    width: 24,
                    height: 24,
                    // color: Colors.white,
                  ), // Use Image.asset for the custom icon
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LowStockProductsScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          RefreshButton(onPressed: _fetchVillagerProducts),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Provider.of<LowStockProvider>(
                context,
                listen: false,
              ).clearLowStockData(); // Clear low stock data on logout
            },
          ),
        ],
      ),
      body: Consumer<LowStockProvider>(
        builder: (context, lowStockProvider, child) {
          // The low stock products are now managed by LowStockProvider
          // No need for a separate FutureBuilder for low stock section
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _villagerProductsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No products added yet.'));
              } else {
                return Column(
                  children: [
                    if (lowStockProvider.lowStockProducts.isNotEmpty)
                      Card(
                        margin: const EdgeInsets.all(8.0),
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Low Stock Alerts:',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const Divider(),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount:
                                    lowStockProvider.lowStockProducts.length,
                                itemBuilder: (context, index) {
                                  final product =
                                      lowStockProvider.lowStockProducts[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Text(
                                      '${product.name}: ${product.stock}kg (Threshold: ${product.lowStockThreshold}kg)',
                                      style: const TextStyle(fontSize: 16.0),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final productData = snapshot.data![index];
                          final product = Product.fromJson(productData);
                          return ProductCard(
                            product: product,
                            onSell: _sellProduct,
                            onDelete: _deleteProduct,
                            userRole: currentUserRole,
                            onEdit: () => _editProduct(product.id),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddNewProduct,
        backgroundColor: Colors.lightGreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}
