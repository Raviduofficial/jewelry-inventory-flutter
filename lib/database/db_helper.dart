import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      physical_quantity INTEGER,
      last_checked TEXT,
      image_path TEXT,
      category_id INTEGER,
      FOREIGN KEY (category_id) REFERENCES categories(id)
    )
    ''');
  }

  // CATEGORY
  Future<int> insertCategory(String name) async {
    final db = await database;
    return await db.insert('categories', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories');
  }

  // ITEMS
  Future<int> insertItem(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('items', data);
  }

  Future<int> updateItem(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('items', data, where: 'id=?', whereArgs: [id]);
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('items', where: 'id=?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getFilteredItems(
    String keyword,
    int? categoryId,
  ) async {
    final db = await database;

    String query = '''
    SELECT items.*, categories.name AS category_name
    FROM items
    LEFT JOIN categories ON items.category_id = categories.id
    WHERE items.name LIKE ?
    ''';

    List args = ['%$keyword%'];

    if (categoryId != null) {
      query += ' AND category_id = ?';
      args.add(categoryId);
    }

    return await db.rawQuery(query, args);
  }
}
