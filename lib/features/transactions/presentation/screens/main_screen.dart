import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cursova/features/transactions/presentation/screens/categories_screen.dart';
import '../../../../app/di/service_locator.dart';
import '../cubit/transaction_cubit.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Список наших екранів
 final List<Widget> _screens = [
    const HomeScreen(),
    const AnalyticsScreen(),
    const CategoriesScreen(), // ДОДАЛИ СЮДИ
  ];

  @override
  Widget build(BuildContext context) {
    // Піднімаємо BlocProvider сюди, щоб і Транзакції, і Аналітика мали доступ до одних даних
    return BlocProvider(
      create: (context) => sl<TransactionCubit>()..loadData(),
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
         destinations: const [
            NavigationDestination(
              icon: Icon(Icons.list_alt),
              label: 'Транзакції',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart),
              label: 'Аналітика',
            ),
            NavigationDestination(
              icon: Icon(Icons.category),
              label: 'Категорії',
            ),
          ],
        ),
      ),
    );
  }
}