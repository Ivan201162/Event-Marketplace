import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/specialist.dart';
import '../providers/auth_providers.dart';
import '../providers/search_providers.dart';
import '../repositories/chats_repository.dart';

class EnhancedHomeScreen extends ConsumerStatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  ConsumerState<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends ConsumerState<EnhancedHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Все';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Все', 'icon': '🎯', 'color': Colors.blue},
    {'name': 'Свадьбы', 'icon': '💒', 'color': Colors.pink},
    {'name': 'Корпоративы', 'icon': '🏢', 'color': Colors.blue},
    {'name': 'Дни рождения', 'icon': '🎂', 'color': Colors.orange},
    {'name': 'Детские праздники', 'icon': '🎈', 'color': Colors.purple},
    {'name': 'Выпускные', 'icon': '🎓', 'color': Colors.green},
    {'name': 'Фотографы', 'icon': '📸', 'color': Colors.indigo},
    {'name': 'Видеографы', 'icon': '🎬', 'color': Colors.red},
    {'name': 'DJ', 'icon': '🎵', 'color': Colors.purple},
    {'name': 'Ведущие', 'icon': '🎤', 'color': Colors.teal},
    {'name': 'Декораторы', 'icon': '🎨', 'color': Colors.amber},
    {'name': 'Аниматоры', 'icon': '🎭', 'color': Colors.cyan},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final specialistsAsync = ref.watch(allSpecialistsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // Обновление данных
        await Future.delayed(const Duration(seconds: 1));
      },
      child: CustomScrollView(
        slivers: [
          // Плашка пользователя
          SliverToBoxAdapter(
            child: currentUserAsync.when(
              data: _buildUserProfileCard,
              loading: () => _buildUserProfileCard(null),
              error: (_, __) => _buildUserProfileCard(null),
            ),
          ),

          // Поиск специалистов
          SliverToBoxAdapter(
            child: _buildSearchSection(),
          ),

          // Категории специалистов
          SliverToBoxAdapter(
            child: _buildCategoriesSection(),
          ),

          // Карусель лучших специалистов недели
          SliverToBoxAdapter(
            child: _buildBestSpecialistsCarousel(),
          ),

          // Блок "Интересное"
          SliverToBoxAdapter(
            child: _buildInterestingSection(),
          ),

          // Быстрые действия
          SliverToBoxAdapter(
            child: _buildQuickActionsSection(),
          ),
        ],
      ),
    );
  }

  /// Плашка пользователя с аватаром, именем и городом
  Widget _buildUserProfileCard(user) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Аватар пользователя
            GestureDetector(
              onTap: () {
                if (user != null) {
                  context.push('/profile/me');
                }
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.white,
                  child: user?.photoURL?.isNotEmpty == true
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user.photoURL!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              size: 30,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Theme.of(context).primaryColor,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Информация о пользователе
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Добро пожаловать!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Войдите в аккаунт',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user?.city?.trim().isNotEmpty == true
                            ? user!.city!
                            : 'Город не указан',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Кнопка редактирования профиля
            IconButton(
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(
                Icons.edit,
                color: Colors.white,
              ),
              tooltip: 'Редактировать профиль',
            ),
          ],
        ),
      );

  /// Строка поиска специалистов
  Widget _buildSearchSection() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Найти специалиста',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Найти специалиста…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      context.push('/search?q=${Uri.encodeComponent(_searchController.text)}');
                    }
                  },
                  icon: const Icon(Icons.search),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  context.push('/search?q=${Uri.encodeComponent(query)}');
                }
              },
            ),
          ],
        ),
      );

  /// Категории специалистов
  Widget _buildCategoriesSection() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Категории',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category['name'] == _selectedCategory;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['name'] as String;
                      });
                      // Переход к отфильтрованным специалистам
                      context.push('/search?category=${Uri.encodeComponent(category['name'] as String)}');
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (category['color'] as Color).withOpacity(0.2)
                            : (category['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (category['color'] as Color).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            category['icon'] as String,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category['name'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? (category['color'] as Color)
                                  : Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );

  /// Карусель лучших специалистов недели
  Widget _buildBestSpecialistsCarousel() {
    final specialistsAsync = ref.watch(allSpecialistsProvider);

    return specialistsAsync.when(
      data: (specialists) {
        // Берем топ-5 специалистов по рейтингу
        final topSpecialists = specialists
          ..sort((a, b) => b.rating.compareTo(a.rating));
        final top5 = topSpecialists.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Лучшие специалисты недели',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/search'),
                    child: const Text('Все'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: top5.length,
                itemBuilder: (context, index) {
                  final specialist = top5[index];
                  return _SpecialistCard(specialist: specialist);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Ошибка загрузки специалистов')),
    );
  }

  /// Блок "Интересное"
  Widget _buildInterestingSection() => Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Интересное',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InterestingCard(
                    title: 'Самые популярные категории недели',
                    icon: Icons.trending_up,
                    color: Colors.orange,
                    onTap: () => context.push('/search?sort=popular'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InterestingCard(
                    title: 'Новые специалисты',
                    icon: Icons.person_add,
                    color: Colors.green,
                    onTap: () => context.push('/search?sort=newest'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InterestingCard(
              title: 'Специалисты рядом',
              icon: Icons.location_on,
              color: Colors.blue,
              onTap: () => context.push('/search?nearby=true'),
            ),
          ],
        ),
      );

  /// Быстрые действия
  Widget _buildQuickActionsSection() => Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Быстрые действия',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.event,
                    title: 'Создать заявку',
                    onTap: () => context.push('/requests/create'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.photo_library,
                    title: 'Мои идеи',
                    onTap: () => context.push('/ideas'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

/// Карточка специалиста с интерактивными кнопками
class _SpecialistCard extends StatelessWidget {
  const _SpecialistCard({required this.specialist});
  final Specialist specialist;

  @override
  Widget build(BuildContext context) => Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => context.push('/specialist/${specialist.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Аватар специалиста
              Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: specialist.avatar != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(specialist.avatar!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: specialist.avatar == null
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : null,
                ),
                child: specialist.avatar == null
                    ? const Center(
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),
              // Информация о специалисте
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialist.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        specialist.category.displayName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber[600],
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            specialist.rating.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${specialist.price}₸',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Интерактивные кнопки
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _openChat(context),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Связаться',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _openBooking(context),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Забронировать',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  /// Открыть чат с специалистом
  Future<void> _openChat(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Необходимо войти в аккаунт')),
        );
        return;
      }

      final chatsRepository = ChatsRepository();
      final chatId = await chatsRepository.findOrCreateChat(
        currentUser.uid,
        specialist.id,
      );

      if (chatId != null) {
        context.push('/chat/$chatId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка создания чата')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  /// Открыть форму бронирования
  void _openBooking(BuildContext context) {
    context.push('/booking/${specialist.id}');
  }
}

/// Карточка интересного контента
class _InterestingCard extends StatelessWidget {
  const _InterestingCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _QuickActionCard extends StatelessWidget {

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
}
