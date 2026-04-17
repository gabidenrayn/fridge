import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/date_utils.dart';

/// Категории продуктов
enum ProductCategory {
  dairy, // Молочное
  meat, // Мясо
  veggies, // Овощи и фрукты
  drinks, // Напитки
  frozen, // Заморозка
  bakery, // Выпечка
  other, // Прочее
}

extension ProductCategoryExt on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.dairy:
        return 'Молочное';
      case ProductCategory.meat:
        return 'Мясо';
      case ProductCategory.veggies:
        return 'Овощи';
      case ProductCategory.drinks:
        return 'Напитки';
      case ProductCategory.frozen:
        return 'Заморозка';
      case ProductCategory.bakery:
        return 'Выпечка';
      case ProductCategory.other:
        return 'Прочее';
    }
  }

  String get icon {
    switch (this) {
      case ProductCategory.dairy:
        return '🥛';
      case ProductCategory.meat:
        return '🥩';
      case ProductCategory.veggies:
        return '🥦';
      case ProductCategory.drinks:
        return '🧃';
      case ProductCategory.frozen:
        return '🧊';
      case ProductCategory.bakery:
        return '🍞';
      case ProductCategory.other:
        return '📦';
    }
  }
}

/// Основная модель продукта
class ProductModel {
  final int? id;
  final String name;
  final String? barcode;
  final DateTime expiryDate;
  final DateTime purchaseDate;
  final double quantity;
  final String unit;
  final ProductCategory category;
  final String? note;
  final String? imagePath;
  final bool isFavorite;
  final String? brand;

  ProductModel({
    this.id,
    required this.name,
    this.barcode,
    required this.expiryDate,
    required this.purchaseDate,
    required this.quantity,
    this.unit = 'шт',
    this.category = ProductCategory.other,
    this.note,
    this.imagePath,
    this.isFavorite = false,
    this.brand,
  });

  /// Статус свежести (0 — свеж, 1 — предупреждение, 2 — просрочен)
  int get freshnessStatus => AppDateUtils.getFreshnessStatus(expiryDate);

  /// Копия с изменёнными полями
  ProductModel copyWith({
    int? id,
    String? name,
    String? barcode,
    DateTime? expiryDate,
    DateTime? purchaseDate,
    double? quantity,
    String? unit,
    ProductCategory? category,
    String? note,
    String? imagePath,
    bool? isFavorite,
    String? brand,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      expiryDate: expiryDate ?? this.expiryDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      brand: brand ?? this.brand,
    );
  }

  /// Сериализация для SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'expiry_date': expiryDate.toIso8601String(),
      'purchase_date': purchaseDate.toIso8601String(),
      'quantity': quantity,
      'unit': unit,
      'category': category.index,
      'note': note,
      'image_path': imagePath,
      'is_favorite': isFavorite ? 1 : 0,
      'brand': brand,
    };
  }

  /// Десериализация из SQLite
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      barcode: map['barcode'] as String?,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      purchaseDate: DateTime.parse(map['purchase_date'] as String),
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String? ?? 'шт',
      category: ProductCategory.values[map['category'] as int? ?? 6],
      note: map['note'] as String?,
      imagePath: map['image_path'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      brand: map['brand'] as String?,
    );
  }

  /// Сериализация для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'barcode': barcode,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'quantity': quantity,
      'unit': unit,
      'category': category.index,
      'note': note,
      'imagePath': imagePath,
      'isFavorite': isFavorite,
      'brand': brand,
    };
  }

  /// Десериализация из Firestore
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: int.tryParse(doc.id), // Для совместимости, но в облаке ID строковый
      name: data['name'] ?? '',
      barcode: data['barcode'],
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      quantity: (data['quantity'] as num).toDouble(),
      unit: data['unit'] ?? 'шт',
      category: ProductCategory.values[data['category'] ?? 6],
      note: data['note'],
      imagePath: data['imagePath'],
      isFavorite: data['isFavorite'] ?? false,
      brand: data['brand'],
    );
  }
}
