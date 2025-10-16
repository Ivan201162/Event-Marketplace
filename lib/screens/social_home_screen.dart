import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialHomeScreen extends ConsumerStatefulWidget {
  const SocialHomeScreen({super.key});

  @override
  ConsumerState<SocialHomeScreen> createState() => _SocialHomeScreenState();
}

class _SocialHomeScreenState extends ConsumerState<SocialHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showProfileCard = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    const threshold = 100.0;

    if (currentOffset > _lastScrollOffset && currentOffset > threshold) {
      // Скролл вниз - скрываем плашку профиля
      if (_showProfileCard) {
        setState(() {
          _showProfileCard = false;
        });
      }
    } else if (currentOffset < _lastScrollOffset ||
        currentOffset <= threshold) {
      // Скролл вверх - показываем плашку профиля
      if (!_showProfileCard) {
        setState(() {
          _showProfileCard = true;
        });
      }
    }

    _lastScrollOffset = currentOffset;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Плашка профиля пользователя
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showProfileCard ? null : 0,
                child: _showProfileCard
                    ? _buildProfileCard(theme)
                    : const SizedBox.shrink(),
              ),
            ),

            // Блок поиска и фильтров
            SliverToBoxAdapter(
              child: _buildSearchSection(theme),
            ),

            // Лучшие специалисты недели
            SliverToBoxAdapter(
              child: _buildTopSpecialistsSection(
                  theme, 'Лучшие специалисты недели по России'),
            ),

            // Лучшие специалисты по городу
            SliverToBoxAdapter(
              child: _buildTopSpecialistsSection(
                  theme, 'Лучшие специалисты по вашему городу'),
            ),

            // Дополнительный контент
            SliverToBoxAdapter(
              child: _buildAdditionalContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Аватар
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),

          // Информация о пользователе
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Александр Иванов',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Москва',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Онлайн',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Счётчик подписчиков
          Column(
            children: [
              Text(
                '1.2K',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              Text(
                'подписчиков',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Найти специалиста',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Поле поиска
          TextField(
            decoration: InputDecoration(
              hintText: 'Поиск по имени, специализации...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
            ),
          ),
          const SizedBox(height: 12),

          // Фильтры
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(theme, 'Москва', Icons.location_on),
              _buildFilterChip(theme, 'Фотограф', Icons.camera_alt),
              _buildFilterChip(theme, 'До 10 000₽', Icons.attach_money),
              _buildFilterChip(theme, 'Профи', Icons.star),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label, IconData icon) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        // Обработка выбора фильтра
      },
      selected: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      selectedColor: theme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: theme.primaryColor,
    );
  }

  Widget _buildTopSpecialistsSection(ThemeData theme, String title) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Переход к полному списку
                },
                child: Text(
                  'Все',
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Горизонтальный список специалистов
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildSpecialistCard(theme, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistCard(ThemeData theme, int index) {
    final specialists = [
      {
        'name': 'Анна Петрова',
        'specialty': 'Фотограф',
        'rating': 4.9,
        'price': '5000₽'
      },
      {
        'name': 'Михаил Сидоров',
        'specialty': 'Видеограф',
        'rating': 4.8,
        'price': '8000₽'
      },
      {
        'name': 'Елена Козлова',
        'specialty': 'Организатор',
        'rating': 4.9,
        'price': '12000₽'
      },
      {
        'name': 'Дмитрий Волков',
        'specialty': 'Диджей',
        'rating': 4.7,
        'price': '15000₽'
      },
      {
        'name': 'Ольга Морозова',
        'specialty': 'Декоратор',
        'rating': 4.8,
        'price': '6000₽'
      },
    ];

    final specialist = specialists[index];

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Аватар специалиста
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.person,
                size: 40,
                color: theme.primaryColor,
              ),
            ),
          ),

          // Информация о специалисте
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  specialist['name'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  specialist['specialty'] as String,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      specialist['rating'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  specialist['price'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalContent(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Популярные категории',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildCategoryCard(theme, 'Фотография', Icons.camera_alt),
              _buildCategoryCard(theme, 'Видеосъёмка', Icons.videocam),
              _buildCategoryCard(theme, 'Организация', Icons.event),
              _buildCategoryCard(theme, 'Музыка', Icons.music_note),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(ThemeData theme, String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () {
          // Переход к категории
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                icon,
                color: theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
