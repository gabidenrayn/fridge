import '../core/database/database_helper.dart';
import '../models/product_model.dart';
import 'notification_service.dart';

/// Репозиторий — единая точка доступа к данным продуктов
class ProductRepository {
  final _db = DatabaseHelper.instance;
  final _notif = NotificationService.instance;

  Future<List<ProductModel>> getAll() => _db.getAllProducts();

  Future<ProductModel> add(ProductModel product) async {
    final id = await _db.insertProduct(product);
    final saved = product.copyWith(id: id);
    // Планируем уведомления после сохранения
    await _notif.scheduleForProduct(saved);
    return saved;
  }

  Future<void> update(ProductModel product) async {
    await _db.updateProduct(product);
    if (product.id != null) {
      await _notif.cancelForProduct(product.id!);
      await _notif.scheduleForProduct(product);
    }
  }

  Future<void> delete(ProductModel product) async {
    if (product.id != null) {
      await _db.deleteProduct(product.id!);
      await _notif.cancelForProduct(product.id!);
    }
  }

  Future<List<ProductModel>> getExpiring({int days = 3}) =>
      _db.getExpiringProducts(days: days);

  Future<List<ProductModel>> search(String query) => _db.searchProducts(query);
}
