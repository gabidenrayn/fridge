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
  String? _deviceId; // Уникальный ID устройства для определения локальных изменений

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

  void _onAuthChanged() async {
    // Отписаться от предыдущего слушателя
    _productsSubscription?.cancel();
    _productsSubscription = null;
    _cloudIdToLocalId.clear();

    if (_authProvider?.accountModel != null) {
      await _generateDeviceId();
      _loadMapping();
      _startRealtimeSync();
      loadProducts(); // Загрузка из локальной БД
    } else {
      _products.clear();
      _saveMapping();
      notifyListeners();
    }
  }

  /// Генерация уникального ID устройства
  Future<void> _generateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id');
    if (_deviceId == null) {
      _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('device_id', _deviceId!);
    }
    debugPrint('Device ID: $_deviceId');
  }

  /// Запуск real-time синхронизации с Firestore
  void _startRealtimeSync() {
    final accountId = _authProvider!.accountModel!.id;
    debugPrint('Starting realtime sync for account: $accountId');
    debugPrint('Firestore path: accounts/$accountId/products');

    _productsSubscription = _firestore
        .collection('accounts')
        .doc(accountId)
        .collection('products')
        .snapshots()
        .listen((snapshot) async {
      debugPrint('Cloud snapshot received: ${snapshot.docs.length} products');
      debugPrint('Snapshot metadata: hasPendingWrites=${snapshot.metadata.hasPendingWrites}, isFromCache=${snapshot.metadata.isFromCache}');
      if (snapshot.docs.isEmpty) {
        debugPrint('Cloud collection is empty');
      }
      for (var doc in snapshot.docs) {
        debugPrint('Product doc: ${doc.id}, data: ${doc.data()}');
      }
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

  /// Обработка изменений из облака
  Future<void> _handleCloudChanges(QuerySnapshot snapshot) async {
    debugPrint('Handling cloud changes...');
    final cloudProducts =
        snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

    // Получить текущие локальные продукты
    final localProducts = await _repo.getAll();
    final cloudDocIds = snapshot.docs.map((doc) => doc.id).toSet();

    debugPrint('Cloud products: ${cloudProducts.length}, Local products: ${localProducts.length}');

    // Синхронизировать: облако -> локальная БД
    for (int i = 0; i < cloudProducts.length; i++) {
      final product = cloudProducts[i];
      final cloudDocId = snapshot.docs[i].id;
      final data = snapshot.docs[i].data() as Map<String, dynamic>;

      // Пропускаем изменения с текущего deviceId (локальные изменения)
      if (data['deviceId'] == _deviceId) {
        debugPrint('Skipping local change for product: ${product.name}');
        continue;
      }

      if (!_cloudIdToLocalId.containsKey(cloudDocId)) {
        // Проверить, нет ли уже продукта с такими же данными (для предотвращения дублирования)
        final isDuplicate = _products.any((p) =>
            p.name == product.name &&
            p.expiryDate.isAtSameMomentAs(product.expiryDate) &&
            p.purchaseDate.isAtSameMomentAs(product.purchaseDate));

        if (isDuplicate) {
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
        debugPrint('Added new product from cloud: ${product.name}');
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

    // Удалить продукты, которых нет в облаке (удалены с других устройств)
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
        debugPrint('Deleted product from local (removed from cloud): localId $localId');
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

  Future<void> addProduct(ProductModel product) async {
    // Сначала добавляем в локальную БД
    final saved = await _repo.add(product);
    _products.add(saved);
    notifyListeners();

    // Синхронизировать в облако
    if (_authProvider?.accountModel != null) {
      try {
        final productData = product.toFirestore();
        productData['deviceId'] = _deviceId; // Добавляем deviceId

        final docRef = await _firestore
            .collection('accounts')
            .doc(_authProvider!.accountModel!.id)
            .collection('products')
            .add(productData);

        if (saved.id != null) {
          _cloudIdToLocalId[docRef.id] = saved.id!;
          await _saveMapping();
        }
        debugPrint('Added product to cloud: ${saved.name} (deviceId: $_deviceId)');
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
          final productData = product.toFirestore();
          productData['deviceId'] = _deviceId; // Добавляем deviceId

          await _firestore
              .collection('accounts')
              .doc(_authProvider!.accountModel!.id)
              .collection('products')
              .doc(entry.key)
              .set(productData);
          debugPrint('Updated product in cloud: ${product.name} (deviceId: $_deviceId)');
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
          debugPrint('Deleted product from cloud: ${product.name} (deviceId: $_deviceId)');
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
