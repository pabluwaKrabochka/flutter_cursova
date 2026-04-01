// ФАЙЛ: home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cursova/core/constants/home_constants.dart';
import 'package:flutter_cursova/features/transactions/widgets/carousel_widget.dart';
import 'package:flutter_cursova/features/transactions/widgets/transaction_list_item.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'add_transaction_screen.dart';
import '../cubit/transaction_cubit.dart';
import '../cubit/transaction_state.dart';

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
        title: const Text('Мій бюджет', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
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
              final monthName = HomeConstants.months[currentDate.month - 1];

              return Column(
                children: [
                  _buildMonthPicker(context, monthName, currentDate),
                  _buildBalanceCard(context, totalBalance),
                  const SizedBox(height: 12),
                  
                  PromoCarousel(currencyRates: currencyRates),
                  
                  const SizedBox(height: 8),
                  Expanded(
                    child: sortedList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: sortedList.length,
                            itemBuilder: (context, index) {
                              final transaction = sortedList[index];
                              final category = categories.firstWhere((c) => c.id == transaction.categoryId);
                              final currentGroupTitle = _getGroupTitle(transaction.timestamp);
                              bool showHeader = index == 0 || _getGroupTitle(sortedList[index - 1].timestamp) != currentGroupTitle;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showHeader)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                      child: Text(currentGroupTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                    ),
                                  TransactionListItem(
                                    key: ValueKey(transaction.id),
                                    transaction: transaction,
                                    category: category,
                                    allCategories: categories,
                                    isIncome: category.type == 'income',
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
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildMonthPicker(BuildContext context, String monthName, DateTime currentDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left, size: 32), onPressed: () => context.read<TransactionCubit>().changeMonth(-1)),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context, 
                initialDate: currentDate, 
                firstDate: DateTime(2020), 
                lastDate: DateTime(2100)
              );
              if (selectedDate != null && context.mounted) {
                context.read<TransactionCubit>().setMonth(selectedDate);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text('$monthName ${currentDate.year}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Icon(Icons.calendar_month, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right, size: 32), onPressed: () => context.read<TransactionCubit>().changeMonth(1)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double totalBalance) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer.withAlpha(150)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(11), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text('Загальний баланс за місяць', style: TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(totalBalance.toStringAsFixed(2), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                initialValue: context.read<TransactionCubit>().mainCurrency,
                onSelected: (newValue) => context.read<TransactionCubit>().changeMainCurrency(newValue),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: '₴', child: Text('₴ - Гривня')),
                  PopupMenuItem(value: '\$', child: Text('\$ - Долар')),
                  PopupMenuItem(value: '€', child: Text('€ - Євро')),
                ],
                child: Row(
                  children: [
                    Text(context.read<TransactionCubit>().mainCurrency, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const Icon(Icons.arrow_drop_down, size: 20, color: Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Lottie.asset('assets/emptyState.json', height: 160),
              const SizedBox(height: 12),
              const Text('Транзакцій ще немає', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildFAB(BuildContext context) {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        return FloatingActionButton.extended(
          onPressed: () {
            state.maybeWhen(
              loaded: (_, categories, __, ___) => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(value: context.read<TransactionCubit>(), child: AddTransactionScreen(categories: categories)))),
              orElse: () {},
            );
          },
          label: const Text('Додати'),
          icon: const Icon(Icons.add),
        );
      },
    );
  }
}