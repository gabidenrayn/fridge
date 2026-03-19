import 'dart:convert';
import 'package:http/http.dart' as http;

/// Результат поиска по штрихкоду через Open Food Facts
class FoodProduct {
  final String? name;
  final String? brand;
  final String? imageUrl;
  final String? quantity;
  final List<String> categories;

  const FoodProduct({
    this.name,
    this.brand,
    this.imageUrl,
    this.quantity,
    this.categories = const [],
  });
}

/// Сервис для работы с Open Food Facts API
/// Документация: https://world.openfoodfacts.org/data
class ApiService {
  static const String _baseUrl = 'https://world.openfoodfacts.org';

  /// Поиск продукта по штрихкоду
  /// GET /api/v2/product/{barcode}.json
  Future<FoodProduct?> getProductByBarcode(String barcode) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v2/product/$barcode.json');
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'SmartFridgeApp/1.0 (contact@example.com)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // status: 1 — найдено, 0 — нет
      if (json['status'] != 1) return null;

      final product = json['product'] as Map<String, dynamic>? ?? {};

      // Получаем название: сначала русское, потом базовое
      final name = product['product_name_ru'] as String? ??
          product['product_name'] as String? ??
          product['abbreviated_product_name'] as String?;

      final brand = product['brands'] as String?;
      final imageUrl = product['image_front_url'] as String?;
      final quantity = product['quantity'] as String?;

      // Парсим категории
      final rawCategories = product['categories_tags'] as List<dynamic>? ?? [];
      final categories = rawCategories
          .take(3)
          .map((e) => e.toString().replaceAll('en:', '').replaceAll('-', ' '))
          .toList();

      return FoodProduct(
        name: name?.isNotEmpty == true ? name : null,
        brand: brand?.isNotEmpty == true ? brand : null,
        imageUrl: imageUrl,
        quantity: quantity,
        categories: categories,
      );
    } catch (_) {
      return null;
    }
  }
}
