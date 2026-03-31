import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/category_model.dart';
import '../cubit/transaction_cubit.dart';
import '../cubit/transaction_state.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категорії'),
        centerTitle: true,
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          return state.maybeWhen(
            loaded: (_, categories, __, ___) {
              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Dismissible(
                    key: Key(category.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    // Захист від випадкового видалення
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Видалити категорію?'),
                          content: const Text('Увага: це видалить усі транзакції, пов\'язані з цією категорією!'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Видалити', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) {
                      context.read<TransactionCubit>().deleteCategory(category.id!);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Категорію видалено')));
                    },
                    child: ListTile(
                      // ДОДАЛИ ЦЕЙ РЯДОК:
                      onTap: () => _showAddCategorySheet(context, category),
                      
                      leading: CircleAvatar(
                        backgroundColor: Color(int.parse(category.colorHex)),
                        child: Icon(IconData(category.iconCode, fontFamily: 'MaterialIcons'), color: Colors.white),
                      ),
                      title: Text(category.name),
                      subtitle: Text(category.type == 'income' ? 'Дохід' : 'Витрата'),
                    ),
                  );
                },
              );
            },
            orElse: () => const Center(child: CircularProgressIndicator()),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategorySheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Виклик нижньої панелі для створення категорії
// Виклик нижньої панелі для створення АБО редагування категорії
  void _showAddCategorySheet(BuildContext context, [CategoryModel? categoryToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<TransactionCubit>(),
        child: AddCategoryForm(categoryToEdit: categoryToEdit),
      ),
    );
  }
}

// --- Віджет форми створення категорії ---
class AddCategoryForm extends StatefulWidget {
  final CategoryModel? categoryToEdit; // Додаємо змінну
  
  const AddCategoryForm({super.key, this.categoryToEdit});

  @override
  State<AddCategoryForm> createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends State<AddCategoryForm> {
  late final TextEditingController _nameController;
  late String _type;
  late Color _selectedColor;
  late IconData _selectedIcon;

  final List<Color> _colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.brown, Colors.pink];
  final List<IconData> _icons = [Icons.shopping_cart, Icons.fastfood, Icons.directions_car, Icons.home, Icons.flight, Icons.medical_services, Icons.work, Icons.attach_money, Icons.pets, Icons.school];

  @override
  void initState() {
    super.initState();
    final c = widget.categoryToEdit;
    
    // Якщо це редагування - підставляємо старі дані, інакше - стандартні
    _nameController = TextEditingController(text: c?.name ?? '');
    _type = c?.type ?? 'expense';
    
    if (c != null) {
      // Шукаємо колір та іконку в наших списках, щоб вони коректно виділялися
      _selectedColor = _colors.firstWhere(
        (color) => color.toARGB32() == Color(int.parse(c.colorHex)).toARGB32(), 
        orElse: () => Color(int.parse(c.colorHex))
      );
      _selectedIcon = _icons.firstWhere(
        (icon) => icon.codePoint == c.iconCode, 
        orElse: () => IconData(c.iconCode, fontFamily: 'MaterialIcons')
      );
    } else {
      _selectedColor = Colors.blue;
      _selectedIcon = Icons.shopping_cart;
    }
  }

  void _saveCategory() {
    if (_nameController.text.isEmpty) return;

    final isEditing = widget.categoryToEdit != null;

    final newCategory = CategoryModel(
      id: isEditing ? widget.categoryToEdit!.id : null,
      name: _nameController.text,
      iconCode: _selectedIcon.codePoint,
      colorHex: '0x${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
      type: _type,
    );

    if (isEditing) {
      context.read<TransactionCubit>().updateCategory(newCategory);
    } else {
      context.read<TransactionCubit>().addCategory(newCategory);
    }
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding для того, щоб клавіатура не перекривала форму
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Нова категорія', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Вибір: Дохід чи Витрата
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('Витрата')),
              ButtonSegment(value: 'income', label: Text('Дохід')),
            ],
            selected: {_type},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _type = newSelection.first);
            },
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Назва категорії', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          
          // Вибір кольору
          const Text('Колір:'),
          Wrap(
            spacing: 8,
            children: _colors.map((c) => GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: CircleAvatar(
                backgroundColor: c,
                radius: 16,
                child: _selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          
          // Вибір іконки
          const Text('Іконка:'),
          Wrap(
            spacing: 8,
            children: _icons.map((icon) => GestureDetector(
              onTap: () => setState(() => _selectedIcon = icon),
              child: CircleAvatar(
                backgroundColor: _selectedIcon == icon ? Colors.grey[300] : Colors.transparent,
                child: Icon(icon, color: Colors.black87),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveCategory,
              child: const Text('Зберегти категорію'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}