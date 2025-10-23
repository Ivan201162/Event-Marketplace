import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_widgets.dart';

/// Адаптивный экран идей
class ResponsiveIdeasScreen extends StatelessWidget {
  const ResponsiveIdeasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: ResponsiveAppBar(
        title: 'Идеи',
        actions: [
          ResponsiveIcon(Icons.search),
          ResponsiveSpacing(width: 8),
          ResponsiveIcon(Icons.add_circle_outline),
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
        _buildCreateIdeaSection(context),
        _buildFiltersSection(context),
        _buildIdeasSection(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        children: [
          _buildCreateIdeaSection(context),
          _buildFiltersSection(context),
          _buildIdeasSection(context),
        ],
        crossAxisCount: 2,
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        children: [
          _buildCreateIdeaSection(context),
          _buildFiltersSection(context),
          _buildIdeasSection(context),
        ],
        crossAxisCount: 3,
      ),
    );
  }

  Widget _buildCreateIdeaSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Создать идею',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveGrid(
            children: [
              ResponsiveButton(
                text: 'Новая идея',
                onPressed: () {},
                backgroundColor: Colors.blue,
              ),
              ResponsiveButton(
                text: 'Шаблоны',
                onPressed: () {},
                backgroundColor: Colors.green,
              ),
            ],
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context,
                mobile: 2, tablet: 2, desktop: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Фильтры',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveGrid(
            children: [
              _buildFilterChip(context, 'Все', true),
              _buildFilterChip(context, 'Мои', false),
              _buildFilterChip(context, 'Популярные', false),
              _buildFilterChip(context, 'Недавние', false),
            ],
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context,
                mobile: 2, tablet: 4, desktop: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected) {
    return ResponsiveCard(
      child: ResponsiveButton(
        text: label,
        onPressed: () {},
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        textColor: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildIdeasSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Идеи',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveList(
            children: [
              _buildIdeaItem(context, 'Свадьба в стиле ретро', 'Анна Петрова',
                  '2 дня назад', 15, 3, true),
              _buildIdeaItem(context, 'Корпоратив на природе', 'Иван Сидоров',
                  '4 дня назад', 28, 7, false),
              _buildIdeaItem(context, 'День рождения в кафе', 'Мария Козлова',
                  '1 неделя назад', 12, 2, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaItem(BuildContext context, String title, String author,
      String time, int likes, int comments, bool isLiked) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: ResponsiveUtils.getResponsiveIconSize(context,
                    mobile: 20.0, tablet: 24.0, desktop: 28.0),
                backgroundColor: Colors.blue,
                child: ResponsiveText(
                  author[0],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                        mobile: 14.0, tablet: 16.0, desktop: 18.0),
                  ),
                ),
              ),
              ResponsiveSpacing(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      author,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                            mobile: 14.0, tablet: 16.0, desktop: 18.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveText(
                      time,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                            mobile: 12.0, tablet: 14.0, desktop: 16.0),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ResponsiveIcon(Icons.more_vert),
            ],
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveText(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 16.0, tablet: 18.0, desktop: 20.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 8),
          ResponsiveText(
            'Отличная идея для организации мероприятия!',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 14.0, tablet: 16.0, desktop: 18.0),
              color: Colors.grey[600],
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveDivider(),
          ResponsiveSpacing(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                  context, Icons.thumb_up, '$likes', Colors.blue, isLiked),
              _buildActionButton(
                  context, Icons.comment, '$comments', Colors.green, false),
              _buildActionButton(
                  context, Icons.share, 'Поделиться', Colors.orange, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label,
      Color color, bool isActive) {
    return ResponsiveButton(
      text: label,
      onPressed: () {},
      backgroundColor: isActive ? color : Colors.transparent,
      textColor: isActive ? Colors.white : color,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context),
        vertical: ResponsiveUtils.getResponsiveSpacing(context) / 2,
      ),
    );
  }
}
