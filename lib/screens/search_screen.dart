import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Экран поиска специалистов
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Все';
  double _priceRange = 5000;
  // final double _ratingFilter = 4; // Unused field

  final List<String> _categories = [
    'Все',
    'Фотографы',
    'Видеографы',
    'Организаторы',
    'Декораторы',
    'Музыканты',
  ];

  final List<Map<String, dynamic>> _specialists = [
    {
      'name': 'Анна Петрова',
      'category': 'Фотограф',
      'rating': 4.9,
      'price': 3000,
      'avatar': 'https://placehold.co/100x100/4CAF50/white?text=AP',
      'isVerified': true,
    },
    {
      'name': 'Михаил Соколов',
      'category': 'Видеограф',
      'rating': 4.8,
      'price': 5000,
      'avatar': 'https://placehold.co/100x100/2196F3/white?text=MS',
      'isVerified': true,
    },
    {
      'name': 'Елена Козлова',
      'category': 'Организатор',
      'rating': 4.7,
      'price': 2500,
      'avatar': 'https://placehold.co/100x100/FF9800/white?text=EK',
      'isVerified': false,
    },
    {
      'name': 'Дмитрий Волков',
      'category': 'Декоратор',
      'rating': 4.6,
      'price': 2000,
      'avatar': 'https://placehold.co/100x100/9C27B0/white?text=DV',
      'isVerified': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Поисковая строка
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Найдите идеального специалиста',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Поисковая строка
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск по имени или специализации...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 16),

                  // Фильтры
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Категория',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          items: _categories
                              .map(
                                (category) => DropdownMenuItem(
                                    value: category, child: Text(category),),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Макс. цена: ${_priceRange.toInt()}₽',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Slider(
                              value: _priceRange,
                              min: 1000,
                              max: 10000,
                              divisions: 18,
                              onChanged: (value) {
                                setState(() {
                                  _priceRange = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Список специалистов
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final specialist = _specialists[index];
                return _buildSpecialistCard(specialist, theme);
              }, childCount: _specialists.length,),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistCard(
          Map<String, dynamic> specialist, ThemeData theme,) =>
      Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        child: InkWell(
          onTap: () {
            _showSpecialistDetails(specialist);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Аватар
                Stack(
                  children: [
                    CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(specialist['avatar']),),
                    if (specialist['isVerified'])
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.verified,
                              color: Colors.white, size: 16,),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialist['name'],
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialist['category'],
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(specialist['rating'].toString(),
                              style: theme.textTheme.bodyMedium,),
                          const SizedBox(width: 16),
                          Text(
                            '${specialist['price']}₽/час',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Кнопка действия
                IconButton(
                  onPressed: () {
                    context.push(
                      '/specialist/${specialist['name'].toLowerCase().replaceAll(' ', '_')}',
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
          ),
        ),
      );

  void _showSpecialistDetails(Map<String, dynamic> specialist) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(specialist['avatar']),),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          specialist['name'],
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          specialist['category'],
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Действия
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(
                            content: Text('Заявка отправлена!'),),);
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Отправить заявку'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                            const SnackBar(content: Text('Чат открыт!')),);
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Написать'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
