import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_widgets.dart';

/// Адаптивный главный экран
class ResponsiveHomeScreen extends StatelessWidget {
  const ResponsiveHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: ResponsiveAppBar(
        title: 'Главная',
        actions: [
          ResponsiveIcon(Icons.search),
          ResponsiveSpacing(width: 8),
          ResponsiveIcon(Icons.notifications),
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
        _buildSearchSection(context),
        _buildCategoriesSection(context),
        _buildQuickActionsSection(context),
        _buildTopSpecialistsSection(context),
        _buildNearbySection(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        children: [
          _buildSearchSection(context),
          _buildCategoriesSection(context),
          _buildQuickActionsSection(context),
          _buildTopSpecialistsSection(context),
          _buildNearbySection(context),
        ],
        crossAxisCount: 2,
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        children: [
          _buildSearchSection(context),
          _buildCategoriesSection(context),
          _buildQuickActionsSection(context),
          _buildTopSpecialistsSection(context),
          _buildNearbySection(context),
        ],
        crossAxisCount: 3,
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Поиск специалистов',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Введите имя, город или специализацию',
              prefixIcon: ResponsiveIcon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getResponsiveBorderRadius(context),
                ),
              ),
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveButton(
            text: 'Найти',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Категории',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveGrid(
            children: [
              _buildCategoryItem(context, 'Ведущие', Icons.mic, Colors.blue),
              _buildCategoryItem(context, 'Фотографы', Icons.camera_alt, Colors.purple),
              _buildCategoryItem(context, 'Кейтеринг', Icons.restaurant, Colors.orange),
              _buildCategoryItem(context, 'Декор', Icons.celebration, Colors.pink),
              _buildCategoryItem(context, 'Музыка', Icons.music_note, Colors.green),
              _buildCategoryItem(context, 'Флористы', Icons.local_florist, Colors.teal),
            ],
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context, mobile: 2, tablet: 3, desktop: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String title, IconData icon, Color color) {
    return ResponsiveCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ResponsiveIcon(
            icon,
            color: color,
            size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 32.0, tablet: 36.0, desktop: 40.0),
          ),
          ResponsiveSpacing(height: 8),
          ResponsiveText(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Быстрые действия',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveGrid(
            children: [
              _buildQuickActionItem(context, 'Создать заявку', Icons.add_circle_outline, Colors.blue),
              _buildQuickActionItem(context, 'Найти специалиста', Icons.search, Colors.green),
              _buildQuickActionItem(context, 'Мои заявки', Icons.assignment, Colors.orange),
              _buildQuickActionItem(context, 'Избранное', Icons.favorite, Colors.red),
            ],
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context, mobile: 2, tablet: 4, desktop: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(BuildContext context, String title, IconData icon, Color color) {
    return ResponsiveCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ResponsiveIcon(
            icon,
            color: color,
            size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 28.0, tablet: 32.0, desktop: 36.0),
          ),
          ResponsiveSpacing(height: 8),
          ResponsiveText(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSpecialistsSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'ТОП специалисты',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveList(
            children: [
              _buildSpecialistItem(context, 'Анна Петрова', 'Ведущая', 4.9, 'Москва'),
              _buildSpecialistItem(context, 'Иван Сидоров', 'Фотограф', 4.8, 'Санкт-Петербург'),
              _buildSpecialistItem(context, 'Мария Козлова', 'Кейтеринг', 4.7, 'Казань'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistItem(BuildContext context, String name, String specialization, double rating, String city) {
    return ResponsiveCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveUtils.getResponsiveIconSize(context, mobile: 20.0, tablet: 24.0, desktop: 28.0),
            backgroundColor: Colors.blue,
            child: ResponsiveText(
              name[0],
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
                  name,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ResponsiveText(
                  specialization,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                    color: Colors.grey[600],
                  ),
                ),
                ResponsiveText(
                  '$rating ⭐ • $city',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ResponsiveButton(
            text: 'Подробнее',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNearbySection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Рядом с вами',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveText(
            'Специалисты в радиусе 5 км',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
              color: Colors.grey[600],
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveButton(
            text: 'Показать на карте',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
