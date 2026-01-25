import 'package:flutter/foundation.dart';
import 'package:lung_chaing_farm/models/product.dart';
import 'package:lung_chaing_farm/services/api_service.dart';

class LowStockProvider with ChangeNotifier {
  List<Product> _lowStockProducts = [];
  int _lowStockCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get lowStockProducts => _lowStockProducts;
  int get lowStockCount => _lowStockCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final ApiService _apiService;

  LowStockProvider(this._apiService);

  Future<void> fetchLowStockProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.getLowStockProducts();
      _lowStockProducts = (data as List)
          .map((json) => Product.fromJson(json))
          .toList();
      _lowStockCount = _lowStockProducts.length;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching low stock products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearLowStockData() {
    _lowStockProducts = [];
    _lowStockCount = 0;
    _errorMessage = null;
    notifyListeners();
  }
}
