import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cursova/data/models/category_model.dart';
import 'package:flutter_cursova/data/services/network/currency_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/transaction_repository.dart';
import '../../../../data/models/transaction_model.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _repository;

  DateTime currentDate = DateTime(DateTime.now().year, DateTime.now().month);
  String mainCurrency = '₴';

  TransactionCubit(this._repository) : super(const TransactionState.initial());

  Future<void> loadData() async {
    final isAlreadyLoaded = state.maybeMap(
      loaded: (_) => true,
      orElse: () => false,
    );

    if (!isAlreadyLoaded) {
      emit(const TransactionState.loading());
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      mainCurrency = prefs.getString('main_currency') ?? '₴';

      final allTransactions = await _repository.getAllTransactions();
      final categories = await _repository.getAllCategories();
      final rates = await CurrencyApiService().getPrivatRates();

      final filteredTransactions = allTransactions.where((t) {
        final date = DateTime.fromMillisecondsSinceEpoch(t.timestamp);
        return date.year == currentDate.year && date.month == currentDate.month;
      }).toList();

      double balance = 0;
      for (var t in filteredTransactions) {
        final category = categories.firstWhere((c) => c.id == t.categoryId);

        double finalAmount = 0;

        // --- ВИПРАВЛЕНА ЛОГІКА ТУТ ---
        // Якщо валюта транзакції співпадає з обраною головною валютою — конвертація НЕ потрібна
        if (t.currency == mainCurrency) {
          finalAmount = t.amount;
        } else {
          // Якщо валюти різні — конвертуємо через гривню
          // 1. Переводимо суму транзакції в ГРИВНІ (базову валюту)
          double amountInUAH = t.amount;
          if (t.currency == '\$') {
            final usdBuyRate = double.parse(rates.firstWhere((r) => r['ccy'] == 'USD')['buy']);
            amountInUAH = t.amount * usdBuyRate;
          } else if (t.currency == '€') {
            final eurBuyRate = double.parse(rates.firstWhere((r) => r['ccy'] == 'EUR')['buy']);
            amountInUAH = t.amount * eurBuyRate;
          }

          // 2. Переводимо ГРИВНІ в головну валюту (mainCurrency)
          finalAmount = amountInUAH;
          if (mainCurrency == '\$') {
            final usdSaleRate = double.parse(rates.firstWhere((r) => r['ccy'] == 'USD')['sale']);
            finalAmount = amountInUAH / usdSaleRate;
          } else if (mainCurrency == '€') {
            final eurSaleRate = double.parse(rates.firstWhere((r) => r['ccy'] == 'EUR')['sale']);
            finalAmount = amountInUAH / eurSaleRate;
          }
        }
        // ------------------------------

        if (category.type == 'income') {
          balance += finalAmount;
        } else {
          balance -= finalAmount;
        }
      }

      emit(TransactionState.loaded(
        transactions: filteredTransactions,
        categories: categories,
        totalBalance: balance,
        currencyRates: rates,
      ));
    } catch (e) {
      emit(TransactionState.error('Помилка завантаження даних: $e'));
    }
  }

  // Решта методів (changeMainCurrency, setMonth і т.д.) залишаються без змін
  Future<void> changeMainCurrency(String newCurrency) async {
    mainCurrency = newCurrency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('main_currency', newCurrency);
    loadData();
  }

  void setMonth(DateTime newDate) {
    currentDate = DateTime(newDate.year, newDate.month);
    loadData();
  }

  void changeMonth(int offset) {
    currentDate = DateTime(currentDate.year, currentDate.month + offset);
    loadData();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _repository.addTransaction(transaction);
      await loadData();
    } catch (e) {
      emit(TransactionState.error('Помилка додавання: $e'));
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _repository.deleteTransaction(id);
      await loadData();
    } catch (e) {
      emit(TransactionState.error('Помилка видалення: $e'));
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      await _repository.addCategory(category);
      await loadData();
    } catch (e) {
      emit(TransactionState.error('Помилка додавання категорії: $e'));
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _repository.updateTransaction(transaction);
      await loadData();
    } catch (e) {
      emit(TransactionState.error('Помилка оновлення: $e'));
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _repository.updateCategory(category);
      await loadData();
    } catch (e) {
      emit(TransactionState.error('Помилка оновлення категорії: $e'));
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _repository.deleteCategory(id);
      await loadData();
    } catch (e) {
      emit(TransactionState.error('Помилка видалення категорії: $e'));
    }
  }
}