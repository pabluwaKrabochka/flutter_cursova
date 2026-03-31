import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cursova/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:lottie/lottie.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/transaction_model.dart';
import '../cubit/transaction_cubit.dart';
import '../cubit/transaction_state.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGroupTitle(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Сьогодні';
    if (checkDate == yesterday) return 'Вчора';
    return DateFormat('d MMMM yyyy', 'uk_UA').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мій бюджет'),
        centerTitle: true,
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(child: Text(message, style: const TextStyle(color: Colors.red))),
            
            loaded: (transactions, categories, totalBalance, currencyRates) {
              final sortedList = List.from(transactions)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
              final currentDate = context.read<TransactionCubit>().currentDate;
              const months = ['Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень', 'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень'];
              final monthName = months[currentDate.month - 1];

              return Column(
                children: [
                  // 1. Панель перемикання місяців
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 32),
                          onPressed: () => context.read<TransactionCubit>().changeMonth(-1),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: currentDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDatePickerMode: DatePickerMode.year,
                            );
                            
                            if (selectedDate != null && context.mounted) {
                              context.read<TransactionCubit>().setMonth(selectedDate);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Text('$monthName ${currentDate.year}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                const Icon(Icons.calendar_month, size: 20, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 32),
                          onPressed: () => context.read<TransactionCubit>().changeMonth(1),
                        ),
                      ],
                    ),
                  ),

                  // 2. Баланс
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text('Загальний баланс за місяць', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              totalBalance.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              initialValue: context.read<TransactionCubit>().mainCurrency,
                              onSelected: (newValue) {
                                context.read<TransactionCubit>().changeMainCurrency(newValue);
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(value: '₴', child: Text('₴ - Гривня')),
                                const PopupMenuItem<String>(value: '\$', child: Text('\$ - Долар')),
                                const PopupMenuItem<String>(value: '€', child: Text('€ - Євро')),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    Text(
                                      context.read<TransactionCubit>().mainCurrency,
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                                    ),
                                    const Icon(Icons.arrow_drop_down, size: 20, color: Colors.blue),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3. Таблиця курсу валют
                  if (currencyRates != null && currencyRates.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Валюта', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text('Купівля', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text('Продаж', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              ],
                            ),
                            const Divider(),
                            ...currencyRates.where((e) => e['ccy'] == 'USD' || e['ccy'] == 'EUR').map((rate) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${rate['ccy']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${double.parse(rate['buy']).toStringAsFixed(2)} ₴'),
                                  Text('${double.parse(rate['sale']).toStringAsFixed(2)} ₴', style: const TextStyle(color: Colors.blue)),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),

                  // 4. Список транзакцій
               // Знайдіть цей блок у вашому коді (приблизно 193 рядок):
Expanded(
  child: sortedList.isEmpty
      ? SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Lottie.asset(
                'assets/emptyState.json',
                height: 200,
                repeat: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Транзакцій ще немає',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
            ],
          ),
        )
      : ListView.builder(
          // --- ДОДАЄМО ЦЕЙ РЯДОК ---
          padding: const EdgeInsets.only(bottom: 80), // Відступ 80 пікселів знизу
          // -------------------------
          itemCount: sortedList.length,
          itemBuilder: (context, index) {
            final transaction = sortedList[index];
            final category = categories.firstWhere((c) => c.id == transaction.categoryId);
            final isIncome = category.type == 'income';
            final currentGroupTitle = _getGroupTitle(transaction.timestamp);
            
            bool showHeader = index == 0 || _getGroupTitle(sortedList[index - 1].timestamp) != currentGroupTitle;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showHeader)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(currentGroupTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                _TransactionListItem(
                  key: ValueKey(transaction.id),
                  transaction: transaction,
                  category: category,
                  allCategories: categories,
                  isIncome: isIncome,
                ),
              ],
            );
          },
        ),
),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          return FloatingActionButton(
            onPressed: () {
              state.maybeWhen(
                loaded: (_, categories, __, ___) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<TransactionCubit>(),
                        child: AddTransactionScreen(categories: categories),
                      ),
                    ),
                  );
                },
                orElse: () {},
              );
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
// --- ОНОВЛЕНИЙ ВІДЖЕТ ДЛЯ КОЖНОЇ ТРАНЗАКЦІЇ ---
class _TransactionListItem extends StatefulWidget {
  final TransactionModel transaction;
  final CategoryModel category;
  final List<CategoryModel> allCategories;
  final bool isIncome;

  const _TransactionListItem({
    super.key, // Key вже на місці
    required this.transaction,
    required this.category,
    required this.allCategories,
    required this.isIncome,
  });

  @override
  State<_TransactionListItem> createState() => _TransactionListItemState();
}

class _TransactionListItemState extends State<_TransactionListItem> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant _TransactionListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Скидаємо стан розкриття, якщо дані в цій комірці списку змінилися
    if (widget.transaction.id != oldWidget.transaction.id) {
      _isExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNote = widget.transaction.note != null && widget.transaction.note!.trim().isNotEmpty;
    
    // Форматування дати: 31.03.2026 14:30
    final transactionDate = DateTime.fromMillisecondsSinceEpoch(widget.transaction.timestamp);
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(transactionDate);

    return Dismissible(
      key: Key(widget.transaction.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Підтвердження"),
            content: const Text("Ви впевнені, що хочете видалити цю транзакцію?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Скасувати")),
              TextButton(
                onPressed: () => Navigator.pop(context, true), 
                child: const Text("Видалити", style: TextStyle(color: Colors.red))
              ),
            ],
          ),
        );
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<TransactionCubit>().deleteTransaction(widget.transaction.id!);
      },
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(int.parse(widget.category.colorHex)),
              child: Icon(IconData(widget.category.iconCode, fontFamily: 'MaterialIcons'), color: Colors.white),
            ),
            title: Text(widget.category.name),
            subtitle: Text(formattedDate), // Новий формат дати
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Кнопка редагування
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BlocProvider.value(
                        value: context.read<TransactionCubit>(),
                        child: AddTransactionScreen(
                          categories: widget.allCategories, 
                          transactionToEdit: widget.transaction
                        ),
                      )),
                    );
                  },
                ),
                // Сума
                Text(
                  '${widget.isIncome ? '+' : '-'}${widget.transaction.amount.toStringAsFixed(2)} ${widget.transaction.currency}',
                  style: TextStyle(
                    color: widget.isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // Стрілочка: малюється ТІЛЬКИ якщо є примітка. БЕЗ else блоку.
                if (hasNote)
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, 
                      color: Colors.grey
                    ),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 8),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),
              ],
            ),
          ),
          
          // Блок примітки
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0, width: double.infinity),
            secondChild: hasNote 
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 72, right: 16, bottom: 12),
                    child: Text(
                      'Примітка: ${widget.transaction.note}',
                      style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  )
                : const SizedBox(height: 0),
            crossFadeState: _isExpanded && hasNote ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}