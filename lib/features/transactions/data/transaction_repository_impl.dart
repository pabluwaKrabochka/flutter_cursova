import 'package:sqflite/sqflite.dart';
import '../../../data/services/storage/database_service.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/transaction_model.dart';
import '../domain/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final DatabaseService _dbService;

  TransactionRepositoryImpl(this._dbService);

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await _dbService.database;
    // Сортуємо: нові транзакції зверху
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions', 
      orderBy: 'timestamp DESC'
    );
    
    return maps.map((map) => TransactionModel.fromJson(map)).toList();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final db = await _dbService.database;
    await db.insert(
      'transactions', 
      transaction.toJson(), 
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  @override
  Future<void> deleteTransaction(int id) async {
    final db = await _dbService.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    
    return maps.map((map) => CategoryModel.fromJson(map)).toList();
  }
}