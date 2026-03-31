import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/transaction_model.dart';
import '../cubit/transaction_cubit.dart';

class AddTransactionScreen extends StatefulWidget {
  final List<CategoryModel> categories;
  final TransactionModel? transactionToEdit;

  const AddTransactionScreen({
    super.key,
    required this.categories,
    this.transactionToEdit,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  CategoryModel? _selectedCategory;

  final Map<String, String> _currencyData = {
    '₴': 'Гривня',
    '\$': 'Долар',
    '€': 'Євро',
  };
  late String _selectedCurrency;

  // Список швидких сум
  final List<double> _quickAmounts = [5, 10, 25, 50, 100, 1000, 10000, 100000];

  @override
  void initState() {
    super.initState();
    _loadDefaultCurrency();
    final t = widget.transactionToEdit;
    _amountController = TextEditingController(
        text: t != null ? t.amount.toString() : '');
    _noteController = TextEditingController(text: t?.note ?? '');

    _selectedCurrency = t?.currency ?? '₴';

    if (t != null) {
      _selectedCategory =
          widget.categories.firstWhere((c) => c.id == t.categoryId);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = widget.transactionToEdit?.currency ??
          prefs.getString('user_currency') ??
          '₴';
    });
  }

  // Метод для додавання суми
  void _addAmount(double value) {
    double current = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      _amountController.text = (current + value).toStringAsFixed(0);
    });
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Будь ласка, оберіть категорію')),
        );
        return;
      }

      final isEditing = widget.transactionToEdit != null;

      final transaction = TransactionModel(
        id: isEditing ? widget.transactionToEdit!.id : null,
        amount: double.parse(_amountController.text),
        timestamp: isEditing
            ? widget.transactionToEdit!.timestamp
            : DateTime.now().millisecondsSinceEpoch,
        categoryId: _selectedCategory!.id!,
        currency: _selectedCurrency,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      if (isEditing) {
        context.read<TransactionCubit>().updateTransaction(transaction);
      } else {
        context.read<TransactionCubit>().addTransaction(transaction);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionToEdit == null
            ? 'Нова транзакція'
            : 'Редагувати'),
      ),
      body: SingleChildScrollView( // Додано для запобігання переповненню при відкритті клавіатури
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Рядок: Сума + Вибір валюти
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Сума',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.numbers),
                        suffixIcon: _amountController.text.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _amountController.clear()),
                            ) 
                          : null,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введіть суму';
                        if (double.tryParse(value) == null) return 'Некоректне число';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 85,
                    child: PopupMenuButton<String>(
                      position: PopupMenuPosition.under,
                      initialValue: _selectedCurrency,
                      onSelected: (val) => setState(() => _selectedCurrency = val),
                      itemBuilder: (context) => _currencyData.entries.map((entry) {
                        return PopupMenuItem<String>(
                          value: entry.key,
                          child: Text('${entry.key} - ${entry.value}'),
                        );
                      }).toList(),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Валюта',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedCurrency,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Блок швидкого вибору сум
              Wrap(
                spacing: 8,
                runSpacing: 0,
                children: _quickAmounts.map((amount) {
                  return ActionChip(
                    avatar: const Icon(Icons.add, size: 14),
                    label: Text(amount >= 1000 
                        ? '${(amount / 1000).toStringAsFixed(0)}k' 
                        : amount.toStringAsFixed(0)),
                    onPressed: () => _addAmount(amount),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(66),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),

              DropdownButtonFormField<CategoryModel>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категорія',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: widget.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          IconData(category.iconCode,
                              fontFamily: 'MaterialIcons'),
                          color: Color(int.parse(category.colorHex)),
                        ),
                        const SizedBox(width: 8),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Оберіть категорію' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Примітка',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveTransaction,
                child: const Text('Зберегти', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}