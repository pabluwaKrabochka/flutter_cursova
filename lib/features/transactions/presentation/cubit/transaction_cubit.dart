import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cursova/data/models/category_model.dart';
import '../../domain/transaction_repository.dart';
import '../../../../data/models/transaction_model.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _repository;

  // Зберігаємо поточний обраний місяць (за замовчуванням - поточний)
  DateTime currentDate = DateTime(DateTime.now().year, DateTime.now().month);

  TransactionCubit(this._repository) : super(const TransactionState.initial());

  Future<void> loadData() async {
    emit(const TransactionState.loading());
    try {
      final allTransactions = await _repository.getAllTransactions();
      final categories = await _repository.getAllCategories();
      
      // ФІЛЬТРУЄМО ТРАНЗАКЦІЇ ЗА ОБРАНИМ МІСЯЦЕМ
      final filteredTransactions = allTransactions.where((t) {
        final date = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
        return date.year == currentDate.year && date.month == currentDate.month;
      }).toList();

      // Розраховуємо баланс ТІЛЬКИ для відфільтрованих транзакцій
      double balance = 0;
      for (var t in filteredTransactions) {
        final category = categories.firstWhere((c) => c.id == t.categoryId);
        if (category.type == 'income') {
          balance += t.amount;
        } else {
          balance -= t.amount;
        }
      }

      emit(TransactionState.loaded(
        transactions: filteredTransactions, // Віддаємо на екран тільки цей місяць!
        categories: categories,
        totalBalance: balance,
      ));
    } catch (e) {
      emit(TransactionState.error('Помилка завантаження даних: $e'));
    }
  }
  void setMonth(DateTime newDate) {
    currentDate = DateTime(newDate.year, newDate.month);
    loadData(); // Перезавантажуємо дані для обраного місяця
  }

  // ДОДАЄМО МЕТОД ДЛЯ ПЕРЕМИКАННЯ МІСЯЦІВ
  void changeMonth(int offset) {
    currentDate = DateTime(currentDate.year, currentDate.month + offset);
    loadData(); // Перезавантажуємо дані з новим місяцем
  }
  // Метод для додавання транзакції
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _repository.addTransaction(transaction);
      await loadData(); // Оновлюємо список та баланс після додавання
    } catch (e) {
      emit(TransactionState.error('Помилка додавання: $e'));
    }
  }

  // Метод для видалення транзакції
  Future<void> deleteTransaction(int id) async {
    try {
      await _repository.deleteTransaction(id);
      await loadData(); // Оновлюємо список
    } catch (e) {
      emit(TransactionState.error('Помилка видалення: $e'));
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      await _repository.addCategory(category);
      await loadData(); // Перезавантажуємо всі дані, щоб UI побачив нову категорію
    } catch (e) {
      emit(TransactionState.error('Помилка додавання категорії: $e'));
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _repository.updateTransaction(transaction);
      await loadData(); // Оновлюємо список
    } catch (e) {
      emit(TransactionState.error('Помилка оновлення: $e'));
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _repository.updateCategory(category);
      await loadData(); // Оновлюємо список
    } catch (e) {
      emit(TransactionState.error('Помилка оновлення категорії: $e'));
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _repository.deleteCategory(id);
      await loadData(); // Перезавантажуємо всі дані
    } catch (e) {
      emit(TransactionState.error('Помилка видалення категорії: $e'));
    }
  }
}