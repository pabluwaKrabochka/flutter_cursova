import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cursova/features/transactions/presentation/screens/add_transaction_screen.dart';
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
                            
                            // ВИПРАВЛЕННЯ ASYNC GAP:
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
                        Text(
                          '${totalBalance.toStringAsFixed(2)} ₴',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                  Expanded(
                    child: sortedList.isEmpty
                        ? const Center(child: Text('Транзакцій ще немає'))
                        : ListView.builder(
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
                                  ListTile(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => BlocProvider.value(
                                        value: context.read<TransactionCubit>(),
                                        child: AddTransactionScreen(categories: categories, transactionToEdit: transaction),
                                      )),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: Color(int.parse(category.colorHex)),
                                      child: Icon(IconData(category.iconCode, fontFamily: 'MaterialIcons'), color: Colors.white),
                                    ),
                                    title: Text(category.name),
                                    subtitle: Text(transaction.note ?? DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(transaction.timestamp))),
                                    trailing: Text(
                                      '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
                                      style: TextStyle(
                                        color: isIncome ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
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