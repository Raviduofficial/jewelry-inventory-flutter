import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;
  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Aluth nama dunna nisa parana eka amathaka karala aluth ekak hadanawa
    _database = await _initDB('inventory_final.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Categories Table
    await db.execute(
      'CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)',
    );

    // Default categories tika
    await db.insert('categories', {'name': 'General'});
    await db.insert('categories', {'name': 'Electronics'});
    await db.insert('categories', {'name': 'Groceries'});

    // 2. Items Table (with Price & Limit)
    await db.execute('''
    CREATE TABLE items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      price REAL DEFAULT 0.0,        -- Unit Price
      min_limit INTEGER DEFAULT 5,   -- Low Stock Warning Limit
      physical_quantity INTEGER,     -- Stock Check waladi gahana real gana
      last_checked TEXT,
      image_path TEXT,
      category_id INTEGER,
      FOREIGN KEY (category_id) REFERENCES categories(id)
    )
    ''');

    // 3. Monthly Records Table (Mase anthimata reports save karanna)
    await db.execute('''
    CREATE TABLE monthly_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      month TEXT NOT NULL,           -- Ex: 2026-02
      total_sales REAL,              -- Wikinuna badu wala watinakama
      total_stock_value REAL,        -- Ithuru badu wala watinakama
      record_date TEXT               -- Save karapu welawa
    )
    ''');
  }

  // --- CATEGORY OPERATIONS ---
  Future<List<Map<String, dynamic>>> getCategories() async =>
      (await database).query('categories');

  Future<int> insertCategory(String name) async {
    final db = await database;
    return await db.insert('categories', {'name': name});
  }

  Future<int> updateCategory(int id, String name) async {
    final db = await database;
    return await db.update(
      'categories',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- ITEM OPERATIONS ---
  Future<int> insertItem(Map<String, dynamic> data) async =>
      (await database).insert('items', data);

  Future<int> updateItem(int id, Map<String, dynamic> data) async =>
      (await database).update('items', data, where: 'id=?', whereArgs: [id]);

  Future<int> deleteItem(int id) async =>
      (await database).delete('items', where: 'id=?', whereArgs: [id]);

  Future<List<Map<String, dynamic>>> getFilteredItems(
    String keyword,
    int? categoryId,
  ) async {
    final db = await database;
    String query =
        'SELECT items.*, categories.name AS category_name FROM items LEFT JOIN categories ON items.category_id = categories.id WHERE items.name LIKE ?';
    List args = ['%$keyword%'];
    if (categoryId != null) {
      query += ' AND category_id = ?';
      args.add(categoryId);
    }
    return await db.rawQuery(query, args);
  }

  // --- MONTH END OPERATIONS ---

  // 1. Record ekak save karanna
  Future<int> insertMonthlyRecord(Map<String, dynamic> data) async {
    return (await database).insert('monthly_records', data);
  }

  // 2. FINALIZE STOCK (Meka thama wadagathma method eka)
  // Mase anthimata 'Confirm' karama meka run wenawa.
  Future<void> finalizeStock() async {
    final db = await database;

    await db.transaction((txn) async {
      // Step A: Physical quantity eka System quantity ekata copy karanawa
      // (E kiyanne Real stock eka dan aluth stock eka wenawa)
      await txn.rawUpdate('''
        UPDATE items 
        SET quantity = physical_quantity 
        WHERE physical_quantity IS NOT NULL
      ''');

      // Step B: Physical quantity eka clear karanawa (Aluth maseta lasthi wenna)
      await txn.rawUpdate('''
        UPDATE items 
        SET physical_quantity = NULL, 
            last_checked = NULL
      ''');
    });
  }

  // (Optional) Pahu giya masa wala records ganna oni nam meka pawichchi karanna puluwan
  Future<List<Map<String, dynamic>>> getMonthlyRecords() async {
    final db = await database;
    return await db.query('monthly_records', orderBy: 'id DESC');
  }
}
