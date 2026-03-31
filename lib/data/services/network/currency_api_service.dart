import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CurrencyApiService {
  // Використовуємо публічне API ПриватБанку
  Future<List<dynamic>> getPrivatRates() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.privatbank.ua/p24api/pubinfo?json&exchange&coursid=5'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body); // Повертає список валют з buy та sale
      }
    } catch (e) {
      debugPrint('Помилка API: $e');
    }
    return [];
  }
}