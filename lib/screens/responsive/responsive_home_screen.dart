import 'package:event_marketplace_app/utils/responsive_utils.dart';
import 'package:event_marketplace_app/widgets/responsive/responsive_widgets.dart';
import 'package:flutter/material.dart';

/// Адаптивный главный экран
class ResponsiveHomeScreen extends StatelessWidget {
  const ResponsiveHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: const ResponsiveAppBar(
        title: 'Главная',
        actions: [
          ResponsiveIcon(Icons.search),
          ResponsiveSpacing(width: 8),
          ResponsiveIcon(Icons.notifications),
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
        crossAxisCount: 2,
        children: [
          _buildSearchSection(context),
          _buildCategoriesSection(context),
          _buildQuickActionsSection(context),
          _buildTopSpecialistsSection(context),
          _buildNearbySection(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        crossAxisCount: 3,
        children: [
          _buildSearchSection(context),
          _buildCategoriesSection(context),
          _buildQuickActionsSection(context),
          _buildTopSpecialistsSection(context),
          _buildNearbySection(context),
        ],
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
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 18, tablet: 20, desktop: 22,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Введите имя, город или специализацию',
              prefixIcon: const ResponsiveIcon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getResponsiveBorderRadius(context),
                ),
              ),
            ),
          ),
          const ResponsiveSpacing(height: 16),
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
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 18, tablet: 20, desktop: 22,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveGrid(
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context,
                mobile: 2, tablet: 3, desktop: 4,),
            children: [
              _buildCategoryItem(context, 'Ведущие', Icons.mic, Colors.blue),
              _buildCategoryItem(
                  context, 'Фотографы', Icons.camera_alt, Colors.purple,),
              _buildCategoryItem(
                  context, 'Кейтеринг', Icons.restaurant, Colors.orange,),
              _buildCategoryItem(
                  context, 'Декор', Icons.celebration, Colors.pink,),
              _buildCategoryItem(
                  context, 'Музыка', Icons.music_note, Colors.green,),
              _buildCategoryItem(
                  context, 'Флористы', Icons.local_florist, Colors.teal,),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
      BuildContext context, String title, IconData icon, Color color,) {
    return ResponsiveCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ResponsiveIcon(
            icon,
            color: color,
            size: ResponsiveUtils.getResponsiveIconSize(context,
                mobile: 32, tablet: 36, desktop: 40,),
          ),
          const ResponsiveSpacing(height: 8),
          ResponsiveText(
            title,
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

  Widget _buildQuickActionsSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Быстрые действия',
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
              _buildQuickActionItem(context, 'Создать заявку',
                  Icons.add_circle_outline, Colors.blue,),
              _buildQuickActionItem(
                  context, 'Найти специалиста', Icons.search, Colors.green,),
              _buildQuickActionItem(
                  context, 'Мои заявки', Icons.assignment, Colors.orange,),
              _buildQuickActionItem(
                  context, 'Избранное', Icons.favorite, Colors.red,),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
      BuildContext context, String title, IconData icon, Color color,) {
    return ResponsiveCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ResponsiveIcon(
            icon,
            color: color,
            size: ResponsiveUtils.getResponsiveIconSize(context,
                mobile: 28, tablet: 32, desktop: 36,),
          ),
          const ResponsiveSpacing(height: 8),
          ResponsiveText(
            title,
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

  Widget _buildTopSpecialistsSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'ТОП специалисты',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 18, tablet: 20, desktop: 22,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveList(
            children: [
              _buildSpecialistItem(
                  context, 'Анна Петрова', 'Ведущая', 4.9, 'Москва',),
              _buildSpecialistItem(
                  context, 'Иван Сидоров', 'Фотограф', 4.8, 'Санкт-Петербург',),
              _buildSpecialistItem(
                  context, 'Мария Козлова', 'Кейтеринг', 4.7, 'Казань',),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistItem(BuildContext context, String name,
      String specialization, double rating, String city,) {
    return ResponsiveCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveUtils.getResponsiveIconSize(context,
                mobile: 20, tablet: 24, desktop: 28,),
            backgroundColor: Colors.blue,
            child: ResponsiveText(
              name[0],
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
                  name,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context,),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ResponsiveText(
                  specialization,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                        mobile: 12, tablet: 14, desktop: 16,),
                    color: Colors.grey[600],
                  ),
                ),
                ResponsiveText(
                  '$rating ⭐ • $city',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                        mobile: 12, tablet: 14, desktop: 16,),
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
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 18, tablet: 20, desktop: 22,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveText(
            'Специалисты в радиусе 5 км',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,),
              color: Colors.grey[600],
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveButton(
            text: 'Показать на карте',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
