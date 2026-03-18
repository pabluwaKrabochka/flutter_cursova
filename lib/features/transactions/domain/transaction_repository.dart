import '../../../../../data/models/category_model.dart';
import '../../../../../data/models/transaction_model.dart';

abstract class TransactionRepository {
  // Отримати всі записи
  Future<List<TransactionModel>> getAllTransactions();
  
  // Додати новий запис (витрату чи дохід)
  Future<void> addTransaction(TransactionModel transaction);
  
  // Видалити запис
  Future<void> deleteTransaction(int id);
  
  // Отримати список категорій для вибору
  Future<List<CategoryModel>> getAllCategories();
}