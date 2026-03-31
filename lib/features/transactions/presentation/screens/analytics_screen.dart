import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import '../cubit/transaction_cubit.dart';
import '../cubit/transaction_state.dart';

enum ChartType { pie, bar }
enum TransactionType { expense, income }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  ChartType _chartType = ChartType.pie;
  TransactionType _transactionType = TransactionType.expense;

  // --- ДОПОМІЖНИЙ МЕТОД ДЛЯ КОНВЕРТАЦІЇ ВАЛЮТ ---
  double _convertAmount(double amount, String fromCurrency, String toCurrency, List<dynamic>? rates) {
    if (fromCurrency == toCurrency || rates == null || rates.isEmpty) return amount;

    // 1. Переводимо в гривні
    double amountInUAH = amount;
    if (fromCurrency == '\$') {
      final usdRate = double.parse(rates.firstWhere((r) => r['ccy'] == 'USD')['buy']);
      amountInUAH = amount * usdRate;
    } else if (fromCurrency == '€') {
      final eurRate = double.parse(rates.firstWhere((r) => r['ccy'] == 'EUR')['buy']);
      amountInUAH = amount * eurRate;
    }

    // 2. Переводимо з гривень у цільову валюту
    if (toCurrency == '\$') {
      final usdSaleRate = double.parse(rates.firstWhere((r) => r['ccy'] == 'USD')['sale']);
      return amountInUAH / usdSaleRate;
    } else if (toCurrency == '€') {
      final eurSaleRate = double.parse(rates.firstWhere((r) => r['ccy'] == 'EUR')['sale']);
      return amountInUAH / eurSaleRate;
    }

    return amountInUAH;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналітика'),
        centerTitle: true,
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          return state.maybeWhen(
            loaded: (transactions, categories, totalBalance, currencyRates) {
              final cubit = context.read<TransactionCubit>();
              final currentDate = cubit.currentDate;
              final mainCurrency = cubit.mainCurrency; // Отримуємо поточну головну валюту

              // 1. Фільтруємо за типом (Витрата або Дохід)
              final targetType = _transactionType == TransactionType.expense ? 'expense' : 'income';
              final filteredTransactions = transactions.where((t) {
                final category = categories.firstWhere((c) => c.id == t.categoryId);
                return category.type == targetType;
              }).toList();

              // 2. Рахуємо суми (З КОНВЕРТАЦІЄЮ) та кольори для відображення
              Map<String, double> totals = {};
              Map<String, Color> categoryColors = {};
              double totalAmount = 0;

              for (var t in filteredTransactions) {
                final category = categories.firstWhere((c) => c.id == t.categoryId);
                
                // КОНВЕРТУЄМО СУМУ ТРАНЗАКЦІЇ
                double convertedAmount = _convertAmount(t.amount, t.currency, mainCurrency, currencyRates);

                totals[category.name] = (totals[category.name] ?? 0) + convertedAmount;
                categoryColors[category.name] = Color(int.parse(category.colorHex));
                totalAmount += convertedAmount;
              }

              return Column(
                children: [
                  _buildDateNavigation(context, cubit, currentDate),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: _buildSwitchers(),
                  ),
                  Expanded(
                    child: filteredTransactions.isEmpty
                        ? _buildEmptyState() 
                        : _buildContent(totals, categoryColors, totalAmount, filteredTransactions, currentDate, categories, mainCurrency, currencyRates),
                  ),
                ],
              );
            },
            orElse: () => const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildDateNavigation(BuildContext context, TransactionCubit cubit, DateTime date) {
    const months = ['Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень', 'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень'];
    final monthName = months[date.month - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left, size: 32), onPressed: () => cubit.changeMonth(-1)),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null && context.mounted) cubit.setMonth(picked);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text('$monthName ${date.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right, size: 32), onPressed: () => cubit.changeMonth(1)),
        ],
      ),
    );
  }

  Widget _buildSwitchers() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(value: TransactionType.expense, label: Text('Витрати')),
              ButtonSegment(value: TransactionType.income, label: Text('Доходи')),
            ],
            selected: {_transactionType},
            onSelectionChanged: (val) => setState(() => _transactionType = val.first),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ChartType>(
            segments: const [
              ButtonSegment(value: ChartType.pie, label: Text('Діаграма'), icon: Icon(Icons.pie_chart)),
              ButtonSegment(value: ChartType.bar, label: Text('Графік'), icon: Icon(Icons.bar_chart)),
            ],
            selected: {_chartType},
            onSelectionChanged: (val) => setState(() => _chartType = val.first),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset('assets/emptyStateDiagram.json', repeat: true, frameRate: FrameRate(30), height: 200),
        const SizedBox(height: 16),
        Text(
          _transactionType == TransactionType.expense ? 'Немає витрат для аналізу' : 'Немає доходів для аналізу',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildContent(Map<String, double> totals, Map<String, Color> categoryColors, double totalAmount, List filteredTransactions, DateTime currentDate, List categories, String mainCurrency, List<dynamic>? currencyRates) {
    return Column(
      children: [
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: _chartType == ChartType.pie
              ? _buildPieChart(totals, categoryColors, totalAmount)
              : _buildBarChart(filteredTransactions, currentDate, categories, categoryColors, mainCurrency, currencyRates), 
        ),
        const SizedBox(height: 24),
        
        Expanded(
          child: ListView.builder(
            itemCount: totals.length,
            itemBuilder: (context, index) {
              String categoryName = totals.keys.elementAt(index);
              double amount = totals.values.elementAt(index);
              Color color = categoryColors[categoryName]!;

              return ListTile(
                leading: CircleAvatar(backgroundColor: color, radius: 12),
                title: Text(categoryName),
                // Використовуємо mainCurrency замість жорстко прописаної гривні
                trailing: Text('${amount.toStringAsFixed(2)} $mainCurrency', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, double> totals, Map<String, Color> categoryColors, double totalAmount) {
    List<PieChartSectionData> sections = [];
    totals.forEach((name, amount) {
      final percent = (amount / totalAmount) * 100;
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

    return SizedBox(
      key: const ValueKey('pie_chart'),
      height: 250,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 50,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildBarChart(List filteredTransactions, DateTime currentDate, List categories, Map<String, Color> categoryColors, String mainCurrency, List<dynamic>? currencyRates) {
    Map<int, Map<String, double>> dailyCategoryTotals = {};

    for (var t in filteredTransactions) {
      final day = DateTime.fromMillisecondsSinceEpoch(t.timestamp).day;
      final category = categories.firstWhere((c) => c.id == t.categoryId);
      final catName = category.name;
      
      // КОНВЕРТУЄМО СУМУ ТРАНЗАКЦІЇ ДЛЯ СТОВПЧИКІВ ГРАФІКА
      double convertedAmount = _convertAmount(t.amount, t.currency, mainCurrency, currencyRates);

      if (dailyCategoryTotals[day] == null) dailyCategoryTotals[day] = {};
      dailyCategoryTotals[day]![catName] = (dailyCategoryTotals[day]![catName] ?? 0) + convertedAmount;
    }

    final daysInMonth = DateTime(currentDate.year, currentDate.month + 1, 0).day;

    return Container(
      key: const ValueKey('bar_chart'),
      height: 250,
      padding: const EdgeInsets.only(top: 20, right: 16, left: 16),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36, 
                getTitlesWidget: (value, meta) {
                  bool isShow = false;
                  if (value == 1 || value == daysInMonth) {
                    isShow = true; 
                  } else if (value % 5 == 0 && (daysInMonth - value) > 2) {
                    isShow = true; 
                  }

                  if (isShow) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        value.toInt().toString(), 
                        style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(daysInMonth, (i) {
            int day = i + 1;
            final dayTotals = dailyCategoryTotals[day] ?? {};
            
            List<BarChartRodStackItem> stackItems = [];
            double currentY = 0;
            
            dayTotals.forEach((catName, amount) {
              final color = categoryColors[catName] ?? Colors.grey;
              stackItems.add(BarChartRodStackItem(currentY, currentY + amount, color));
              currentY += amount;
            });

            return BarChartGroupData(
              x: day,
              barRods: [
                BarChartRodData(
                  toY: currentY, 
                  width: 12, 
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  rodStackItems: stackItems, 
                  color: Colors.transparent, 
                )
              ],
            );
          }),
        ),
      ),
    );
  }
}