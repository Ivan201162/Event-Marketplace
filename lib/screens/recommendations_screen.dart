import 'package:flutter/material.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Рекомендации'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.recommend, size: 80, color: Colors.blue),
          SizedBox(height: 16),
          Text('Рекомендации', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            'Здесь будут отображаться персональные рекомендации специалистов',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}
