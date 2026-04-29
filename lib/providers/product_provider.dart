import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  StreamSubscription<QuerySnapshot>? _productsSubscription;
  final Map<String, int> _cloudIdToLocalId = {};

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
    // Отписаться от предыдущего слушателя
    _productsSubscription?.cancel();
    _productsSubscription = null;
    _cloudIdToLocalId.clear();

    if (_authProvider?.accountModel != null) {
      _loadMapping();
      loadProducts(); // Одноразовая загрузка и синхронизация
    } else {
      _products.clear();
      _saveMapping();
      notifyListeners();
    }
  }

  /// Сохранить маппинг в SharedPreferences
  Future<void> _saveMapping() async {
    final prefs = await SharedPreferences.getInstance();
    final accountId = _authProvider?.accountModel?.id ?? 'default';
    final jsonString = jsonEncode(_cloudIdToLocalId);
    await prefs.setString('cloud_id_mapping_$accountId', jsonString);
  }

  /// Загрузить маппинг из SharedPreferences
  Future<void> _loadMapping() async {
    final prefs = await SharedPreferences.getInstance();
    final accountId = _authProvider?.accountModel?.id ?? 'default';
    final jsonString = prefs.getString('cloud_id_mapping_$accountId');
    if (jsonString != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        _cloudIdToLocalId.clear();
        decoded.forEach((key, value) {
          _cloudIdToLocalId[key] = value as int;
        });
      } catch (e) {
        debugPrint('Error loading mapping: $e');
      }
    }
  }

  /// Загрузка из базы
  Future<void> loadProducts() async {
    if (_authProvider?.accountModel == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Загрузка из локальной БД
      _products = await _repo.getAll();
    } catch (e) {
      debugPrint('Error loading products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    // Сначала добавляем в локальную БД
    final saved = await _repo.add(product);
    _products.add(saved);
    notifyListeners();

    // Синхронизировать в облако
    if (_authProvider?.accountModel != null) {
      try {
        final docRef = await _firestore
            .collection('accounts')
            .doc(_authProvider!.accountModel!.id)
            .collection('products')
            .add(product.toFirestore());

        if (saved.id != null) {
          _cloudIdToLocalId[docRef.id] = saved.id!;
          await _saveMapping();
        }
        debugPrint('Added product to cloud: ${saved.name}');
      } catch (e) {
        debugPrint('Error adding product to cloud: $e');
      }
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    // Сначала обновляем в локальной БД
    await _repo.update(product);
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = product;
      notifyListeners();
    }

    // Синхронизировать в облако
    if (_authProvider?.accountModel != null && product.id != null) {
      try {
        final entry = _cloudIdToLocalId.entries
            .cast<MapEntry<String, int>?>()
            .firstWhere((entry) => entry?.value == product.id, orElse: () => null);
        if (entry != null) {
          await _firestore
              .collection('accounts')
              .doc(_authProvider!.accountModel!.id)
              .collection('products')
              .doc(entry.key)
              .set(product.toFirestore());
          debugPrint('Updated product in cloud: ${product.name}');
        }
      } catch (e) {
        debugPrint('Error updating product in cloud: $e');
      }
    }
  }

  Future<void> deleteProduct(ProductModel product) async {
    // Сначала удаляем из локальной БД
    await _repo.delete(product);
    _products.removeWhere((p) => p.id == product.id);
    notifyListeners();

    // Удалить из облака
    if (_authProvider?.accountModel != null && product.id != null) {
      try {
        final entry = _cloudIdToLocalId.entries
            .cast<MapEntry<String, int>?>()
            .firstWhere((entry) => entry?.value == product.id, orElse: () => null);
        if (entry != null) {
          await _firestore
              .collection('accounts')
              .doc(_authProvider!.accountModel!.id)
              .collection('products')
              .doc(entry.key)
              .delete();
          _cloudIdToLocalId.remove(entry.key);
          await _saveMapping();
          debugPrint('Deleted product from cloud: ${product.name}');
        }
      } catch (e) {
        debugPrint('Error deleting product from cloud: $e');
      }
    }
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
