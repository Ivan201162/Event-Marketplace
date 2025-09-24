import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/specialist_service.dart';
import '../services/specialist_service_service.dart';
import '../widgets/enhanced_page_transition.dart';
import '../widgets/responsive_layout.dart';
import 'add_service_screen.dart';
import 'edit_service_screen.dart';

/// Экран управления услугами специалиста
class SpecialistServicesScreen extends ConsumerStatefulWidget {
  const SpecialistServicesScreen({
    super.key,
    required this.specialistId,
  });

  final String specialistId;

  @override
  ConsumerState<SpecialistServicesScreen> createState() => _SpecialistServicesScreenState();
}

class _SpecialistServicesScreenState extends ConsumerState<SpecialistServicesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final SpecialistServiceService _serviceService = SpecialistServiceService();
  String _searchQuery = '';
  String? _selectedCategory;
  ServicePriceType? _selectedPriceType;
  bool _showOnlyActive = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
        largeDesktop: _buildLargeDesktopLayout(),
      );

  Widget _buildMobileLayout() => Scaffold(
        appBar: AppBar(
          title: const Text('Мои услуги'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addService,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilters,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.list), text: 'Все'),
              Tab(icon: Icon(Icons.star), text: 'Популярные'),
              Tab(icon: Icon(Icons.analytics), text: 'Аналитика'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildServicesList(),
            _buildPopularServices(),
            _buildAnalytics(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addService,
          child: const Icon(Icons.add),
        ),
      );

  Widget _buildTabletLayout() => Scaffold(
        appBar: AppBar(
          title: const Text('Мои услуги'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addService,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilters,
            ),
          ],
        ),
        body: ResponsiveContainer(
          child: Column(
            children: [
              // Фильтры
              _buildFiltersBar(),
              // Вкладки
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.list), text: 'Все услуги'),
                  Tab(icon: Icon(Icons.star), text: 'Популярные'),
                  Tab(icon: Icon(Icons.analytics), text: 'Аналитика'),
                ],
              ),
              // Контент
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildServicesList(),
                    _buildPopularServices(),
                    _buildAnalytics(),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addService,
          icon: const Icon(Icons.add),
          label: const Text('Добавить услугу'),
        ),
      );

  Widget _buildDesktopLayout() => Scaffold(
        appBar: AppBar(
          title: const Text('Управление услугами'),
          actions: [
            ElevatedButton.icon(
              onPressed: _addService,
              icon: const Icon(Icons.add),
              label: const Text('Добавить услугу'),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilters,
            ),
          ],
        ),
        body: ResponsiveContainer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Левая панель с фильтрами
              SizedBox(
                width: 300,
                child: _buildFiltersPanel(),
              ),
              const SizedBox(width: 24),
              // Основной контент
              Expanded(
                child: Column(
                  children: [
                    // Вкладки
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.list), text: 'Все услуги'),
                        Tab(icon: Icon(Icons.star), text: 'Популярные'),
                        Tab(icon: Icon(Icons.analytics), text: 'Аналитика'),
                      ],
                    ),
                    // Контент
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildServicesList(),
                          _buildPopularServices(),
                          _buildAnalytics(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildLargeDesktopLayout() => Scaffold(
        appBar: AppBar(
          title: const Text('Управление услугами'),
          actions: [
            ElevatedButton.icon(
              onPressed: _addService,
              icon: const Icon(Icons.add),
              label: const Text('Добавить услугу'),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilters,
            ),
          ],
        ),
        body: ResponsiveContainer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Левая панель с фильтрами
              SizedBox(
                width: 350,
                child: _buildFiltersPanel(),
              ),
              const SizedBox(width: 32),
              // Основной контент
              Expanded(
                child: Column(
                  children: [
                    // Вкладки
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.list), text: 'Все услуги'),
                        Tab(icon: Icon(Icons.star), text: 'Популярные'),
                        Tab(icon: Icon(Icons.analytics), text: 'Аналитика'),
                      ],
                    ),
                    // Контент
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildServicesList(),
                          _buildPopularServices(),
                          _buildAnalytics(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Правая панель с аналитикой
              SizedBox(
                width: 300,
                child: _buildAnalyticsPanel(),
              ),
            ],
          ),
        ),
      );

  Widget _buildFiltersBar() => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Поиск услуг...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            FilterChip(
              label: const Text('Только активные'),
              selected: _showOnlyActive,
              onSelected: (selected) {
                setState(() {
                  _showOnlyActive = selected;
                });
              },
            ),
          ],
        ),
      );

  Widget _buildFiltersPanel() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Фильтры',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            // Поиск
            TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск услуг...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Категория
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Категория',
                border: OutlineInputBorder(),
              ),
              value: _selectedCategory,
              items: const [
                DropdownMenuItem(value: null, child: Text('Все категории')),
                DropdownMenuItem(value: 'photography', child: Text('Фотография')),
                DropdownMenuItem(value: 'videography', child: Text('Видеосъемка')),
                DropdownMenuItem(value: 'music', child: Text('Музыка')),
                DropdownMenuItem(value: 'decoration', child: Text('Оформление')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Тип цены
            DropdownButtonFormField<ServicePriceType>(
              decoration: const InputDecoration(
                labelText: 'Тип цены',
                border: OutlineInputBorder(),
              ),
              value: _selectedPriceType,
              items: ServicePriceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriceType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Только активные
            CheckboxListTile(
              title: const Text('Только активные'),
              value: _showOnlyActive,
              onChanged: (value) {
                setState(() {
                  _showOnlyActive = value ?? true;
                });
              },
            ),
            const SizedBox(height: 16),
            // Сбросить фильтры
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _resetFilters,
                child: const Text('Сбросить фильтры'),
              ),
            ),
          ],
        ),
      );

  Widget _buildServicesList() => StreamBuilder<List<SpecialistService>>(
        stream: _serviceService.getSpecialistServices(widget.specialistId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка загрузки услуг: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final services = snapshot.data ?? [];
          final filteredServices = _filterServices(services);

          if (filteredServices.isEmpty) {
            return _buildEmptyState();
          }

          return ResponsiveList(
            children: filteredServices.map(_buildServiceCard).toList(),
          );
        },
      );

  Widget _buildPopularServices() => StreamBuilder<List<SpecialistService>>(
        stream: _serviceService.getPopularServices(widget.specialistId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка загрузки популярных услуг: ${snapshot.error}'),
            );
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return _buildEmptyState(
              'Нет популярных услуг',
              'Популярные услуги появятся после получения заказов',
            );
          }

          return ResponsiveList(
            children: services.map(_buildServiceCard).toList(),
          );
        },
      );

  Widget _buildAnalytics() => ResponsiveList(
        children: [
          _buildAnalyticsCard(),
          _buildPriceAnalysisCard(),
          _buildPerformanceCard(),
        ],
      );

  Widget _buildAnalyticsPanel() => Column(
        children: [
          const SizedBox(height: 20),
          _buildAnalyticsCard(),
          const SizedBox(height: 24),
          _buildPriceAnalysisCard(),
          const SizedBox(height: 24),
          _buildPerformanceCard(),
        ],
      );

  Widget _buildServiceCard(SpecialistService service) => AnimatedContent(
        delay: Duration(milliseconds: 100),
        type: AnimationType.slideUp,
        child: ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          service.name,
                          isTitle: true,
                        ),
                        const SizedBox(height: 4),
                        ResponsiveText(
                          service.description,
                          isSubtitle: true,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  // Статус
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(service.statusColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      service.statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Цена и тип
              Row(
                children: [
                  ResponsiveText(
                    service.formattedPrice,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (service.hasDiscount) ...[
                    ResponsiveText(
                      service.formattedOriginalPrice!,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        service.formattedDiscountPercentage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              ResponsiveText(
                service.priceTypeDisplayName,
                isSubtitle: true,
              ),
              const SizedBox(height: 16),
              // Статистика
              Row(
                children: [
                  _buildStatChip(Icons.shopping_cart, '${service.bookingCount}'),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.star, service.rating.toStringAsFixed(1)),
                  const SizedBox(width: 8),
                  if (service.durationRange != null)
                    _buildStatChip(Icons.access_time, service.durationRange!),
                ],
              ),
              const SizedBox(height: 16),
              // Действия
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editService(service),
                      icon: const Icon(Icons.edit),
                      label: const Text('Редактировать'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _duplicateService(service),
                      icon: const Icon(Icons.copy),
                      label: const Text('Дублировать'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStatChip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildAnalyticsCard() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Общая статистика',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Всего услуг', '12'),
            _buildStatRow('Активных услуг', '10'),
            _buildStatRow('Популярных услуг', '3'),
            _buildStatRow('Общий доход', '125,000 ₽'),
            _buildStatRow('Средний рейтинг', '4.8 ⭐'),
          ],
        ),
      );

  Widget _buildPriceAnalysisCard() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Анализ цен',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Средняя цена', '8,500 ₽'),
            _buildStatRow('Минимальная цена', '3,000 ₽'),
            _buildStatRow('Максимальная цена', '25,000 ₽'),
            _buildStatRow('Цены обновлены', '2 дня назад'),
          ],
        ),
      );

  Widget _buildPerformanceCard() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Производительность',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Заказов в месяц', '24'),
            _buildStatRow('Конверсия', '12%'),
            _buildStatRow('Повторные клиенты', '35%'),
            _buildStatRow('Время ответа', '2 часа'),
          ],
        ),
      );

  Widget _buildStatRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(label, isSubtitle: true),
            ResponsiveText(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _buildEmptyState([String? title, String? subtitle]) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            ResponsiveText(
              title ?? 'Нет услуг',
              isTitle: true,
            ),
            const SizedBox(height: 8),
            ResponsiveText(
              subtitle ?? 'Добавьте свои первые услуги, чтобы начать получать заказы',
              isSubtitle: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addService,
              icon: const Icon(Icons.add),
              label: const Text('Добавить услугу'),
            ),
          ],
        ),
      );

  Color _getStatusColor(String statusColor) {
    switch (statusColor) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  List<SpecialistService> _filterServices(List<SpecialistService> services) {
    return services.where((service) {
      // Поиск
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!service.name.toLowerCase().contains(query) &&
            !service.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Категория
      if (_selectedCategory != null && service.category != _selectedCategory) {
        return false;
      }

      // Тип цены
      if (_selectedPriceType != null && service.priceType != _selectedPriceType) {
        return false;
      }

      // Только активные
      if (_showOnlyActive && !service.isActive) {
        return false;
      }

      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _selectedPriceType = null;
      _showOnlyActive = true;
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Фильтры',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Здесь можно добавить дополнительные фильтры
            const Text('Фильтры будут добавлены в следующей версии'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addService() {
    Navigator.of(context).push(
      EnhancedPageTransition(
        child: AddServiceScreen(specialistId: widget.specialistId),
        type: PageTransitionType.slideUp,
      ),
    );
  }

  void _editService(SpecialistService service) {
    Navigator.of(context).push(
      EnhancedPageTransition(
        child: EditServiceScreen(service: service),
        type: PageTransitionType.slideUp,
      ),
    );
  }

  void _duplicateService(SpecialistService service) {
    // TODO: Реализовать дублирование услуги
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция дублирования будет добавлена')),
    );
  }
}