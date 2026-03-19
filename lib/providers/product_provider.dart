import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/product_repository.dart';

/// Провайдер состояния — управляет списком продуктов
class ProductProvider extends ChangeNotifier {
  final _repo = ProductRepository();

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';
  ProductCategory? _filterCategory;

  List<ProductModel> get products => _filtered;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ProductCategory? get filterCategory => _filterCategory;

  /// Отфильтрованный список
  List<ProductModel> get _filtered {
    var list = [..._products];
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
              (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_filterCategory != null) {
      list = list.where((p) => p.category == _filterCategory).toList();
    }
    return list;
  }

  /// Продукты по статусу
  List<ProductModel> get expiredProducts =>
      _products.where((p) => p.freshnessStatus == 2).toList();
  List<ProductModel> get warningProducts =>
      _products.where((p) => p.freshnessStatus == 1).toList();
  List<ProductModel> get freshProducts =>
      _products.where((p) => p.freshnessStatus == 0).toList();

  /// Загрузка из базы
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await _repo.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    final saved = await _repo.add(product);
    _products.add(saved);
    notifyListeners();
  }

  Future<void> updateProduct(ProductModel product) async {
    await _repo.update(product);
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(ProductModel product) async {
    await _repo.delete(product);
    _products.removeWhere((p) => p.id == product.id);
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(ProductCategory? category) {
    _filterCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterCategory = null;
    notifyListeners();
  }
}
