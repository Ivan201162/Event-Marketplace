import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_widgets.dart';

/// Адаптивный экран ленты
class ResponsiveFeedScreen extends StatelessWidget {
  const ResponsiveFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: ResponsiveAppBar(
        title: 'Лента',
        actions: [
          ResponsiveIcon(Icons.search),
          ResponsiveSpacing(width: 8),
          ResponsiveIcon(Icons.filter_list),
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
        _buildCreatePostSection(context),
        _buildFiltersSection(context),
        _buildPostsSection(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        children: [
          _buildCreatePostSection(context),
          _buildFiltersSection(context),
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
          _buildCreatePostSection(context),
          _buildFiltersSection(context),
          _buildPostsSection(context),
        ],
        crossAxisCount: 3,
      ),
    );
  }

  Widget _buildCreatePostSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Создать пост',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Что у вас нового?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getResponsiveBorderRadius(context),
                ),
              ),
            ),
            maxLines: 3,
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveGrid(
            children: [
              ResponsiveButton(
                text: 'Фото',
                onPressed: () {},
                backgroundColor: Colors.blue,
              ),
              ResponsiveButton(
                text: 'Видео',
                onPressed: () {},
                backgroundColor: Colors.red,
              ),
              ResponsiveButton(
                text: 'Поделиться',
                onPressed: () {},
                backgroundColor: Colors.green,
              ),
            ],
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context, mobile: 3, tablet: 3, desktop: 3),
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
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
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
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context, mobile: 2, tablet: 4, desktop: 4),
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

  Widget _buildPostsSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Посты',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveList(
            children: [
              _buildPostItem(context, 'Анна Петрова', 'Отличное мероприятие!', '2 часа назад', 15, 3),
              _buildPostItem(context, 'Иван Сидоров', 'Новые фотографии с свадьбы', '4 часа назад', 28, 7),
              _buildPostItem(context, 'Мария Козлова', 'Готовлю кейтеринг для корпоратива', '6 часов назад', 12, 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, String author, String content, String time, int likes, int comments) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: ResponsiveUtils.getResponsiveIconSize(context, mobile: 20.0, tablet: 24.0, desktop: 28.0),
                backgroundColor: Colors.blue,
                child: ResponsiveText(
                  author[0],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
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
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveText(
                      time,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
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
            content,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
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
