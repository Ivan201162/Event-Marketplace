import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/portfolio_item.dart';
import '../models/profile_statistics.dart';
import '../models/social_link.dart';
import '../providers/auth_providers.dart';
import '../widgets/portfolio_widget.dart';
import '../widgets/profile_statistics_widget.dart';
import '../widgets/social_links_widget.dart';
import '../widgets/specialist_badges_widget.dart';

/// Улучшенный экран профиля специалиста/пользователя
class EnhancedProfileScreen extends ConsumerStatefulWidget {
  // Если null, то показываем профиль текущего пользователя

  const EnhancedProfileScreen({super.key, this.specialistId});
  final String? specialistId;

  @override
  ConsumerState<EnhancedProfileScreen> createState() =>
      _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends ConsumerState<EnhancedProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _isOnline = true;
  final bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.value;
    final isOwnProfile =
        widget.specialistId == null || widget.specialistId == currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'Мой профиль' : 'Профиль специалиста'),
        actions: [
          if (isOwnProfile) ...[
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: _toggleEditMode,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/settings'),
            ),
          ] else ...[
            IconButton(icon: const Icon(Icons.share), onPressed: _shareProfile),
            IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: _toggleFavorite),
          ],
        ],
      ),
      body: Column(
        children: [
          // Заголовок профиля
          _buildProfileHeader(currentUser, isOwnProfile),

          // Бейджи
          _buildBadgesSection(),

          // Статистика
          _buildStatisticsSection(),

          // Табы
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'О себе', icon: Icon(Icons.person)),
              Tab(text: 'Портфолио', icon: Icon(Icons.photo_library)),
              Tab(text: 'Отзывы', icon: Icon(Icons.star)),
              Tab(text: 'Контакты', icon: Icon(Icons.contact_phone)),
            ],
          ),

          // Содержимое табов
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildPortfolioTab(),
                _buildReviewsTab(),
                _buildContactsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(isOwnProfile),
    );
  }

  Widget _buildProfileHeader(currentUser, bool isOwnProfile) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Аватар с онлайн статусом
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: currentUser?.photoURL != null
                      ? NetworkImage(currentUser!.photoURL!)
                      : null,
                  child: currentUser?.photoURL == null
                      ? Text(
                          currentUser?.displayName
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              '?',
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                if (_isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Имя и статус
            Text(
              currentUser?.displayName ?? 'Без имени',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(
              currentUser?.email ?? 'Email не указан',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const SizedBox(height: 8),

            // Город
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  currentUser?.city?.trim().isNotEmpty == true
                      ? currentUser!.city!
                      : 'Город не указан',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Кнопки действий
            if (isOwnProfile)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Редактировать',
                    onPressed: _toggleEditMode,
                  ),
                  _buildActionButton(
                    icon: Icons.calendar_today,
                    label: 'Календарь',
                    onPressed: _openCalendar,
                  ),
                  _buildActionButton(
                    icon: Icons.analytics,
                    label: 'Аналитика',
                    onPressed: _openAnalytics,
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                      icon: Icons.message,
                      label: 'Написать',
                      onPressed: _sendMessage),
                  _buildActionButton(
                    icon: Icons.assignment,
                    label: 'Заказать',
                    onPressed: _createOrder,
                  ),
                  _buildActionButton(
                      icon: Icons.phone,
                      label: 'Позвонить',
                      onPressed: _makeCall),
                ],
              ),
          ],
        ),
      );

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white),
            style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      );

  Widget _buildBadgesSection() {
    // Тестовые бейджи
    final badges = [
      const SpecialistBadge(
        text: 'Проверен',
        icon: Icons.verified,
        color: Color(0xFF2196F3),
        textColor: Colors.white,
      ),
      const SpecialistBadge(
        text: 'ТОП',
        icon: Icons.star,
        color: Color(0xFFFFD700),
        textColor: Color(0xFF8B4513),
      ),
      const SpecialistBadge(
        text: 'Быстрый ответ',
        icon: Icons.flash_on,
        color: Color(0xFFFF9800),
        textColor: Colors.white,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SpecialistBadgesWidget(badges: badges),
    );
  }

  Widget _buildStatisticsSection() => Container(
        padding: const EdgeInsets.all(16),
        child: const ProfileStatisticsWidget(
          statistics: ProfileStatistics(
            views: 1250,
            likes: 89,
            rating: 4.8,
            reviewsCount: 127,
            averagePrice: 15000,
            completedOrders: 89,
            responseTime: 2.5,
            onlineStatus: true,
            portfolioItems: 15,
            socialLinks: 3,
            pinnedPosts: 5,
          ),
        ),
      );

  Widget _buildAboutTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('О специалисте',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Профессиональный фотограф с 5-летним опытом работы. '
              'Специализируюсь на свадебной и портретной съёмке. '
              'Работаю в Москве и области. Готов к выездным съёмкам.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text('Специализация',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Свадебная съёмка',
                'Портретная съёмка',
                'Семейная съёмка',
                'Корпоративные мероприятия',
              ]
                  .map(
                    (specialization) => Chip(
                        label: Text(specialization),
                        backgroundColor: Colors.blue[50]),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            const Text('Опыт работы',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('5 лет в сфере фотографии'),
            const Text('Более 200 успешных проектов'),
            const Text('Работа с известными брендами'),
          ],
        ),
      );

  Widget _buildPortfolioTab() {
    // Тестовые данные для портфолио
    final portfolioItems = [
      PortfolioItem(
        id: '1',
        specialistId: widget.specialistId ?? 'current_user',
        title: 'Свадебная фотосессия',
        description: 'Красивая свадебная съёмка в парке',
        mediaUrl: 'https://picsum.photos/400/300?random=1',
        mediaType: PortfolioMediaType.image,
        category: 'Свадебная съёмка',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        views: 45,
        likes: 12,
        tags: ['свадьба', 'фото', 'парк'],
        location: 'Москва',
        eventDate: DateTime.now().subtract(const Duration(days: 1)),
        clientName: 'Анна и Дмитрий',
      ),
      PortfolioItem(
        id: '2',
        specialistId: widget.specialistId ?? 'current_user',
        title: 'Портретная съёмка',
        description: 'Профессиональная портретная съёмка',
        mediaUrl: 'https://picsum.photos/400/300?random=2',
        mediaType: PortfolioMediaType.image,
        category: 'Портретная съёмка',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        views: 32,
        likes: 8,
        tags: ['портрет', 'студия'],
        location: 'Студия в Москве',
        eventDate: DateTime.now().subtract(const Duration(days: 3)),
        clientName: 'Елена К.',
      ),
    ];

    return PortfolioWidget(portfolioItems: portfolioItems);
  }

  Widget _buildReviewsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Отзывы',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('Все отзывы')),
              ],
            ),

            const SizedBox(height: 16),

            // Рейтинг
            Row(
              children: [
                const Text('4.8',
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(Icons.star,
                            color: index < 4 ? Colors.amber : Colors.grey,
                            size: 20),
                      ),
                    ),
                    const Text('127 отзывов'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Список отзывов
            ...List.generate(3, _buildReviewCard),
          ],
        ),
      );

  Widget _buildReviewCard(int index) {
    final reviews = [
      {
        'name': 'Анна Петрова',
        'rating': 5,
        'text': 'Отличный фотограф! Очень довольна результатом. Рекомендую!',
        'date': '2 дня назад',
        'avatar': 'https://picsum.photos/50/50?random=${index + 10}',
      },
      {
        'name': 'Дмитрий Смирнов',
        'rating': 4,
        'text': 'Качественная работа, быстрое выполнение заказа.',
        'date': '1 неделю назад',
        'avatar': 'https://picsum.photos/50/50?random=${index + 11}',
      },
      {
        'name': 'Елена Козлова',
        'rating': 5,
        'text': 'Профессиональный подход, отличные фотографии!',
        'date': '2 недели назад',
        'avatar': 'https://picsum.photos/50/50?random=${index + 12}',
      },
    ];

    final review = reviews[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(review['avatar']! as String),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['name']! as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (starIndex) => Icon(
                              Icons.star,
                              color: starIndex < (review['rating']! as int)
                                  ? Colors.amber
                                  : Colors.grey,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            review['date']! as String,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(review['text']! as String),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Контакты',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Социальные сети
            SocialLinksWidget(
              socialLinks: [
                SocialLink(
                  id: '1',
                  specialistId: widget.specialistId ?? 'current_user',
                  platform: SocialPlatform.instagram,
                  url: 'https://instagram.com/photographer',
                  username: 'photographer',
                  isVerified: true,
                  isPublic: true,
                  followersCount: 1250,
                  createdAt: DateTime.now().subtract(const Duration(days: 30)),
                ),
                SocialLink(
                  id: '2',
                  specialistId: widget.specialistId ?? 'current_user',
                  platform: SocialPlatform.vk,
                  url: 'https://vk.com/photographer',
                  username: 'photographer',
                  isVerified: false,
                  isPublic: true,
                  followersCount: 890,
                  createdAt: DateTime.now().subtract(const Duration(days: 60)),
                ),
                SocialLink(
                  id: '3',
                  specialistId: widget.specialistId ?? 'current_user',
                  platform: SocialPlatform.telegram,
                  url: 'https://t.me/photographer',
                  username: 'photographer',
                  isVerified: true,
                  isPublic: true,
                  followersCount: 450,
                  createdAt: DateTime.now().subtract(const Duration(days: 15)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Контактная информация
            const Text(
              'Контактная информация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildContactItem(
              icon: Icons.email,
              title: 'Email',
              value: 'photographer@example.com',
              onTap: () {},
            ),

            _buildContactItem(
              icon: Icons.phone,
              title: 'Телефон',
              value: '+7 (999) 123-45-67',
              onTap: () {},
            ),

            _buildContactItem(
              icon: Icons.location_on,
              title: 'Адрес',
              value: 'Москва, ул. Тверская, 1',
              onTap: () {},
            ),

            _buildContactItem(
              icon: Icons.schedule,
              title: 'Время работы',
              value: 'Пн-Пт: 9:00-18:00',
              onTap: () {},
            ),
          ],
        ),
      );

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) =>
      ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      );

  Widget? _buildFloatingActionButton(bool isOwnProfile) {
    if (!isOwnProfile) return null;

    return FloatingActionButton(
      onPressed: _toggleEditMode,
      child: Icon(_isEditing ? Icons.check : Icons.edit),
    );
  }

  void _toggleEditMode() {
    // Открываем экран редактирования профиля
    context.push('/edit-profile').then((_) {
      // Обновляем данные профиля после возврата
      setState(() {});
    });
  }

  void _shareProfile() {
    // TODO: Реализовать шаринг профиля
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Функция шаринга будет добавлена')));
  }

  void _toggleFavorite() {
    // TODO: Реализовать добавление в избранное
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Добавлено в избранное')));
  }

  void _openCalendar() {
    // TODO: Реализовать открытие календаря
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Календарь будет добавлен')));
  }

  void _openAnalytics() {
    // TODO: Реализовать открытие аналитики
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Аналитика будет добавлена')));
  }

  void _sendMessage() {
    // TODO: Реализовать отправку сообщения
    context.push('/chat/${widget.specialistId}');
  }

  void _createOrder() {
    // TODO: Реализовать создание заказа
    context.push('/create-order/${widget.specialistId}');
  }

  void _makeCall() {
    // TODO: Реализовать звонок
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Функция звонков будет добавлена')));
  }
}
