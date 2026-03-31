import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/transaction_model.dart';

// ОСЬ ЦЕЙ РЯДОК БУВ ПРОПУЩЕНИЙ (Він обов'язковий!):
part 'transaction_state.freezed.dart';

@freezed
class TransactionState with _$TransactionState {
  const factory TransactionState.initial() = _Initial;
  const factory TransactionState.loading() = _Loading;
  
  const factory TransactionState.loaded({
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required double totalBalance,
    List<dynamic>? currencyRates, // Твоє нове поле
  }) = _Loaded; // Це ім'я має збігатися зі згенерованим класом

  const factory TransactionState.error(String message) = _Error;
}