import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/product_model.dart';

/// Singleton-обёртка над SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_fridge.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            name          TEXT NOT NULL,
            barcode       TEXT,
            expiry_date   TEXT NOT NULL,
            purchase_date TEXT NOT NULL,
            quantity      REAL NOT NULL DEFAULT 1,
            unit          TEXT NOT NULL DEFAULT 'шт',
            category      INTEGER NOT NULL DEFAULT 6,
            note          TEXT,
            image_path    TEXT,
            is_favorite   INTEGER NOT NULL DEFAULT 0,
            brand         TEXT
          )
        ''');
      },
    );
  }

  // ─────────── CRUD ───────────

  Future<int> insertProduct(ProductModel product) async {
    final db = await database;
    return db.insert('products', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ProductModel>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'expiry_date ASC');
    return maps.map<ProductModel>(ProductModel.fromMap).toList();
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// Продукты, срок годности которых истекает в ближайшие [days] дней
  Future<List<ProductModel>> getExpiringProducts({int days = 3}) async {
    final db = await database;
    final now = DateTime.now();
    final limit = now.add(Duration(days: days));
    final maps = await db.query(
      'products',
      where: 'expiry_date <= ? AND expiry_date >= ?',
      whereArgs: [limit.toIso8601String(), now.toIso8601String()],
      orderBy: 'expiry_date ASC',
    );
    return maps.map<ProductModel>(ProductModel.fromMap).toList();
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return maps.map<ProductModel>(ProductModel.fromMap).toList();
  }
}
