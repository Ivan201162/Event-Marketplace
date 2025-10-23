import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_widgets.dart';

/// Адаптивный экран профиля
class ResponsiveProfileScreen extends StatelessWidget {
  const ResponsiveProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: ResponsiveAppBar(
        title: 'Профиль',
        actions: [
          ResponsiveIcon(Icons.settings),
          ResponsiveSpacing(width: 16),
        ],
      ),
      body: ResponsiveLayoutBuilder(
        mobile: (context) => _buildMobileLayout(context),
        tablet: (context) => _buildTabletLayout(context),
        desktop: (context) => _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return ResponsiveList(
      children: [
        _buildProfileSection(context),
        _buildStatsSection(context),
        _buildActionsSection(context),
        _buildPostsSection(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        children: [
          _buildProfileSection(context),
          _buildStatsSection(context),
          _buildActionsSection(context),
          _buildPostsSection(context),
        ],
        crossAxisCount: 2,
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        children: [
          _buildProfileSection(context),
          _buildStatsSection(context),
          _buildActionsSection(context),
          _buildPostsSection(context),
        ],
        crossAxisCount: 3,
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: ResponsiveUtils.getResponsiveIconSize(context, mobile: 40.0, tablet: 50.0, desktop: 60.0),
            backgroundColor: Colors.blue,
            child: ResponsiveText(
              'А',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 24.0, tablet: 30.0, desktop: 36.0),
              ),
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveText(
            'Анна Петрова',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 20.0, tablet: 24.0, desktop: 28.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 8),
          ResponsiveText(
            'Ведущая мероприятий',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
              color: Colors.grey[600],
            ),
          ),
          ResponsiveSpacing(height: 8),
          ResponsiveText(
            'Москва',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
              color: Colors.grey[600],
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveGrid(
            children: [
              ResponsiveButton(
                text: 'Редактировать',
                onPressed: () {},
                backgroundColor: Colors.blue,
              ),
              ResponsiveButton(
                text: 'Поделиться',
                onPressed: () {},
                backgroundColor: Colors.green,
              ),
            ],
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context, mobile: 2, tablet: 2, desktop: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Статистика',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveGrid(
            children: [
              _buildStatItem(context, 'Заявки', '12', Colors.blue),
              _buildStatItem(context, 'Отзывы', '8', Colors.green),
              _buildStatItem(context, 'Рейтинг', '4.9', Colors.orange),
              _buildStatItem(context, 'Подписчики', '156', Colors.purple),
            ],
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context, mobile: 2, tablet: 4, desktop: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return ResponsiveCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ResponsiveText(
            value,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 20.0, tablet: 24.0, desktop: 28.0),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          ResponsiveSpacing(height: 8),
          ResponsiveText(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Действия',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveList(
            children: [
              _buildActionItem(context, 'Мои заявки', Icons.assignment, Colors.blue),
              _buildActionItem(context, 'Мои отзывы', Icons.star, Colors.orange),
              _buildActionItem(context, 'Настройки', Icons.settings, Colors.grey),
              _buildActionItem(context, 'Помощь', Icons.help, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String title, IconData icon, Color color) {
    return ResponsiveCard(
      child: Row(
        children: [
          ResponsiveIcon(
            icon,
            color: color,
            size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24.0, tablet: 28.0, desktop: 32.0),
          ),
          ResponsiveSpacing(width: 16),
          Expanded(
            child: ResponsiveText(
              title,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
              ),
            ),
          ),
          ResponsiveIcon(Icons.arrow_forward_ios),
        ],
      ),
    );
  }

  Widget _buildPostsSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Мои посты',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveList(
            children: [
              _buildPostItem(context, 'Отличное мероприятие!', '2 дня назад', 15, 3),
              _buildPostItem(context, 'Новые фотографии', '1 неделя назад', 28, 7),
              _buildPostItem(context, 'Готовлюсь к свадьбе', '2 недели назад', 12, 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, String title, String time, int likes, int comments) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 8),
          ResponsiveText(
            time,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
              color: Colors.grey[600],
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveDivider(),
          ResponsiveSpacing(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(context, Icons.thumb_up, '$likes', Colors.blue),
              _buildActionButton(context, Icons.comment, '$comments', Colors.green),
              _buildActionButton(context, Icons.share, 'Поделиться', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color) {
    return ResponsiveButton(
      text: label,
      onPressed: () {},
      backgroundColor: Colors.transparent,
      textColor: color,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context),
        vertical: ResponsiveUtils.getResponsiveSpacing(context) / 2,
      ),
    );
  }
}
