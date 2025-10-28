import 'package:event_marketplace_app/utils/responsive_utils.dart';
import 'package:event_marketplace_app/widgets/responsive/responsive_widgets.dart';
import 'package:flutter/material.dart';

/// Адаптивный экран заявок
class ResponsiveRequestsScreen extends StatelessWidget {
  const ResponsiveRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: const ResponsiveAppBar(
        title: 'Заявки',
        actions: [
          ResponsiveIcon(Icons.search),
          ResponsiveSpacing(width: 8),
          ResponsiveIcon(Icons.filter_list),
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
        _buildCreateRequestSection(context),
        _buildFiltersSection(context),
        _buildRequestsSection(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        crossAxisCount: 2,
        children: [
          _buildCreateRequestSection(context),
          _buildFiltersSection(context),
          _buildRequestsSection(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        crossAxisCount: 3,
        children: [
          _buildCreateRequestSection(context),
          _buildFiltersSection(context),
          _buildRequestsSection(context),
        ],
      ),
    );
  }

  Widget _buildCreateRequestSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Создать заявку',
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
                text: 'Новая заявка',
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
              _buildFilterChip(context, 'Активные', false),
              _buildFilterChip(context, 'Завершенные', false),
              _buildFilterChip(context, 'Отклоненные', false),
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

  Widget _buildRequestsSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Мои заявки',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 18, tablet: 20, desktop: 22,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveList(
            children: [
              _buildRequestItem(context, 'Ведущий на свадьбу', 'Активная',
                  '2 дня назад', 5, 2,),
              _buildRequestItem(context, 'Фотограф на корпоратив', 'Завершена',
                  '1 неделя назад', 3, 1,),
              _buildRequestItem(context, 'Кейтеринг на день рождения',
                  'Отклонена', '3 дня назад', 2, 0,),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(BuildContext context, String title, String status,
      String time, int responses, int selected,) {
    Color statusColor;
    switch (status) {
      case 'Активная':
        statusColor = Colors.green;
      case 'Завершена':
        statusColor = Colors.blue;
      case 'Отклонена':
        statusColor = Colors.red;
      default:
        statusColor = Colors.grey;
    }

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ResponsiveText(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                        mobile: 16, tablet: 18, desktop: 20,),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ResponsiveCard(
                child: ResponsiveText(
                  status,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                        mobile: 12, tablet: 14, desktop: 16,),
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Откликов: $responses',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                      mobile: 12, tablet: 14, desktop: 16,),
                  color: Colors.grey[600],
                ),
              ),
              ResponsiveText(
                'Выбрано: $selected',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                      mobile: 12, tablet: 14, desktop: 16,),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveGrid(
            crossAxisCount: ResponsiveUtils.getResponsiveColumns(context,
                mobile: 3, tablet: 3,),
            children: [
              ResponsiveButton(
                text: 'Подробнее',
                onPressed: () {},
                backgroundColor: Colors.blue,
              ),
              ResponsiveButton(
                text: 'Редактировать',
                onPressed: () {},
                backgroundColor: Colors.orange,
              ),
              ResponsiveButton(
                text: 'Удалить',
                onPressed: () {},
                backgroundColor: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
