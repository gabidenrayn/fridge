/// Утилиты для работы с датами и статусами свежести
class FreshnesStatus {
  static const int fresh = 0;
  static const int warning = 1; // < 3 дней
  static const int expired = 2;
}

class AppDateUtils {
  AppDateUtils._();

  /// Возвращает статус свежести продукта
  static int getFreshnessStatus(DateTime expiryDate) {
    final now = DateTime.now();
    final diff = expiryDate.difference(now).inDays;
    if (diff < 0) return FreshnesStatus.expired;
    if (diff <= 3) return FreshnesStatus.warning;
    return FreshnesStatus.fresh;
  }

  /// Строка "Истекает через X дней" / "Просрочен X дней назад"
  static String getExpiryLabel(DateTime expiryDate) {
    final now = DateTime.now();
    final diff = expiryDate.difference(now).inDays;
    if (diff < 0) return 'Просрочен ${(-diff)}д назад';
    if (diff == 0) return 'Истекает сегодня!';
    if (diff == 1) return 'Истекает завтра';
    return 'Через $diff дней';
  }

  /// Форматирование даты в строку dd.MM.yyyy
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}'
        '.${date.month.toString().padLeft(2, '0')}'
        '.${date.year}';
  }
}
