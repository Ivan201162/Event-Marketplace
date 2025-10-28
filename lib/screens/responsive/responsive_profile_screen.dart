import 'package:event_marketplace_app/utils/responsive_utils.dart';
import 'package:event_marketplace_app/widgets/responsive/responsive_widgets.dart';
import 'package:flutter/material.dart';

/// Адаптивный экран профиля
class ResponsiveProfileScreen extends StatelessWidget {
  const ResponsiveProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: const ResponsiveAppBar(
        title: 'Профиль',
        actions: [
          ResponsiveIcon(Icons.settings),
          ResponsiveSpacing(width: 16),
        ],
      ),
      body: ResponsiveLayoutBuilder(
        mobile: _buildMobileLayout,
        tablet: _buildTabletLayout,
        desktop: _buildDesktopLayout,
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
        crossAxisCount: 2,
        children: [
          _buildProfileSection(context),
          _buildStatsSection(context),
          _buildActionsSection(context),
          _buildPostsSection(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        crossAxisCount: 3,
        children: [
          _buildProfileSection(context),
          _buildStatsSection(context),
          _buildActionsSection(context),
          _buildPostsSection(context),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: ResponsiveUtils.getResponsiveIconSize(context,
                mobile: 40, tablet: 50, desktop: 60,),
            backgroundColor: Colors.blue,
            child: ResponsiveText(
              'А',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                    mobile: 24, tablet: 30, desktop: 36,),
              ),
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveText(
            'Анна Петрова',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 20, tablet: 24, desktop: 28,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 8),
          ResponsiveText(
            'Ведущая мероприятий',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,),
              color: Colors.grey[600],
            ),
          ),
          const ResponsiveSpacing(height: 8),
          ResponsiveText(
            'Москва',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 12, tablet: 14, desktop: 16,),
              color: Colors.grey[600],
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveGrid(
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context,
                mobile: 2, desktop: 2,),
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
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 18, tablet: 20, desktop: 22,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveGrid(
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context,
                mobile: 2, tablet: 4, desktop: 4,),
            children: [
              _buildStatItem(context, 'Заявки', '12', Colors.blue),
              _buildStatItem(context, 'Отзывы', '8', Colors.green),
              _buildStatItem(context, 'Рейтинг', '4.9', Colors.orange),
              _buildStatItem(context, 'Подписчики', '156', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, Color color,) {
    return ResponsiveCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ResponsiveText(
            value,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 20, tablet: 24, desktop: 28,),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const ResponsiveSpacing(height: 8),
          ResponsiveText(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 12, tablet: 14, desktop: 16,),
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
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 18, tablet: 20, desktop: 22,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveList(
            children: [
              _buildActionItem(
                  context, 'Мои заявки', Icons.assignment, Colors.blue,),
              _buildActionItem(
                  context, 'Мои отзывы', Icons.star, Colors.orange,),
              _buildActionItem(
                  context, 'Настройки', Icons.settings, Colors.grey,),
              _buildActionItem(context, 'Помощь', Icons.help, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
      BuildContext context, String title, IconData icon, Color color,) {
    return ResponsiveCard(
      child: Row(
        children: [
          ResponsiveIcon(
            icon,
            color: color,
            size: ResponsiveUtils.getResponsiveIconSize(context,),
          ),
          const ResponsiveSpacing(width: 16),
          Expanded(
            child: ResponsiveText(
              title,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context,),
              ),
            ),
          ),
          const ResponsiveIcon(Icons.arrow_forward_ios),
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
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 18, tablet: 20, desktop: 22,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveList(
            children: [
              _buildPostItem(
                  context, 'Отличное мероприятие!', '2 дня назад', 15, 3,),
              _buildPostItem(
                  context, 'Новые фотографии', '1 неделя назад', 28, 7,),
              _buildPostItem(
                  context, 'Готовлюсь к свадьбе', '2 недели назад', 12, 2,),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, String title, String time,
      int likes, int comments,) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 16, tablet: 18, desktop: 20,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 8),
          ResponsiveText(
            time,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 12, tablet: 14, desktop: 16,),
              color: Colors.grey[600],
            ),
          ),
          const ResponsiveSpacing(height: 16),
          const ResponsiveDivider(),
          const ResponsiveSpacing(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                  context, Icons.thumb_up, '$likes', Colors.blue,),
              _buildActionButton(
                  context, Icons.comment, '$comments', Colors.green,),
              _buildActionButton(
                  context, Icons.share, 'Поделиться', Colors.orange,),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, IconData icon, String label, Color color,) {
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
