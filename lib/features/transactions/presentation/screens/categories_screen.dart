import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Видалити категорію?'),
                          content: const Text('Це видалить усі транзакції в цій категорії!'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true), 
                              child: const Text('Видалити', style: TextStyle(color: Colors.red))
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) => context.read<TransactionCubit>().deleteCategory(category.id!),
                    child: ListTile(
                      onTap: () => _showAddCategorySheet(context, category),
                      leading: CircleAvatar(
                        backgroundColor: Color(int.parse(category.colorHex)),
                        child: Icon(
                          IconData(category.iconCode, fontFamily: 'MaterialIcons'), 
                          color: Colors.white
                        ),
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

  void _showAddCategorySheet(BuildContext context, [CategoryModel? categoryToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(
        value: context.read<TransactionCubit>(),
        child: AddCategoryForm(categoryToEdit: categoryToEdit),
      ),
    );
  }
}

class AddCategoryForm extends StatefulWidget {
  final CategoryModel? categoryToEdit;
  const AddCategoryForm({super.key, this.categoryToEdit});

  @override
  State<AddCategoryForm> createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends State<AddCategoryForm> {
  late final TextEditingController _nameController;
  late String _type;
  late Color _selectedColor;
  IconData? _selectedIcon;

  // --- СПИСОК ІКОНОК ІЗ КЛЮЧОВИМИ СЛОВАМИ ДЛЯ ПОШУКУ ---
  final Map<IconData, String> _availableIcons = {
    // ЇЖА ТА ПРОДУКТИ
    Icons.shopping_cart: "магазин продукти покупки shopping shop візок",
    Icons.shopping_basket: "кошик покупки продукти basket",
    Icons.fastfood: "їжа продукти ресторан кафе food burger бургер",
    Icons.restaurant: "їжа обід ресторан вечеря кафе restaurant",
    Icons.coffee: "кава чай напої кафе coffee tea",
    Icons.icecream: "морозиво солодощі десерт sweets",
    Icons.liquor: "алкоголь бар вечірка drinks",

    // ТРАНСПОРТ
    Icons.directions_car: "авто машина транспорт таксі car taxi автомобіль",
    Icons.directions_bus: "автобус маршрутка громадський транспорт bus",
    Icons.train: "поїзд квитки залізниця train",
    Icons.local_gas_station: "паливо бензин заправка gas fuel азс",
    Icons.handyman: "ремонт авто сервіс майстер",
    Icons.flight: "подорожі літак відпустка travel flight",

    // ЖИТЛО ТА КОМУНАЛКА
    Icons.home: "дім оренда житло квартира home house будинок",
    Icons.electric_bolt: "електрика світло комуналка electricity",
    Icons.water_drop: "вода комуналка оренду water",
    Icons.cleaning_services: "прибирання хімчистка засіб cleaning",
    Icons.chair: "меблі інтер'єр дім furniture",
    Icons.wifi: "інтернет зв'язок телефон internet вайфай",

    // ЗДОРОВ'Я ТА ДОГЛЯД
    Icons.medical_services: "ліки аптека здоров'я лікар hospital health медицина",
    Icons.medication: "пігулки вітаміни аптека",
    Icons.fitness_center: "спорт зал тренування фітнес gym спортзал",
    Icons.spa: "краса спа манікюр парикмахер barber beauty",
    Icons.health_and_safety_outlined: "гігієна стоматолог косметика",

    // ВІДПОЧИНОК ТА ХОБІ
    Icons.movie: "кіно розваги фільми театр cinema фільм",
    Icons.theater_comedy: "театр вистава культура",
    Icons.sports_esports: "ігри розваги дозвілля games іграшки",
    Icons.music_note: "музика концерт підписка music",
    Icons.camera_alt: "фото техніка хобі photo",
    Icons.brush: "мистецтво малювання творчість art",
    Icons.pets: "тварини собака кіт pets домашні",

    // ОСВІТА ТА РОБОТА
    Icons.school: "навчання школа університет курси education навчання",
    Icons.menu_book: "книги література саморозвиток books",
    Icons.work: "офіс робота кар'єра office",
    Icons.laptop_mac: "техніка комп'ютер гаджети laptop",

    // ФІНАНСИ ТА ДОХОДИ
    Icons.payments: "зарплата гроші дохід кошти money salary гроші",
    Icons.account_balance_wallet: "гаманець гроші витрати wallet",
    Icons.savings: "копилка заощадження інвестиції savings",
    Icons.trending_up: "акції інвестиції ріст profit",
    Icons.credit_card: "банківська карта банк рахунок card",
    Icons.receipt_long: "податки чеки квитанції tax",

    // СІМ'Я ТА ПОДАРУНКИ
    Icons.stroller: "діти дитина садок baby child",
    Icons.toys: "іграшки дитяче хобі toys",
    Icons.card_giftcard: "подарунок свято день народження gift презент",
    Icons.volunteer_activism: "благодійність допомога донат charity",

    // ІНШЕ
    Icons.subscriptions: "підписки сервіси youtube netflix підписка",
    Icons.umbrella: "страховка захист негода insurance",
    Icons.local_shipping: "доставка пошта кур'єр delivery",
    Icons.build: "ремонт інструменти інструменти",
    Icons.local_pizza_sharp: "pizza піцца піца їжа няма food fastfood фастфуд",
  };

  @override
  void initState() {
    super.initState();
    final c = widget.categoryToEdit;
    _nameController = TextEditingController(text: c?.name ?? '');
    _type = c?.type ?? 'expense';
    _selectedColor = c != null ? Color(int.parse(c.colorHex)) : Colors.blue;
    _selectedIcon = c != null ? IconData(c.iconCode, fontFamily: 'MaterialIcons') : Icons.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- ВЛАСНИЙ ПІКЕР ІКОНОК (ВАРІАНТ 1) ---
void _pickIcon() {
    String searchQuery = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredIcons = _availableIcons.entries.where((entry) {
              if (searchQuery.isEmpty) return true;
              return entry.value.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Оберіть іконку',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Наприклад: їжа, гроші, car...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setModalState(() => searchQuery = ""),
                          )
                        : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (val) => setModalState(() => searchQuery = val),
                  ),
                  const SizedBox(height: 16),

                  // Збільшено висоту з 250 до 350, бо іконок тепер багато
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4, 
                    ),
                    child: filteredIcons.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Text('Нічого не знайдено'),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                            itemCount: filteredIcons.length,
                            itemBuilder: (context, index) {
                              final iconData = filteredIcons[index].key;
                              final isSelected = _selectedIcon == iconData;
                              return InkWell(
                                onTap: () {
                                  setState(() => _selectedIcon = iconData);
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue.withAlpha(22) : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(iconData, size: 30, color: isSelected ? Colors.blue : Colors.black87),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Колір категорії'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
            enableAlpha: true,
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Готово'))],
      ),
    );
  }

  void _saveCategory() {
    if (_nameController.text.isEmpty || _selectedIcon == null) return;
    final isEditing = widget.categoryToEdit != null;
    final newCategory = CategoryModel(
      id: isEditing ? widget.categoryToEdit!.id : null,
      name: _nameController.text,
      iconCode: _selectedIcon!.codePoint,
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Налаштування категорії', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('Витрата'), icon: Icon(Icons.remove_circle_outline)),
              ButtonSegment(value: 'income', label: Text('Дохід'), icon: Icon(Icons.add_circle_outline)),
            ],
            selected: {_type},
            onSelectionChanged: (val) => setState(() => _type = val.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Назва', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickColor,
                  icon: CircleAvatar(backgroundColor: _selectedColor, radius: 10),
                  label: const Text('Колір'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickIcon,
                  icon: Icon(_selectedIcon),
                  label: const Text('Іконка'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                foregroundColor: useWhiteForeground(_selectedColor) ? Colors.white : Colors.black,
              ),
              onPressed: _saveCategory,
              child: const Text('Зберегти'),
            ),
          ),
        ],
      ),
    );
  }
}