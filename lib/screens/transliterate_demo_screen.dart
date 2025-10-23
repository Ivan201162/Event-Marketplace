import 'package:flutter/material.dart';
import '../utils/transliterate.dart';

/// Демонстрационный экран для тестирования транслитерации
class TransliterateDemoScreen extends StatefulWidget {
  const TransliterateDemoScreen({super.key});

  @override
  State<TransliterateDemoScreen> createState() =>
      _TransliterateDemoScreenState();
}

class _TransliterateDemoScreenState extends State<TransliterateDemoScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _generatedUsername = '';
  final List<String> _examples = [
    'Иван Иванов',
    'Анна-Мария Петрова',
    'Джон Доу',
    'Александр Смирнов',
    'Екатерина Волкова',
    'Михаил Козлов',
    'Ольга Новикова',
    'Сергей Морозов',
    'Татьяна Лебедева',
    'Андрей Соколов',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _generateUsername() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        _generatedUsername =
            TransliterateUtils.transliterateNameToUsername(name);
      });
    }
  }

  void _generateFromExample(String example) {
    _nameController.text = example;
    setState(() {
      _generatedUsername =
          TransliterateUtils.transliterateNameToUsername(example);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Демо транслитерации'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Генератор username',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Введите полное имя',
                          hintText: 'Иван Иванов',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        onSubmitted: (_) => _generateUsername(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generateUsername,
                          icon: const Icon(Icons.auto_fix_high),
                          label: const Text('Сгенерировать username'),
                        ),
                      ),
                      if (_generatedUsername.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Результат:',
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 4),
                              Text(
                                '@$_generatedUsername',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Примеры транслитерации:',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              ..._examples.map(
                (example) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(example),
                    subtitle: Text(
                        '@${TransliterateUtils.transliterateNameToUsername(example)}'),
                    trailing: const Icon(Icons.copy),
                    onTap: () => _generateFromExample(example),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Как это работает:',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text(
                        '• Кириллические буквы транслитерируются в латиницу\n'
                        '• Пробелы и дефисы заменяются на подчеркивания\n'
                        '• Удаляются все специальные символы\n'
                        '• Добавляется случайный 4-значный суффикс\n'
                        '• Username ограничивается 15 символами + суффикс',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
