import 'package:flutter/material.dart';
import 'package:flutter_cursova/app/di/service_locator.dart' as di;

import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ініціалізація залежностей
  await di.init();
  
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Поки що залишимо Scaffold тут, поки не створимо Home Page
      home: const Scaffold(
        body: Center(child: Text('Структура Dudka-style готова!')),
      ),
    );
  }
}