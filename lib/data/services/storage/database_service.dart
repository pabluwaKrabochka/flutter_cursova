import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance.db');
    return _database!;
  }

 Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      // ДОДАЄМО ЦЕЙ БЛОК:
      onConfigure: (db) async {
        // Вмикаємо підтримку Foreign Keys для каскадного видалення
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        iconCode INTEGER NOT NULL,
        colorHex TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        categoryId INTEGER NOT NULL,
        currency TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');
    
    // Додаємо категорії (виправили 0 media_payments на числовий код)
    await db.insert('categories', {
      'name': 'Продукти', 
      'iconCode': 0xe51c, 
      'colorHex': '0xFFE57373', 
      'type': 'expense'
    });
    
    await db.insert('categories', {
      'name': 'Зарплата', 
      'iconCode': 0xe4b0, // Код іконки payments
      'colorHex': '0xFF81C784', 
      'type': 'income'
    });
  }
}