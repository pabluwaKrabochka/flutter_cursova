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
  
  // Логіка валют
final Map<String, String> _currencyData = {
  '₴': 'Гривня',
  '\$': 'Долар',
  '€': 'Євро',
};
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _loadDefaultCurrency();
    final t = widget.transactionToEdit;
    _amountController = TextEditingController(text: t != null ? t.amount.toString() : '');
    _noteController = TextEditingController(text: t?.note ?? '');
    
    // Встановлюємо валюту: або з транзакції, або стандартну
    _selectedCurrency = t?.currency ?? '₴';

    if (t != null) {
      _selectedCategory = widget.categories.firstWhere((c) => c.id == t.categoryId);
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
    // Якщо це нова транзакція - беремо з налаштувань, якщо редагування - з транзакції
    _selectedCurrency = widget.transactionToEdit?.currency ?? 
                       prefs.getString('user_currency') ?? '₴';
  });
}

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final isEditing = widget.transactionToEdit != null;
      
      final transaction = TransactionModel(
        id: isEditing ? widget.transactionToEdit!.id : null,
        amount: double.parse(_amountController.text),
        timestamp: isEditing ? widget.transactionToEdit!.timestamp : DateTime.now().millisecondsSinceEpoch,
        categoryId: _selectedCategory!.id!,
        currency: _selectedCurrency, // ПЕРЕДАЄМО ОБРАНУ ВАЛЮТУ
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
        title: Text(widget.transactionToEdit == null ? 'Нова транзакція' : 'Редагувати'),
      ),
      body: Padding(
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
                    flex: 3,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Сума',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введіть суму';
                        if (double.tryParse(value) == null) return 'Некоректне число';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Валюта',
                        border: OutlineInputBorder(),
                      ),
                  items: _currencyData.entries.map((entry) {
  return DropdownMenuItem(
    value: entry.key,
    child: Text('${entry.key} - ${entry.value}'), // Виведе: ₴ - Гривня
  );
}).toList(),
                      onChanged: (val) => setState(() => _selectedCurrency = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
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
                          IconData(category.iconCode, fontFamily: 'MaterialIcons'), 
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
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _saveTransaction,
                child: const Text('Зберегти', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}