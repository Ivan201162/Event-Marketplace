import 'package:event_marketplace_app/models/user.dart';
import 'package:flutter/material.dart';

/// Виджет вкладок профиля
class ProfileTabsWidget extends StatefulWidget {
  const ProfileTabsWidget(
      {required this.user, required this.isCurrentUser, super.key,});

  final AppUser user;
  final bool isCurrentUser;

  @override
  State<ProfileTabsWidget> createState() => _ProfileTabsWidgetState();
}

class _ProfileTabsWidgetState extends State<ProfileTabsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.user.isSpecialist ? 4 : 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Табы
          TabBar(
            controller: _tabController,
            indicatorColor: theme.primaryColor,
            labelColor: theme.primaryColor,
            unselectedLabelColor:
                theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: widget.user.isSpecialist
                ? const [
                    Tab(text: 'Портфолио'),
                    Tab(text: 'Услуги'),
                    Tab(text: 'Отзывы'),
                    Tab(text: 'О себе'),
                  ]
                : const [
                    Tab(text: 'Заказы'),
                    Tab(text: 'Избранное'),
                    Tab(text: 'О себе'),
                  ],
          ),

          // Содержимое табов
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: widget.user.isSpecialist
                  ? [
                      _buildPortfolioTab(),
                      _buildServicesTab(),
                      _buildReviewsTab(),
                      _buildAboutTab(),
                    ]
                  : [_buildOrdersTab(), _buildFavoritesTab(), _buildAboutTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Портфолио пусто'),
            SizedBox(height: 8),
            Text('Добавьте свои работы', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _buildServicesTab() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Услуги не добавлены'),
            SizedBox(height: 8),
            Text('Добавьте свои услуги', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _buildReviewsTab() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Отзывы отсутствуют'),
            SizedBox(height: 8),
            Text('Пока нет отзывов', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _buildOrdersTab() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Заказы отсутствуют'),
            SizedBox(height: 8),
            Text('Пока нет заказов', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _buildFavoritesTab() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Избранное пусто'),
            SizedBox(height: 8),
            Text('Добавьте специалистов в избранное',
                style: TextStyle(color: Colors.grey),),
          ],
        ),
      );

  Widget _buildAboutTab() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
            Text(
              'О себе',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.user.bio!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
          ],
          Text(
            'Информация',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Роль', widget.user.roleDisplayName),
          _buildInfoRow('Дата регистрации', _formatDate(widget.user.createdAt)),
          if (widget.user.city != null)
            _buildInfoRow('Город', widget.user.city!),
          if (widget.user.phone != null)
            _buildInfoRow('Телефон', widget.user.phone!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}
