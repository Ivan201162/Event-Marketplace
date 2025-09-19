import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран управления отзывами в админ-панели
class AdminReviewsScreen extends ConsumerWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Модерация отзывов',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Функция будет реализована в следующих версиях',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
}
