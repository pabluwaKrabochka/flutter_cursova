import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart'; // Додано імпорт графіків
import 'package:lottie/lottie.dart';
import '../cubit/transaction_cubit.dart';
import '../cubit/transaction_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналітика витрат'),
        centerTitle: true,
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          return state.maybeWhen(
            loaded: (transactions, categories, totalBalance, currencyRates) {
              // 1. Фільтруємо ТІЛЬКИ витрати та рахуємо суму по кожній категорії
              Map<String, double> expenseTotals = {};
              Map<String, Color> categoryColors = {};
              double totalExpense = 0;

              for (var t in transactions) {
                final category = categories.firstWhere((c) => c.id == t.categoryId);
                if (category.type == 'expense') {
                  expenseTotals[category.name] = (expenseTotals[category.name] ?? 0) + t.amount;
                  categoryColors[category.name] = Color(int.parse(category.colorHex));
                  totalExpense += t.amount;
                }
              }

              // Якщо витрат немає взагалі
              if (expenseTotals.isEmpty) {
                return Column(
                  children: [
                    
                    Lottie.asset('assets/emptyStateDiagram.json',repeat: true,frameRate: FrameRate(30)),
                    Text('Немає витрат для аналізу'),
                  ],
                );
              }

              // 2. Формуємо секції для кругової діаграми
              List<PieChartSectionData> sections = [];
              expenseTotals.forEach((name, amount) {
                final percent = (amount / totalExpense) * 100;
                sections.add(
                  PieChartSectionData(
                    color: categoryColors[name],
                    value: amount,
                    title: '${percent.toStringAsFixed(1)}%',
                    radius: 80,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                );
              });

              // 3. Малюємо інтерфейс (Графік + Легенда)
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Структура ваших витрат', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    
                    // Сам графік fl_chart
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          centerSpaceRadius: 50,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Легенда (список категорій під графіком)
                    Expanded(
                      child: ListView.builder(
                        itemCount: expenseTotals.length,
                        itemBuilder: (context, index) {
                          String categoryName = expenseTotals.keys.elementAt(index);
                          double amount = expenseTotals.values.elementAt(index);
                          Color color = categoryColors[categoryName]!;

                          return ListTile(
                            leading: CircleAvatar(backgroundColor: color, radius: 12),
                            title: Text(categoryName),
                            trailing: Text('${amount.toStringAsFixed(2)} ₴', style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}