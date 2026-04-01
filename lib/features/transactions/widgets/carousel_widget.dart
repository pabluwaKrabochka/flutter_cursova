// ФАЙЛ: promo_carousel.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_cursova/core/constants/home_constants.dart';

class PromoCarousel extends StatefulWidget {
  final List<dynamic>? currencyRates;
  const PromoCarousel({super.key, this.currencyRates});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  int _currentIndex = 0;

  void _showBannerDetails(Map<String, dynamic> banner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Для гарних кутів і відступів
      builder: (context) {
        // Отримуємо висоту екрану для розрахунку розміру картинки
        final screenHeight = MediaQuery.of(context).size.height;
        
        return Container(
          // Максимальна висота вікна - 85% від екрану, щоб не перекривати статус-бар
          constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Вікно займе мінімально необхідну висоту
            children: [
              // Handle (сіра смужка для закриття свайпом)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              
              // Основний контент із прокруткою
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(), // Плавна анімація прокрутки
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Велика картинка (завжди займає 25% від висоти екрану)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          banner["image"],
                          height: screenHeight * 0.22,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: screenHeight * 0.25,
                            color: Colors.grey[200],
                            child: const Center(child: Text("Банер відсутній")),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Назва
                      Text(
                        banner["title"],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5, // Трохи розрядив текст для кращого вигляду
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Опис
                      Text(
                        banner["description"],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.6, // Міжрядковий інтервал для зручності читання
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double carouselHeight = MediaQuery.of(context).size.height * 0.22;

    final List<Widget> items = [
      _buildRatesTable(widget.currencyRates),
      ...HomeConstants.banners.map((b) => _buildClickableBanner(b)),
    ];

    return Column(
      children: [
        CarouselSlider(
          items: items,
          options: CarouselOptions(
            height: carouselHeight,
            viewportFraction: 0.93,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 6),
            enlargeCenterPage: true,
            onPageChanged: (index, reason) => setState(() => _currentIndex = index),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: items.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentIndex == entry.key ? 22.0 : 7.0, height: 7.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentIndex == entry.key ? Colors.blue : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildClickableBanner(Map<String, dynamic> banner) {
    return GestureDetector(
      onTap: () => _showBannerDetails(banner),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            // Легка тінь під самими банерами в каруселі
            BoxShadow(
              color: Colors.black.withAlpha(11),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            banner["image"],
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.fill,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Center(child: Text("Банер відсутній")),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatesTable(List<dynamic>? rates) {
    if (rates == null || rates.isEmpty) {
      return Container(
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Валюта', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Text('Купівля', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Text('Продаж', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const Divider(),
          ...rates.where((e) => e['ccy'] == 'USD' || e['ccy'] == 'EUR').map((rate) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${rate['ccy']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${double.parse(rate['buy']).toStringAsFixed(2)} ₴', style: const TextStyle(fontSize: 16)),
                Text('${double.parse(rate['sale']).toStringAsFixed(2)} ₴', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}