import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_statistics.dart';
import '../models/portfolio_item.dart';
import '../models/social_link.dart';
import '../services/specialist_profile_service.dart';
import '../widgets/profile_statistics_widget.dart';
import '../widgets/portfolio_widget.dart';
import '../widgets/social_links_widget.dart';

/// Расширенный экран профиля специалиста
class EnhancedSpecialistProfileScreen extends ConsumerStatefulWidget {
  const EnhancedSpecialistProfileScreen({
    super.key,
    required this.specialistId,
  });

  final String specialistId;

  @override
  ConsumerState<EnhancedSpecialistProfileScreen> createState() =>
      _EnhancedSpecialistProfileScreenState();
}

class _EnhancedSpecialistProfileScreenState
    extends ConsumerState<EnhancedSpecialistProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final SpecialistProfileService _profileService = SpecialistProfileService();

  ProfileStatistics? _statistics;
  List<PortfolioItem> _portfolio = [];
  List<SocialLink> _socialLinks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      // Загружаем данные параллельно
      final results = await Future.wait([
        _profileService.getProfileStatistics(widget.specialistId),
        _profileService.getPortfolio(widget.specialistId),
        _profileService.getSocialLinks(widget.specialistId),
      ]);

      setState(() {
        _statistics = results[0] as ProfileStatistics;
        _portfolio = results[1] as List<PortfolioItem>;
        _socialLinks = results[2] as List<SocialLink>;
        _isLoading = false;
      });

      // Увеличиваем количество просмотров
      await _profileService.incrementViews(widget.specialistId);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Ошибка загрузки данных профиля: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль специалиста'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProfile,
            tooltip: 'Поделиться профилем',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'О специалисте', icon: Icon(Icons.person)),
            Tab(text: 'Портфолио', icon: Icon(Icons.photo_library)),
            Tab(text: 'Контакты', icon: Icon(Icons.contact_phone)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildPortfolioTab(),
                _buildContactsTab(),
              ],
            ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Основная информация
          _buildBasicInfo(),
          const SizedBox(height: 20),
          
          // Статистика профиля
          if (_statistics != null) ...[
            ProfileStatisticsWidget(statistics: _statistics!),
            const SizedBox(height: 20),
          ],
          
          // Отзывы (заглушка)
          _buildReviewsSection(),
          const SizedBox(height: 20),
          
          // Закреплённые посты (заглушка)
          _buildPinnedPostsSection(),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: PortfolioWidget(
        portfolioItems: _portfolio,
        onItemTap: _onPortfolioItemTap,
        onLike: _onPortfolioItemLike,
      ),
    );
  }

  Widget _buildContactsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Социальные ссылки
          SocialLinksWidget(
            socialLinks: _socialLinks,
            onLinkTap: _onSocialLinkTap,
          ),
          const SizedBox(height: 20),
          
          // Контактная информация
          _buildContactInfo(),
          const SizedBox(height: 20),
          
          // Кнопки действий
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Аватар и основная информация
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Имя специалиста',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Категория специалиста',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _statistics?.rating.toStringAsFixed(1) ?? '0.0',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${_statistics?.reviewsCount ?? 0} отзывов)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Описание
          const Text(
            'Описание специалиста и его услуг. Здесь может быть подробная информация о опыте работы, специализации и подходах к работе.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Отзывы',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Переход к полному списку отзывов
                },
                child: const Text('Все отзывы'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Заглушка для отзывов
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Отзывы появятся здесь',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Клиенты смогут оставлять отзывы после завершения заказов',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedPostsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Закреплённые посты',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Заглушка для закреплённых постов
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Icon(Icons.push_pin_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Закреплённые посты',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Специалист может закреплять важные посты в своём профиле',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.contact_phone, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Контактная информация',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildContactItem(Icons.phone, 'Телефон', '+7 (999) 123-45-67'),
          _buildContactItem(Icons.email, 'Email', 'specialist@example.com'),
          _buildContactItem(Icons.location_on, 'Город', 'Москва'),
          _buildContactItem(Icons.access_time, 'Время ответа', '2-4 часа'),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _contactSpecialist,
            icon: const Icon(Icons.message),
            label: const Text('Написать сообщение'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _createOrder,
            icon: const Icon(Icons.add),
            label: const Text('Создать заявку'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _onPortfolioItemTap(PortfolioItem item) {
    // TODO: Открыть полноэкранный просмотр элемента портфолио
    debugPrint('Открытие элемента портфолио: ${item.title}');
  }

  void _onPortfolioItemLike(PortfolioItem item) {
    // TODO: Реализовать лайк элемента портфолио
    debugPrint('Лайк элемента портфолио: ${item.title}');
  }

  void _onSocialLinkTap(SocialLink link) {
    debugPrint('Открытие социальной ссылки: ${link.platform.value}');
  }

  Future<void> _shareProfile() async {
    try {
      final shareUrl = await _profileService.shareProfile(widget.specialistId);
      // TODO: Реализовать шаринг профиля
      debugPrint('Шаринг профиля: $shareUrl');
    } catch (e) {
      debugPrint('Ошибка шаринга профиля: $e');
    }
  }

  void _contactSpecialist() {
    // TODO: Переход к чату с специалистом
    debugPrint('Создание чата с специалистом');
  }

  void _createOrder() {
    // TODO: Создание заявки специалисту
    debugPrint('Создание заявки специалисту');
  }
}