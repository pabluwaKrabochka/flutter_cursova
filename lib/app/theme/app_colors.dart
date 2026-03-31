import 'package:flutter/material.dart';

class AppColors {
  // Основний колір (бірюзово-синій) - використовується для кнопок, заголовків
  static const Color primary = Color(0xFF1976D2);
  // Світлий відтінок основного кольору (для фону слайдів привітання)
  static const Color primaryLight = Color(0xFFE3F2FD);
  // Колір акценту (наприклад, для індикаторів)
  static const Color accent = Color(0xFFFDD835);

  // Стандартні кольори
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  
  // Кольори для транзакцій (не забудь поправити їх у DatabaseService пізніше)
  static const Color income = Color(0xFF66BB6A);
  static const Color expense = Color(0xFFEF5350);

  static const Color background = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF212121);
}