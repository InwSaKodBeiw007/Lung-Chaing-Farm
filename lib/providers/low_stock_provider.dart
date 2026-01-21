import 'package:flutter/material.dart';
import 'package:lung_chaing_farm/models/product.dart';
import 'package:lung_chaing_farm/services/api_service.dart';
import 'package:flutter/foundation.dart';

class LowStockProvider with ChangeNotifier {
  List<Product> _lowStockProducts = [];
  int _lowStockCount = 0;
  bool _isLoading = false;

  List<Product> get lowStockProducts => _lowStockProducts;
  int get lowStockCount => _lowStockCount;
  bool get isLoading => _isLoading;

  Future<void> fetchLowStockProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> data = await ApiService.instance.getLowStockProducts();
      _lowStockProducts = data.map((item) {
        return Product.fromJson(item);
      }).toList();
      _lowStockCount = _lowStockProducts.length;
    } catch (e) {
      // Handle error, e.g., log it or show a notification
      debugPrint('Failed to fetch low stock products: $e');
      _lowStockProducts = [];
      _lowStockCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Optionally, a method to update a single product's low stock status
  // if its stock changes from outside (e.g., after a purchase)
  void updateProductLowStockStatus(Product updatedProduct) {
    int index = _lowStockProducts.indexWhere((p) => p.id == updatedProduct.id);
    if (updatedProduct.stock <= (updatedProduct.lowStockThreshold ?? 0)) {
      if (index == -1) {
        _lowStockProducts.add(updatedProduct);
      } else {
        _lowStockProducts[index] = updatedProduct;
      }
    } else {
      if (index != -1) {
        _lowStockProducts.removeAt(index);
      }
    }
    _lowStockCount = _lowStockProducts.length;
    notifyListeners();
  }

  // Clear low stock data when user logs out (handled by AuthProvider, but good to have)
  void clearLowStockData() {
    _lowStockProducts = [];
    _lowStockCount = 0;
    notifyListeners();
  }
}
