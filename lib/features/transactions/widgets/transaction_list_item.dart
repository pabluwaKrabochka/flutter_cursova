// ФАЙЛ: transaction_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cursova/data/models/category_model.dart';
import 'package:flutter_cursova/data/models/transaction_model.dart';
import 'package:flutter_cursova/features/transactions/presentation/cubit/transaction_cubit.dart';
import 'package:flutter_cursova/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:intl/intl.dart';



class TransactionListItem extends StatefulWidget {
  final TransactionModel transaction;
  final CategoryModel category;
  final List<CategoryModel> allCategories;
  final bool isIncome;

  const TransactionListItem({
    super.key, 
    required this.transaction, 
    required this.category, 
    required this.allCategories, 
    required this.isIncome
  });

  @override
  State<TransactionListItem> createState() => _TransactionListItemState();
}

class _TransactionListItemState extends State<TransactionListItem> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant TransactionListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transaction.id != oldWidget.transaction.id) {
      _isExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNote = widget.transaction.note != null && widget.transaction.note!.trim().isNotEmpty;
    final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(widget.transaction.timestamp));
    
    return Dismissible(
      key: Key(widget.transaction.id.toString()),
      direction: DismissDirection.endToStart,
      // ВІДНОВЛЕНО ВІКНО ПІДТВЕРДЖЕННЯ
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Підтвердження"),
            content: const Text("Ви впевнені, що хочете видалити цю транзакцію?"),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Скасувати")),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Видалити", style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) => context.read<TransactionCubit>().deleteTransaction(widget.transaction.id!),
      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(backgroundColor: Color(int.parse(widget.category.colorHex)), child: Icon(IconData(widget.category.iconCode, fontFamily: 'MaterialIcons'), color: Colors.white)),
            title: Text(widget.category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(formattedDate),
            trailing: Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.grey, size: 20), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(value: context.read<TransactionCubit>(), child: AddTransactionScreen(categories: widget.allCategories, transactionToEdit: widget.transaction))))),
                Text('${widget.isIncome ? '+' : '-'}${widget.transaction.amount.toStringAsFixed(2)} ${widget.transaction.currency}', style: TextStyle(color: widget.isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                if (hasNote) IconButton(icon: Icon(_isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, color: Colors.grey), onPressed: () => setState(() => _isExpanded = !_isExpanded)),
              ]
            )
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0, width: double.infinity),
            secondChild: Container(width: double.infinity, padding: const EdgeInsets.only(left: 72, right: 16, bottom: 12), child: Text('Примітка: ${widget.transaction.note}', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
            crossFadeState: _isExpanded && hasNote ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}