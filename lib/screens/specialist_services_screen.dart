import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive_utils.dart';
import '../models/service_template.dart';
import '../services/service_template_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран управления услугами и ценами специалиста
class SpecialistServicesScreen extends ConsumerStatefulWidget {
  const SpecialistServicesScreen({
    super.key,
    required this.specialistId,
  });
  final String specialistId;

  @override
  ConsumerState<SpecialistServicesScreen> createState() => _SpecialistServicesScreenState();
}

class _SpecialistServicesScreenState extends ConsumerState<SpecialistServicesScreen> {
  final ServiceTemplateService _templateService = ServiceTemplateService();
  final SpecialistServiceService _serviceService = SpecialistServiceService();

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
        largeDesktop: _buildLargeDesktopLayout(context),
      );

  Widget _buildMobileLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Услуги и цены'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddServiceDialog(context),
            ),
          ],
        ),
        body: _buildContent(),
      );

  Widget _buildTabletLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Услуги и цены'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showAddServiceDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Добавить услугу'),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: ResponsiveContainer(
          child: _buildContent(),
        ),
      );

  Widget _buildDesktopLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Услуги и цены'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showAddServiceDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Добавить услугу'),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: ResponsiveContainer(
          child: _buildContent(),
        ),
      );

  Widget _buildLargeDesktopLayout(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Услуги и цены'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showAddServiceDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Добавить услугу'),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: ResponsiveContainer(
          child: _buildContent(),
        ),
      );

  Widget _buildContent() => Column(
        children: [
          // Заголовок с информацией
          ResponsiveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 12),
                    Expanded(
                      child: ResponsiveText(
                        'Управление услугами и ценами',
                        isTitle: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Укажите цены для всех ваших услуг. Цены обязательны и не могут быть "по договорённости".',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Обновляйте цены регулярно для привлечения клиентов',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Список услуг
          Expanded(
            child: FutureBuilder<List<SpecialistService>>(
              future: _serviceService.getSpecialistServices(widget.specialistId),
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

                final services = snapshot.data ?? [];

                if (services.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.work_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text('У вас пока нет услуг'),
                        const SizedBox(height: 8),
                        const Text(
                          'Добавьте услуги, чтобы клиенты могли их заказать',
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddServiceDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить услугу'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _buildServiceCard(service);
                  },
                );
              },
            ),
          ),
        ],
      );

  Widget _buildServiceCard(SpecialistService service) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        service.serviceName,
                        isTitle: true,
                      ),
                      const SizedBox(height: 4),
                      ResponsiveText(
                        service.description,
                        isSubtitle: true,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleServiceAction(value, service),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Редактировать'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Удалить'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Цены
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveText(
                          'Цена: ${service.priceRange}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (service.priceMin != service.priceMax)
                          ResponsiveText(
                            'Средняя: ${service.averagePrice.toStringAsFixed(0)} ${service.currency}',
                            isSubtitle: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Детали ценообразования
            if (service.pricingDetails.isNotEmpty) ...[
              const ResponsiveText(
                'Детали ценообразования:',
                isSubtitle: true,
              ),
              const SizedBox(height: 4),
              ...service.pricingDetails.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 2),
                  child: ResponsiveText(
                    '${entry.key}: ${entry.value}',
                    isSubtitle: true,
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  void _handleServiceAction(String action, SpecialistService service) {
    switch (action) {
      case 'edit':
        _showEditServiceDialog(context, service);
        break;
      case 'delete':
        _showDeleteServiceDialog(context, service);
        break;
    }
  }

  void _showAddServiceDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => _ServiceDialog(
        specialistId: widget.specialistId,
        onServiceAdded: () => setState(() {}),
      ),
    );
  }

  void _showEditServiceDialog(BuildContext context, SpecialistService service) {
    showDialog<void>(
      context: context,
      builder: (context) => _ServiceDialog(
        specialistId: widget.specialistId,
        service: service,
        onServiceUpdated: () => setState(() {}),
      ),
    );
  }

  void _showDeleteServiceDialog(
    BuildContext context,
    SpecialistService service,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить услугу'),
        content: Text(
          'Вы уверены, что хотите удалить услугу "${service.serviceName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _serviceService.deleteSpecialistService(
                  widget.specialistId,
                  service.id,
                );
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Услуга удалена')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

/// Диалог для добавления/редактирования услуги
class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({
    required this.specialistId,
    this.service,
    this.onServiceAdded,
    this.onServiceUpdated,
  });
  final String specialistId;
  final SpecialistService? service;
  final VoidCallback? onServiceAdded;
  final VoidCallback? onServiceUpdated;

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();

  final SpecialistServiceService _serviceService = SpecialistServiceService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _serviceNameController.text = widget.service!.serviceName;
      _descriptionController.text = widget.service!.description;
      _priceMinController.text = widget.service!.priceMin.toString();
      _priceMaxController.text = widget.service!.priceMax.toString();
    }
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _descriptionController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
          widget.service == null ? 'Добавить услугу' : 'Редактировать услугу',
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _serviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Название услуги *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название услуги';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание услуги *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите описание услуги';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceMinController,
                      decoration: const InputDecoration(
                        labelText: 'Минимальная цена *',
                        border: OutlineInputBorder(),
                        suffixText: '₽',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите минимальную цену';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Цена должна быть больше 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceMaxController,
                      decoration: const InputDecoration(
                        labelText: 'Максимальная цена *',
                        border: OutlineInputBorder(),
                        suffixText: '₽',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите максимальную цену';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Цена должна быть больше 0';
                        }

                        final minPrice = double.tryParse(_priceMinController.text);
                        if (minPrice != null && price < minPrice) {
                          return 'Максимальная цена не может быть меньше минимальной';
                        }

                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Цены обязательны и не могут быть "по договорённости"',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveService,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.service == null ? 'Добавить' : 'Сохранить'),
          ),
        ],
      );

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final service = SpecialistService(
        id: widget.service?.id ?? '',
        specialistId: widget.specialistId,
        serviceName: _serviceNameController.text.trim(),
        description: _descriptionController.text.trim(),
        priceMin: double.parse(_priceMinController.text),
        priceMax: double.parse(_priceMaxController.text),
        createdAt: widget.service?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.service == null) {
        await _serviceService.createSpecialistService(
          widget.specialistId,
          service,
        );
        widget.onServiceAdded?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Услуга добавлена')),
        );
      } else {
        await _serviceService.updateSpecialistService(
          widget.specialistId,
          widget.service!.id,
          service,
        );
        widget.onServiceUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Услуга обновлена')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
