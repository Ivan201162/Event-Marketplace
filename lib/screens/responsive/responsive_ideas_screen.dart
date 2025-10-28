import 'package:event_marketplace_app/utils/responsive_utils.dart';
import 'package:event_marketplace_app/widgets/responsive/responsive_widgets.dart';
import 'package:flutter/material.dart';

/// Адаптивный экран идей
class ResponsiveIdeasScreen extends StatelessWidget {
  const ResponsiveIdeasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: const ResponsiveAppBar(
        title: 'Идеи',
        actions: [
          ResponsiveIcon(Icons.search),
          ResponsiveSpacing(width: 8),
          ResponsiveIcon(Icons.add_circle_outline),
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
        _buildCreateIdeaSection(context),
        _buildFiltersSection(context),
        _buildIdeasSection(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        crossAxisCount: 2,
        children: [
          _buildCreateIdeaSection(context),
          _buildFiltersSection(context),
          _buildIdeasSection(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        crossAxisCount: 3,
        children: [
          _buildCreateIdeaSection(context),
          _buildFiltersSection(context),
          _buildIdeasSection(context),
        ],
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
                  mobile: 18, tablet: 20, desktop: 22,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveGrid(
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context,
                mobile: 2, desktop: 2,),
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
                  mobile: 18, tablet: 20, desktop: 22,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveGrid(
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context,
                mobile: 2, tablet: 4, desktop: 4,),
            children: [
              _buildFilterChip(context, 'Все', true),
              _buildFilterChip(context, 'Мои', false),
              _buildFilterChip(context, 'Популярные', false),
              _buildFilterChip(context, 'Недавние', false),
            ],
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
                  mobile: 18, tablet: 20, desktop: 22,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveList(
            children: [
              _buildIdeaItem(context, 'Свадьба в стиле ретро', 'Анна Петрова',
                  '2 дня назад', 15, 3, true,),
              _buildIdeaItem(context, 'Корпоратив на природе', 'Иван Сидоров',
                  '4 дня назад', 28, 7, false,),
              _buildIdeaItem(context, 'День рождения в кафе', 'Мария Козлова',
                  '1 неделя назад', 12, 2, false,),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaItem(BuildContext context, String title, String author,
      String time, int likes, int comments, bool isLiked,) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: ResponsiveUtils.getResponsiveIconSize(context,
                    mobile: 20, tablet: 24, desktop: 28,),
                backgroundColor: Colors.blue,
                child: ResponsiveText(
                  author[0],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context,),
                  ),
                ),
              ),
              const ResponsiveSpacing(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      author,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context,),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveText(
                      time,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                            mobile: 12, tablet: 14, desktop: 16,),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const ResponsiveIcon(Icons.more_vert),
            ],
          ),
          const ResponsiveSpacing(height: 16),
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
            'Отличная идея для организации мероприятия!',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,),
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
                  context, Icons.thumb_up, '$likes', Colors.blue, isLiked,),
              _buildActionButton(
                  context, Icons.comment, '$comments', Colors.green, false,),
              _buildActionButton(
                  context, Icons.share, 'Поделиться', Colors.orange, false,),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label,
      Color color, bool isActive,) {
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
