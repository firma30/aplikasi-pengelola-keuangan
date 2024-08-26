import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'models/transaksi.dart' as transaksi;
import 'models/kategory.dart' as category;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() => _instance;

  static DatabaseHelper get instance => _instance;

  Future<Database> get db async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'my_database.db');
    return openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        userId TEXT, 
        categoryId INTEGER, 
        categoryName TEXT, 
        amount REAL, 
        transactionType TEXT, 
        transactionDate TEXT, 
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        userId TEXT,
        name TEXT NOT NULL, 
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT
      )
    ''');

    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    List<Map<String, dynamic>> defaultCategories = [
      {'name': 'Gaji', 'type': 'Pendapatan', 'userId': 'default'},
      {'name': 'Bonus', 'type': 'Pendapatan', 'userId': 'default'},
      {'name': 'Investasi', 'type': 'Pendapatan', 'userId': 'default'},
      {'name': 'Makanan', 'type': 'Pengeluaran', 'userId': 'default'},
      {'name': 'Transportasi', 'type': 'Pengeluaran', 'userId': 'default'},
      {'name': 'Belanja', 'type': 'Pengeluaran', 'userId': 'default'},
    ];

    for (var category in defaultCategories) {
      // Periksa apakah kategori sudah ada
      var existingCategory = await db.query(
        'categories',
        where: 'name = ? AND type = ? AND userId = ?',
        whereArgs: [category['name'], category['type'], 'userId'],
      );

      if (existingCategory.isEmpty) {
        await db.insert('categories', category,
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN categoryName TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE categories ADD COLUMN userId TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE categories ADD COLUMN type TEXT');
    }
    if (oldVersion < 5) {
      // Ensure default categories exist
      await _insertDefaultCategories(db);
    }
    if (oldVersion < 6) {
      // Update existing default categories to have 'default' userId
      await db.execute(
          "UPDATE categories SET userId = 'default' WHERE userId IS NULL");
    }
  }

  Future<void> ensureDefaultCategories() async {
    final db = await instance.db;
    await _insertDefaultCategories(db);
  }

  Future<List<category.Category>> getKategori(String userId) async {
    final db = await instance.db;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'userId = ? OR userId = ?',
      whereArgs: [userId, 'default'],
      groupBy: 'name, type',
    );
    return maps.map((map) => category.Category.fromMap(map)).toList();
  }

  Future<void> insertTransaction(transaksi.Transaction transaction) async {
    final db = await instance.db;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertKategori(
      String namaKategori, String tipeKategori, String userId) async {
    final db = await instance.db;
    await db.insert(
      'categories',
      {
        'name': namaKategori,
        'type': tipeKategori,
        'userId': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<transaksi.Transaction>> readLatestTransactions(
      int limit, String userId) async {
    final db = await instance.db;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM transactions WHERE userId = ? ORDER BY transactionDate DESC LIMIT ?',
      [userId, limit],
    );
    return maps.map((map) => transaksi.Transaction.fromMap(map)).toList();
  }

  Future<List<transaksi.Transaction>> readAllTransactions(String userId) async {
    final db = await instance.db;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => transaksi.Transaction.fromMap(map)).toList();
  }

  Future<double> getTotalPendapatan(String userId) async {
    final db = await instance.db;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as totalPendapatan FROM transactions WHERE transactionType = ? AND userId = ?',
      ['Pendapatan', userId],
    );
    return (result.first['totalPendapatan'] as double?) ?? 0.0;
  }

  Future<double> getTotalPengeluaran(String userId) async {
    final db = await instance.db;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as totalPengeluaran FROM transactions WHERE transactionType = ? AND userId = ?',
      ['Pengeluaran', userId],
    );
    return (result.first['totalPengeluaran'] as double?) ?? 0.0;
  }

  Future<double> getTotalPendapatanByMonth(
      int year, int month, String userId) async {
    final db = await instance.db;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as totalPendapatan FROM transactions WHERE transactionType = ? AND userId = ? AND strftime(\'%Y-%m\', transactionDate) = ?',
      ['Pendapatan', userId, '$year-${month.toString().padLeft(2, '0')}'],
    );
    return (result.first['totalPendapatan'] as double?) ?? 0.0;
  }

  Future<double> getTotalPengeluaranByMonth(
      int year, int month, String userId) async {
    final db = await instance.db;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as totalPengeluaran FROM transactions WHERE transactionType = ? AND userId = ? AND strftime(\'%Y-%m\', transactionDate) = ?',
      ['Pengeluaran', userId, '$year-${month.toString().padLeft(2, '0')}'],
    );
    return (result.first['totalPengeluaran'] as double?) ?? 0.0;
  }

  Future<void> resetDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'my_database.db');
    await deleteDatabase(path);
    _database = null;
    await initDatabase();
  }

  Future<void> close() async {
    final db = await instance.db;
    await db.close();
  }

  Future<void> clearUserData(String userId) async {
    final db = await instance.db;
    await db.delete('transactions', where: 'userId = ?', whereArgs: [userId]);
    await db.delete('categories',
        where: 'userId = ? AND userId != ?', whereArgs: [userId, 'default']);
  }

  Future<void> deleteTransaction(int id) async {
    final db = await instance.db;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTransaction(transaksi.Transaction transaction) async {
    final db = await instance.db;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<double> getPendapatanTahunan(String userId) async {
    final db = await instance.db;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as totalPendapatan FROM transactions WHERE transactionType = ? AND userId = ? AND transactionDate >= date("now", "-1 year")',
      ['Pendapatan', userId],
    );
    return (result.first['totalPendapatan'] as double?) ?? 0.0;
  }
}
