import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lung_chaing_farm/providers/auth_provider.dart';
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:lung_chaing_farm/widgets/product_card.dart';
import 'package:lung_chaing_farm/screens/auth/login_screen.dart';
import 'package:lung_chaing_farm/screens/auth/register_screen.dart';
import 'package:lung_chaing_farm/services/notification_service.dart'; // Import NotificationService
import 'package:lung_chaing_farm/models/product.dart'; // Import Product model
import 'package:lung_chaing_farm/widgets/refresh_button.dart'; // Import RefreshButton
import 'package:lung_chaing_farm/widgets/quick_buy_modal.dart'; // Import QuickBuyModal

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() async {
    setState(() {
      _productsFuture = (() async {
        try {
          return await ApiService.instance.getProducts();
        } catch (e) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService.showSnackBar(
              'Failed to load products: ${e.toString()}',
              isError: true,
            );
          });
          return <Map<String, dynamic>>[];
        }
      })();
    });
  }

  void _sellProduct(Product product) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return QuickBuyModal(
          product: product,
          onConfirmPurchase: (productId, quantity) async {
            if (quantity > 0) {
              try {
                await ApiService.instance.updateProductStock(
                  productId,
                  product.stock - quantity, // Subtract the purchased quantity
                );
                _fetchProducts(); // Refresh products after selling
                NotificationService.showSnackBar(
                  'Purchased $quantity kg of ${product.name}!',
                );
              } catch (e) {
                NotificationService.showSnackBar(
                  'Failed to purchase product: ${e.toString()}',
                  isError: true,
                );
              }
            }
          },
        );
      },
    );
  }

  void _deleteProduct(int productId) async {
    try {
      await ApiService.instance.deleteProduct(productId);
      _fetchProducts(); // Refresh products after deleting
    } catch (e) {
      NotificationService.showSnackBar(
        'Failed to delete product: ${e.toString()}',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lung Chaing Farm Marketplace'),
        backgroundColor: Colors.lightGreen,
        actions: [
          RefreshButton(onPressed: _fetchProducts),
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              if (auth.isAuthenticated) {
                return IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                  },
                );
              } else {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person_add),
                      tooltip: 'Register',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.login),
                      tooltip: 'Login',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No products available. Add some!'),
            );
          } else {
            final auth = Provider.of<AuthProvider>(context);
            final String? currentUserRole = auth.user?.role;

            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two columns
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.75, // Adjust as needed
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
                );
              },
            );
          }
        },
      ),
    );
  }
}
