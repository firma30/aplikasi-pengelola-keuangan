// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// class DatabaseHelper {
//   static final DatabaseHelper instance = DatabaseHelper._init();

//   static Database? _database;

//   DatabaseHelper._init();

//   Future<Database> get database async {
//     if (_database != null) return _database!;

//     _database = await _initDB('transactions.db');
//     return _database!;
//   }

//   Future<Database> _initDB(String filePath) async {
//     final dbPath = await getDatabasesPath();
//     final path = join(dbPath, filePath);

//     return await openDatabase(path, version: 1, onCreate: _createDB);
//   }

//   Future _createDB(Database db, int version) async {
//     const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
//     const textType = 'TEXT NOT NULL';
//     const doubleType = 'REAL NOT NULL';

//     await db.execute('''
//     CREATE TABLE transactions (
//       id $idType,
//       type $textType,
//       category $textType,
//       account $textType,
//       amount $doubleType,
//       note $textType,
//       date $textType
//     )
//     ''');
//   }

//   Future<int> insertTransaction(Map<String, dynamic> transaction) async {
//     final db = await instance.database;

//     return await db.insert('transactions', transaction);
//   }

//   Future close() async {
//     final db = await instance.database;

//     db.close();
//   }
// }
