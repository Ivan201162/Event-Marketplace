import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist.dart';
import '../providers/specialist_providers.dart';
import '../widgets/specialist_portfolio_widget.dart';
import '../widgets/specialist_reviews_widget.dart';
import '../widgets/booking_widget.dart';
import 'booking_form_screen.dart';

class SpecialistProfileScreen extends ConsumerStatefulWidget {
  final String specialistId;

  const SpecialistProfileScreen({
    super.key,
    required this.specialistId,
  });

  @override
  ConsumerState<SpecialistProfileScreen> createState() =>
      _SpecialistProfileScreenState();
}

class _SpecialistProfileScreenState
    extends ConsumerState<SpecialistProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;

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
    final specialistAsync = ref.watch(specialistProvider(widget.specialistId));
    final favorites = ref.watch(favoriteSpecialistsProvider);

    _isFavorite = favorites.contains(widget.specialistId);

    return Scaffold(
      body: specialistAsync.when(
        data: (specialist) {
          if (specialist == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Специалист не найден'),
                ],
              ),
            );
          }

          return _buildSpecialistProfile(specialist);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(specialistProvider(widget.specialistId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Построить профиль специалиста
  Widget _buildSpecialistProfile(Specialist specialist) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          _buildSliverAppBar(specialist),
          _buildSliverHeader(specialist),
        ];
      },
      body: _buildTabBarView(specialist),
    );
  }

  /// Построить AppBar
  Widget _buildSliverAppBar(Specialist specialist) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Фоновое изображение (заглушка)
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://via.placeholder.com/400x200/6366f1/ffffff?text=${specialist.categoryDisplayName}',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Градиентный оверлей
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Контент
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Text(
                            specialist.name.isNotEmpty
                                ? specialist.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                specialist.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                specialist.categoryDisplayName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            if (_isFavorite) {
                              ref
                                  .read(favoriteSpecialistsProvider.notifier)
                                  .removeFromFavorites(specialist.id);
                            } else {
                              ref
                                  .read(favoriteSpecialistsProvider.notifier)
                                  .addToFavorites(specialist.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => _shareSpecialist(specialist),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) => _handleMenuAction(value, specialist),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Пожаловаться'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'contact',
              child: Row(
                children: [
                  Icon(Icons.contact_phone),
                  SizedBox(width: 8),
                  Text('Связаться'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Построить заголовок с информацией
  Widget _buildSliverHeader(Specialist specialist) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статистика
            _buildStatsRow(specialist),

            const SizedBox(height: 16),

            // Описание
            if (specialist.description != null) ...[
              Text(
                'О специалисте',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                specialist.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Подкатегории
            if (specialist.subcategories.isNotEmpty) ...[
              Text(
                'Услуги',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: specialist.subcategories.map((subcategory) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      subcategory,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Контактная информация
            _buildContactInfo(specialist),
          ],
        ),
      ),
    );
  }

  /// Построить строку статистики
  Widget _buildStatsRow(Specialist specialist) {
    return Row(
      children: [
        // Рейтинг
        Expanded(
          child: _buildStatCard(
            icon: Icons.star,
            label: 'Рейтинг',
            value: specialist.rating.toStringAsFixed(1),
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),

        // Отзывы
        Expanded(
          child: _buildStatCard(
            icon: Icons.rate_review,
            label: 'Отзывы',
            value: specialist.reviewCount.toString(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),

        // Опыт
        Expanded(
          child: _buildStatCard(
            icon: Icons.work,
            label: 'Опыт',
            value: '${specialist.yearsOfExperience} лет',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),

        // Цена
        Expanded(
          child: _buildStatCard(
            icon: Icons.attach_money,
            label: 'Цена',
            value: '${specialist.hourlyRate.toStringAsFixed(0)} ₽/ч',
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  /// Построить карточку статистики
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Построить контактную информацию
  Widget _buildContactInfo(Specialist specialist) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Контактная информация',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Области обслуживания
          if (specialist.serviceAreas.isNotEmpty) ...[
            _buildInfoRow(Icons.location_on, 'Области обслуживания',
                specialist.serviceAreas.join(', ')),
            const SizedBox(height: 8),
          ],

          // Языки
          if (specialist.languages.isNotEmpty) ...[
            _buildInfoRow(
                Icons.language, 'Языки', specialist.languages.join(', ')),
            const SizedBox(height: 8),
          ],

          // Оборудование
          if (specialist.equipment.isNotEmpty) ...[
            _buildInfoRow(
                Icons.build, 'Оборудование', specialist.equipment.join(', ')),
            const SizedBox(height: 8),
          ],

          // Статус верификации
          _buildInfoRow(
            specialist.isVerified ? Icons.verified : Icons.pending,
            'Статус',
            specialist.isVerified ? 'Верифицирован' : 'На рассмотрении',
          ),
        ],
      ),
    );
  }

  /// Построить строку информации
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Построить TabBarView
  Widget _buildTabBarView(Specialist specialist) {
    return Column(
      children: [
        // TabBar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Портфолио'),
              Tab(text: 'Отзывы'),
              Tab(text: 'Расписание'),
              Tab(text: 'Контакты'),
            ],
          ),
        ),

        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SpecialistPortfolioWidget(specialist: specialist),
              SpecialistReviewsWidget(specialistId: specialist.id),
              _buildScheduleTab(specialist),
              _buildContactsTab(specialist),
            ],
          ),
        ),

        // Кнопка бронирования
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialist.priceRange,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'от ${specialist.hourlyRate.toStringAsFixed(0)} ₽/час',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: specialist.isAvailable
                      ? () => _showBookingDialog(specialist)
                      : null,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Забронировать'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Построить вкладку расписания
  Widget _buildScheduleTab(Specialist specialist) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Доступность',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Статус доступности
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: specialist.isAvailable
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: specialist.isAvailable ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  specialist.isAvailable ? Icons.check_circle : Icons.cancel,
                  color: specialist.isAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialist.isAvailable
                            ? 'Доступен для бронирования'
                            : 'Временно недоступен',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: specialist.isAvailable
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialist.isAvailable
                            ? 'Специалист принимает новые заявки'
                            : 'Специалист временно не принимает заявки',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Календарь (заглушка)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.calendar_month, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Календарь доступности',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Будет добавлен в следующем шаге',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Построить вкладку контактов
  Widget _buildContactsTab(Specialist specialist) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Способы связи',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Кнопки связи
          _buildContactButton(
            icon: Icons.message,
            label: 'Написать сообщение',
            onTap: () => _sendMessage(specialist),
          ),

          const SizedBox(height: 12),

          _buildContactButton(
            icon: Icons.phone,
            label: 'Позвонить',
            onTap: () => _makeCall(specialist),
          ),

          const SizedBox(height: 12),

          _buildContactButton(
            icon: Icons.email,
            label: 'Отправить email',
            onTap: () => _sendEmail(specialist),
          ),

          const SizedBox(height: 24),

          // Социальные сети (заглушка)
          Text(
            'Социальные сети',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.share, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Социальные сети',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Будут добавлены в следующем шаге',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Построить кнопку контакта
  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  /// Показать диалог бронирования
  void _showBookingDialog(Specialist specialist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingFormScreen(specialistId: specialist.id),
      ),
    );
  }

  /// Поделиться специалистом
  void _shareSpecialist(Specialist specialist) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Поделиться ${specialist.name}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  /// Обработать действие меню
  void _handleMenuAction(String action, Specialist specialist) {
    switch (action) {
      case 'report':
        _reportSpecialist(specialist);
        break;
      case 'contact':
        _showContactOptions(specialist);
        break;
    }
  }

  /// Пожаловаться на специалиста
  void _reportSpecialist(Specialist specialist) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Пожаловаться на ${specialist.name}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  /// Показать варианты связи
  void _showContactOptions(Specialist specialist) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Связаться с ${specialist.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactButton(
              icon: Icons.message,
              label: 'Написать сообщение',
              onTap: () {
                Navigator.pop(context);
                _sendMessage(specialist);
              },
            ),
            const SizedBox(height: 12),
            _buildContactButton(
              icon: Icons.phone,
              label: 'Позвонить',
              onTap: () {
                Navigator.pop(context);
                _makeCall(specialist);
              },
            ),
            const SizedBox(height: 12),
            _buildContactButton(
              icon: Icons.email,
              label: 'Отправить email',
              onTap: () {
                Navigator.pop(context);
                _sendEmail(specialist);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Отправить сообщение
  void _sendMessage(Specialist specialist) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Отправить сообщение ${specialist.name}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  /// Позвонить
  void _makeCall(Specialist specialist) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Позвонить ${specialist.name}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  /// Отправить email
  void _sendEmail(Specialist specialist) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Отправить email ${specialist.name}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
}
