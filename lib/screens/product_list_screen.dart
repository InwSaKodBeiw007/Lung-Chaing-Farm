import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lung_chaing_farm/providers/auth_provider.dart';
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:lung_chaing_farm/widgets/product_card.dart';
import 'package:lung_chaing_farm/screens/add_product_screen.dart';
import 'package:lung_chaing_farm/screens/auth/login_screen.dart';
import 'package:lung_chaing_farm/screens/auth/register_screen.dart';
import 'package:lung_chaing_farm/services/audio_service.dart';
import 'package:lung_chaing_farm/services/notification_service.dart'; // Import NotificationService

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

  void _fetchProducts() {
    setState(() {
      _productsFuture = ApiService.instance.getProducts();
    });
  }

  void _navigateToAddNewProduct() async {
    AudioService.playClickSound(); // Play sound on add button click
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );
    if (result == true) {
      _fetchProducts(); // Refresh products if a new one was added
    }
  }

  void _sellProduct(int productId, double currentStock) async {
    if (currentStock > 0) {
      try {
        await ApiService.instance.updateProductStock(productId, currentStock - 1);
        _fetchProducts(); // Refresh products after selling
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              AudioService.playClickSound();
              _fetchProducts();
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              if (auth.isAuthenticated) {
                return IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () {
                    AudioService.playClickSound();
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
                        AudioService.playClickSound();
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
                        AudioService.playClickSound();
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
                final product = snapshot.data![index];
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddNewProduct,
        backgroundColor: Colors.lightGreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}
