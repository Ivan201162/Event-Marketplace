import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/integration.dart';
import '../services/integration_service.dart';
import '../widgets/integration_widget.dart';
import 'integration_detail_screen.dart';

/// Экран интеграций
class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen> {
  final IntegrationService _integrationService = IntegrationService();

  IntegrationType? _selectedType;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Интеграции'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Быстрые действия
          _buildQuickActions(),

          // Типы интеграций
          _buildTypeSelector(),

          // Список интеграций
          Expanded(
            child: _buildIntegrationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.location_on,
              title: 'Геолокация',
              color: Colors.blue,
              onTap: _showLocationSettings,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.share,
              title: 'Шаринг',
              color: Colors.green,
              onTap: _showSharingOptions,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.wifi,
              title: 'Подключение',
              color: Colors.orange,
              onTap: _showConnectionStatus,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: IntegrationType.values.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedType == null;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Все'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = null;
                  });
                },
              ),
            );
          }

          final type = IntegrationType.values[index - 1];
          final isSelected = _selectedType == type;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getTypeText(type)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedType = selected ? type : null;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntegrationsList() {
    return StreamBuilder<List<Integration>>(
      stream: _integrationService.getAvailableIntegrations(),
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
                Text('Ошибка: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final integrations = snapshot.data ?? [];
        final filteredIntegrations = _filterIntegrations(integrations);

        if (filteredIntegrations.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: filteredIntegrations.length,
          itemBuilder: (context, index) {
            final integration = filteredIntegrations[index];
            return IntegrationWidget(
              integration: integration,
              onTap: () => _showIntegrationDetail(integration),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.extension, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Нет интеграций',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Попробуйте изменить фильтры или поисковый запрос',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Integration> _filterIntegrations(List<Integration> integrations) {
    var filtered = integrations;

    // Фильтр по типу
    if (_selectedType != null) {
      filtered = filtered
          .where((integration) => integration.type == _selectedType)
          .toList();
    }

    // Фильтр по поисковому запросу
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((integration) {
        return integration.name.toLowerCase().contains(query) ||
            integration.description.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  String _getTypeText(IntegrationType type) {
    switch (type) {
      case IntegrationType.maps:
        return 'Карты';
      case IntegrationType.social:
        return 'Социальные';
      case IntegrationType.payment:
        return 'Платежи';
      case IntegrationType.calendar:
        return 'Календарь';
      case IntegrationType.email:
        return 'Email';
      case IntegrationType.sms:
        return 'SMS';
      case IntegrationType.analytics:
        return 'Аналитика';
      case IntegrationType.storage:
        return 'Хранилище';
      case IntegrationType.other:
        return 'Другое';
    }
  }

  void _showIntegrationDetail(Integration integration) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IntegrationDetailScreen(
          integration: integration,
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск интеграций'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Введите поисковый запрос...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Поиск'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтр интеграций'),
        content: const Text('Фильтры уже применены в интерфейсе'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showLocationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки геолокации'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Разрешить доступ к геолокации'),
            Text('• Использовать для поиска событий рядом'),
            Text('• Показывать местоположение на карте'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestLocationPermission();
            },
            child: const Text('Разрешить'),
          ),
        ],
      ),
    );
  }

  void _showSharingOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки шаринга'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Поделиться событием'),
            Text('• Поделиться профилем'),
            Text('• Поделиться отзывом'),
            Text('• Поделиться идеей'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showConnectionStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статус подключения'),
        content: FutureBuilder<bool>(
          future: _integrationService.isConnectedToInternet(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final isConnected = snapshot.data ?? false;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  size: 48,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  isConnected
                      ? 'Подключено к интернету'
                      : 'Нет подключения к интернету',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    try {
      final location = await _integrationService.getCurrentLocation();
      if (location != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Геолокация получена успешно'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось получить геолокацию'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
