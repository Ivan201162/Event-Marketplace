import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Поиск специалистов"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Поисковая строка
            TextField(
              decoration: InputDecoration(
                hintText: "Поиск специалистов...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Фильтры
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Категория",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "all", child: Text("Все категории")),
                      DropdownMenuItem(value: "photographer", child: Text("Фотографы")),
                      DropdownMenuItem(value: "dj", child: Text("DJ")),
                      DropdownMenuItem(value: "host", child: Text("Ведущие")),
                      DropdownMenuItem(value: "decorator", child: Text("Декораторы")),
                    ],
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Город",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "all", child: Text("Все города")),
                      DropdownMenuItem(value: "moscow", child: Text("Москва")),
                      DropdownMenuItem(value: "spb", child: Text("Санкт-Петербург")),
                      DropdownMenuItem(value: "kazan", child: Text("Казань")),
                    ],
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Результаты поиска
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Заглушка
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text("${index + 1}"),
                      ),
                      title: Text("Специалист ${index + 1}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Фотограф • Москва"),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              const Text("4.8"),
                              const SizedBox(width: 16),
                              const Icon(Icons.attach_money, color: Colors.green, size: 16),
                              const SizedBox(width: 4),
                              const Text("от 15 000 ₽"),
                            ],
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Выбрать специалиста ${index + 1}")),
                          );
                        },
                        child: const Text("Выбрать"),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
