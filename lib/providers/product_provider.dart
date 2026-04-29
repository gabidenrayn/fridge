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
  bool _isLocalOperation = false; // Флаг для локальных операций

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

    if (_authProvider?.accountModel != null) {
      _loadMapping();
      _startRealtimeSync();
    } else {
      _products.clear();
      _cloudIdToLocalId.clear();
      _saveMapping();
      notifyListeners();
    }
  }

  /// Запуск real-time синхронизации с Firestore
  void _startRealtimeSync() {
    final accountId = _authProvider!.accountModel!.id;
    debugPrint('Starting realtime sync for account: $accountId');

    _productsSubscription = _firestore
        .collection('accounts')
        .doc(accountId)
        .collection('products')
        .snapshots()
        .listen((snapshot) async {
      debugPrint('Cloud snapshot received: ${snapshot.docs.length} products');
      _handleCloudChanges(snapshot);
    }, onError: (error) {
      debugPrint('Realtime sync error: $error');
    });
  }

  /// Сохранить маппинг в SharedPreferences
  Future<void> _saveMapping() async {
    final prefs = await SharedPreferences.getInstance();
    final accountId = _authProvider?.accountModel?.id ?? 'default';
    final jsonString = jsonEncode(_cloudIdToLocalId);
    await prefs.setString('cloud_id_mapping_$accountId', jsonString);
    debugPrint('Saved mapping: $_cloudIdToLocalId');
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
        debugPrint('Loaded mapping: $_cloudIdToLocalId');
      } catch (e) {
        debugPrint('Error loading mapping: $e');
      }
    }
  }

  /// Обработка изменений из облака
  Future<void> _handleCloudChanges(QuerySnapshot snapshot) async {
    // Если идет локальная операция, пропускаем обработку
    if (_isLocalOperation) {
      debugPrint('Skipping cloud changes during local operation');
      return;
    }

    debugPrint('Handling cloud changes...');
    final cloudProducts =
        snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

    // Получить текущие локальные продукты
    final localProducts = await _repo.getAll();
    final cloudDocIds = snapshot.docs.map((doc) => doc.id).toSet();

    debugPrint('Cloud products: ${cloudProducts.length}, Local products: ${localProducts.length}');

    // Добавить новые продукты из облака
    for (int i = 0; i < cloudProducts.length; i++) {
      final product = cloudProducts[i];
      final cloudDocId = snapshot.docs[i].id;

      if (!_cloudIdToLocalId.containsKey(cloudDocId)) {
        // Проверить, нет ли уже продукта с такими же данными (для предотвращения дублирования)
        final isDuplicate = _products.any((p) =>
            p.name == product.name &&
            p.expiryDate.isAtSameMomentAs(product.expiryDate) &&
            p.purchaseDate.isAtSameMomentAs(product.purchaseDate));

        if (isDuplicate) {
          debugPrint('Skipping duplicate product from cloud: ${product.name}');
          // Найти дубликат и привязать к cloud ID
          final duplicate = _products.firstWhere((p) =>
              p.name == product.name &&
              p.expiryDate.isAtSameMomentAs(product.expiryDate) &&
              p.purchaseDate.isAtSameMomentAs(product.purchaseDate));
          if (duplicate.id != null) {
            _cloudIdToLocalId[cloudDocId] = duplicate.id!;
            await _saveMapping();
          }
          continue;
        }

        // Создать локальный ID для продукта из облака
        final localId = _generateLocalId();
        _cloudIdToLocalId[cloudDocId] = localId;
        final localProduct = product.copyWith(id: localId);
        await _repo.add(localProduct);
        _products.add(localProduct);
        debugPrint('Added new product from cloud: ${product.name} (cloudId: $cloudDocId, localId: $localId)');
      } else {
        // Обновить существующий продукт
        final localId = _cloudIdToLocalId[cloudDocId]!;
        final localProduct = localProducts.firstWhere(
          (p) => p.id == localId,
          orElse: () => product.copyWith(id: localId),
        );
        final updatedProduct = localProduct.copyWith(
          name: product.name,
          barcode: product.barcode,
          expiryDate: product.expiryDate,
          purchaseDate: product.purchaseDate,
          quantity: product.quantity,
          unit: product.unit,
          category: product.category,
          note: product.note,
          imagePath: product.imagePath,
          isFavorite: product.isFavorite,
          brand: product.brand,
        );
        await _repo.update(updatedProduct);
        final idx = _products.indexWhere((p) => p.id == localId);
        if (idx != -1) {
          _products[idx] = updatedProduct;
        }
        debugPrint('Updated product from cloud: ${product.name}');
      }
    }

    // Удалить продукты, которых нет в облаке
    final cloudIdsSet = _cloudIdToLocalId.keys.toSet();
    for (final entry in _cloudIdToLocalId.entries) {
      if (!cloudDocIds.contains(entry.key)) {
        final localId = entry.value;
        final localProduct = localProducts.firstWhere(
          (p) => p.id == localId,
          orElse: () => _products.firstWhere(
            (p) => p.id == localId,
            orElse: () => _products.first,
          ),
        );
        await _repo.delete(localProduct);
        _products.removeWhere((p) => p.id == localId);
        _cloudIdToLocalId.remove(entry.key);
        debugPrint('Deleted product from local: cloudId ${entry.key}, localId $localId');
      }
    }

    await _saveMapping();
    notifyListeners();
    debugPrint('Cloud changes handled, total products: ${_products.length}');
  }

  /// Генерация локального ID для продукта из облака
  int _generateLocalId() {
    if (_products.isEmpty) return 1;
    return _products.map((p) => p.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
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
        final localProduct = product.copyWith(id: _generateLocalId());
        await _repo.add(localProduct);
        _products.add(localProduct);
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
    _isLocalOperation = true;
    final saved = await _repo.add(product);
    _products.add(saved);
    notifyListeners();

    // Синхронизировать в облако
    if (_authProvider?.accountModel != null) {
      final docRef = await _firestore
          .collection('accounts')
          .doc(_authProvider!.accountModel!.id)
          .collection('products')
          .add(product.toFirestore());

      final cloudDocId = docRef.id;
      _cloudIdToLocalId[cloudDocId] = saved.id!;
      await _saveMapping();
      debugPrint('Added product to cloud: ${saved.name} (cloudId: $cloudDocId, localId: ${saved.id})');
    }

    // Ждем немного перед снятием флага, чтобы real-time слушатель успел сработать
    await Future.delayed(const Duration(milliseconds: 500));
    _isLocalOperation = false;
  }

  Future<void> updateProduct(ProductModel product) async {
    _isLocalOperation = true;
    await _repo.update(product);
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = product;
      notifyListeners();
    }

    // Синхронизировать в облако
    if (_authProvider?.accountModel != null && product.id != null) {
      final entry = _cloudIdToLocalId.entries
          .cast<MapEntry<String, int>?>()
          .firstWhere((entry) => entry?.value == product.id, orElse: () => null);
      if (entry != null) {
        await _syncProductToCloudById(product, _authProvider!.accountModel!.id, entry.key);
        debugPrint('Updated product in cloud: ${product.name}');
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _isLocalOperation = false;
  }

  Future<void> deleteProduct(ProductModel product) async {
    _isLocalOperation = true;
    await _repo.delete(product);
    _products.removeWhere((p) => p.id == product.id);
    notifyListeners();

    // Удалить из облака
    if (_authProvider?.accountModel != null && product.id != null) {
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
        debugPrint('Deleted product from cloud: ${product.name} (cloudId: ${entry.key})');
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _isLocalOperation = false;
  }

  Future<String?> _syncProductToCloud(
    ProductModel product,
    String accountId,
  ) async {
    final docRef = await _firestore
        .collection('accounts')
        .doc(accountId)
        .collection('products')
        .add(product.toFirestore());
    return docRef.id;
  }

  Future<void> _syncProductToCloudById(
    ProductModel product,
    String accountId,
    String cloudDocId,
  ) async {
    await _firestore
        .collection('accounts')
        .doc(accountId)
        .collection('products')
        .doc(cloudDocId)
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
