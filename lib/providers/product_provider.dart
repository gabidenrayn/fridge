import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/product_repository.dart';
import 'auth_provider.dart';

/// Провайдер состояния — управляет списком продуктов
class ProductProvider extends ChangeNotifier {
  final _repo = ProductRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthProvider? _authProvider;
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
            (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    if (_filterCategory != null) {
      list = list.where((p) => p.category == _filterCategory).toList();
    }
    return list;
  }

  /// Продукты по месту хранения
  List<ProductModel> get fridgeProducts =>
      _filtered.where((p) => p.category != ProductCategory.frozen).toList();
  List<ProductModel> get freezerProducts =>
      _filtered.where((p) => p.category == ProductCategory.frozen).toList();

  /// Продукты по статусу
  List<ProductModel> get expiredProducts =>
      _products.where((p) => p.freshnessStatus == 2).toList();
  List<ProductModel> get warningProducts =>
      _products.where((p) => p.freshnessStatus == 1).toList();
  List<ProductModel> get freshProducts =>
      _products.where((p) => p.freshnessStatus == 0).toList();

  /// Установить провайдер аутентификации
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    _authProvider!.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  void _onAuthChanged() {
    if (_authProvider?.accountModel != null) {
      loadProducts();
    } else {
      _products.clear();
      notifyListeners();
    }
  }

  /// Загрузка из базы и синхронизация с облаком
  Future<void> loadProducts() async {
    if (_authProvider?.accountModel == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Загрузка из локальной БД
      _products = await _repo.getAll();

      // Синхронизация с Firestore
      final accountId = _authProvider!.accountModel!.id;
      final snapshot = await _firestore
          .collection('accounts')
          .doc(accountId)
          .collection('products')
          .get();

      final cloudProducts =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      // Слияние данных (облако имеет приоритет)
      final localIds = _products.map((p) => p.id).toSet();
      final newProducts =
          cloudProducts.where((p) => !localIds.contains(p.id)).toList();

      for (final product in newProducts) {
        await _repo.add(product);
        _products.add(product);
      }

      // Синхронизировать локальные изменения в облако
      for (final product in _products) {
        await _syncProductToCloud(product, accountId);
      }
    } catch (e) {
      // Если облако недоступно, используем локальные данные
      debugPrint('Error syncing products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    final saved = await _repo.add(product);
    _products.add(saved);
    notifyListeners();

    // Синхронизировать в облако
    if (_authProvider?.accountModel != null) {
      await _syncProductToCloud(saved, _authProvider!.accountModel!.id);
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    await _repo.update(product);
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = product;
      notifyListeners();
    }

    // Синхронизировать в облако
    if (_authProvider?.accountModel != null) {
      await _syncProductToCloud(product, _authProvider!.accountModel!.id);
    }
  }

  Future<void> deleteProduct(ProductModel product) async {
    await _repo.delete(product);
    _products.removeWhere((p) => p.id == product.id);
    notifyListeners();

    // Удалить из облака
    if (_authProvider?.accountModel != null) {
      await _firestore
          .collection('accounts')
          .doc(_authProvider!.accountModel!.id)
          .collection('products')
          .doc(product.id.toString().toString())
          .delete();
    }
  }

  Future<void> _syncProductToCloud(
    ProductModel product,
    String accountId,
  ) async {
    await _firestore
        .collection('accounts')
        .doc(accountId)
        .collection('products')
        .doc(product.id.toString())
        .set(product.toFirestore());
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
