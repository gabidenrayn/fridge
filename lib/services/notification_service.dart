import '../models/product_model.dart';

/// Заглушка сервиса уведомлений (для веб/десктоп версии)
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  Future<void> init() async {
    // Уведомления отключены в данной версии
  }

  Future<void> scheduleForProduct(ProductModel product) async {
    // Уведомления отключены в данной версии
  }

  Future<void> cancelForProduct(int productId) async {}

  Future<void> cancelAll() async {}
}
