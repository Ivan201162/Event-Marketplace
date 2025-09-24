import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist_service.dart';
import '../services/specialist_service_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран добавления новой услуги
class AddServiceScreen extends ConsumerStatefulWidget {
  const AddServiceScreen({
    super.key,
    required this.specialistId,
  });

  final String specialistId;

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountController = TextEditingController();
  final _durationController = TextEditingController();
  final _minDurationController = TextEditingController();
  final _maxDurationController = TextEditingController();
  
  final SpecialistServiceService _serviceService = SpecialistServiceService();
  
  ServicePriceType _selectedPriceType = ServicePriceType.fixed;
  PriceUnit _selectedCurrency = PriceUnit.rubles;
  String? _selectedCategory;
  String? _selectedSubcategory;
  
  final List<String> _requirements = [];
  final List<String> _includes = [];
  final List<String> _excludes = [];
  final List<String> _tags = [];
  final List<String> _images = [];
  final List<String> _videos = [];
  
  bool _isActive = true;
  bool _isPopular = false;
  bool _isRecommended = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _discountController.dispose();
    _durationController.dispose();
    _minDurationController.dispose();
    _maxDurationController.dispose();
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
          title: const Text('Добавить услугу'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveService,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
          ],
        ),
        body: _buildForm(),
      );

  Widget _buildTabletLayout() => Scaffold(
        appBar: AppBar(
          title: const Text('Добавить услугу'),
          actions: [
            ElevatedButton(
              onPressed: _isLoading ? null : _saveService,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
          ],
        ),
        body: ResponsiveContainer(
          child: _buildForm(),
        ),
      );

  Widget _buildDesktopLayout() => Scaffold(
        appBar: AppBar(
          title: const Text('Добавить услугу'),
          actions: [
            ElevatedButton(
              onPressed: _isLoading ? null : _saveService,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
          ],
        ),
        body: ResponsiveContainer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная форма
              Expanded(
                flex: 2,
                child: _buildForm(),
              ),
              const SizedBox(width: 24),
              // Боковая панель с дополнительными настройками
              SizedBox(
                width: 300,
                child: _buildSidebar(),
              ),
            ],
          ),
        ),
      );

  Widget _buildLargeDesktopLayout() => Scaffold(
        appBar: AppBar(
          title: const Text('Добавить услугу'),
          actions: [
            ElevatedButton(
              onPressed: _isLoading ? null : _saveService,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
          ],
        ),
        body: ResponsiveContainer(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная форма
              Expanded(
                flex: 3,
                child: _buildForm(),
              ),
              const SizedBox(width: 32),
              // Боковая панель с дополнительными настройками
              SizedBox(
                width: 350,
                child: _buildSidebar(),
              ),
            ],
          ),
        ),
      );

  Widget _buildForm() => Form(
        key: _formKey,
        child: ResponsiveList(
          children: [
            // Основная информация
            ResponsiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ResponsiveText(
                    'Основная информация',
                    isTitle: true,
                  ),
                  const SizedBox(height: 16),
                  // Название услуги
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название услуги *',
                      hintText: 'Например: Свадебная фотосъемка',
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
                  // Описание
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Описание услуги *',
                      hintText: 'Подробное описание услуги',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите описание услуги';
                      }
                      return null;
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
                      DropdownMenuItem(value: 'photography', child: Text('Фотография')),
                      DropdownMenuItem(value: 'videography', child: Text('Видеосъемка')),
                      DropdownMenuItem(value: 'music', child: Text('Музыка')),
                      DropdownMenuItem(value: 'decoration', child: Text('Оформление')),
                      DropdownMenuItem(value: 'catering', child: Text('Кейтеринг')),
                      DropdownMenuItem(value: 'entertainment', child: Text('Развлечения')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Ценообразование
            ResponsiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ResponsiveText(
                    'Ценообразование',
                    isTitle: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Тип цены
                      Expanded(
                        child: DropdownButtonFormField<ServicePriceType>(
                          decoration: const InputDecoration(
                            labelText: 'Тип цены *',
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
                              _selectedPriceType = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Валюта
                      Expanded(
                        child: DropdownButtonFormField<PriceUnit>(
                          decoration: const InputDecoration(
                            labelText: 'Валюта',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCurrency,
                          items: PriceUnit.values.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit.displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCurrency = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Цена
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Цена *',
                            hintText: '0',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите цену';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Введите корректную цену';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Оригинальная цена
                      Expanded(
                        child: TextFormField(
                          controller: _originalPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Оригинальная цена',
                            hintText: '0',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Скидка
                  TextFormField(
                    controller: _discountController,
                    decoration: const InputDecoration(
                      labelText: 'Скидка (%)',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            // Длительность и требования
            ResponsiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ResponsiveText(
                    'Длительность и требования',
                    isTitle: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Длительность
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(
                            labelText: 'Длительность',
                            hintText: 'Например: 4 часа',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Минимальная длительность
                      Expanded(
                        child: TextFormField(
                          controller: _minDurationController,
                          decoration: const InputDecoration(
                            labelText: 'Мин. длительность (часы)',
                            hintText: '0',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Максимальная длительность
                      Expanded(
                        child: TextFormField(
                          controller: _maxDurationController,
                          decoration: const InputDecoration(
                            labelText: 'Макс. длительность (часы)',
                            hintText: '0',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Требования
                  _buildListField(
                    'Требования',
                    _requirements,
                    'Добавить требование',
                    Icons.checklist,
                  ),
                  const SizedBox(height: 16),
                  // Что включено
                  _buildListField(
                    'Что включено',
                    _includes,
                    'Добавить пункт',
                    Icons.check_circle,
                  ),
                  const SizedBox(height: 16),
                  // Что не включено
                  _buildListField(
                    'Что не включено',
                    _excludes,
                    'Добавить пункт',
                    Icons.cancel,
                  ),
                ],
              ),
            ),
            // Теги и медиа
            ResponsiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ResponsiveText(
                    'Теги и медиа',
                    isTitle: true,
                  ),
                  const SizedBox(height: 16),
                  // Теги
                  _buildListField(
                    'Теги',
                    _tags,
                    'Добавить тег',
                    Icons.tag,
                  ),
                  const SizedBox(height: 16),
                  // Изображения
                  _buildMediaField(
                    'Изображения',
                    _images,
                    'Добавить изображение',
                    Icons.image,
                  ),
                  const SizedBox(height: 16),
                  // Видео
                  _buildMediaField(
                    'Видео',
                    _videos,
                    'Добавить видео',
                    Icons.video_library,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildSidebar() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResponsiveText(
              'Дополнительные настройки',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            // Статус услуги
            SwitchListTile(
              title: const Text('Активная услуга'),
              subtitle: const Text('Услуга доступна для заказа'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Популярная услуга'),
              subtitle: const Text('Отметить как популярную'),
              value: _isPopular,
              onChanged: (value) {
                setState(() {
                  _isPopular = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Рекомендуемая услуга'),
              subtitle: const Text('Отметить как рекомендуемую'),
              value: _isRecommended,
              onChanged: (value) {
                setState(() {
                  _isRecommended = value;
                });
              },
            ),
            const SizedBox(height: 24),
            // Предварительный просмотр
            const ResponsiveText(
              'Предварительный просмотр',
              isTitle: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    _nameController.text.isEmpty ? 'Название услуги' : _nameController.text,
                    isTitle: true,
                  ),
                  const SizedBox(height: 8),
                  ResponsiveText(
                    _descriptionController.text.isEmpty 
                        ? 'Описание услуги' 
                        : _descriptionController.text,
                    isSubtitle: true,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ResponsiveText(
                        _priceController.text.isEmpty 
                            ? '0 ₽' 
                            : '${_priceController.text} ${_selectedCurrency.symbol}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ResponsiveText(
                        _selectedPriceType.displayName,
                        isSubtitle: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildListField(
    String title,
    List<String> items,
    String addButtonText,
    IconData icon,
  ) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          // Список элементов
          if (items.isNotEmpty) ...[
            ...items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            items.remove(item);
                          });
                        },
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
          ],
          // Кнопка добавления
          OutlinedButton.icon(
            onPressed: () => _addListItem(items, addButtonText),
            icon: const Icon(Icons.add),
            label: Text(addButtonText),
          ),
        ],
      );

  Widget _buildMediaField(
    String title,
    List<String> items,
    String addButtonText,
    IconData icon,
  ) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          // Список медиа
          if (items.isNotEmpty) ...[
            ...items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            items.remove(item);
                          });
                        },
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
          ],
          // Кнопка добавления
          OutlinedButton.icon(
            onPressed: () => _addMediaItem(items, addButtonText),
            icon: const Icon(Icons.add),
            label: Text(addButtonText),
          ),
        ],
      );

  void _addListItem(List<String> items, String addButtonText) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(addButtonText),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Введите текст',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  items.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _addMediaItem(List<String> items, String addButtonText) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(addButtonText),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Введите URL медиа файла',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  items.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = SpecialistService(
        id: '', // Будет установлен Firestore
        specialistId: widget.specialistId,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        priceType: _selectedPriceType,
        originalPrice: _originalPriceController.text.isNotEmpty
            ? double.parse(_originalPriceController.text)
            : null,
        discount: _discountController.text.isNotEmpty
            ? int.parse(_discountController.text)
            : null,
        currency: _selectedCurrency,
        duration: _durationController.text.isNotEmpty ? _durationController.text : null,
        minDuration: _minDurationController.text.isNotEmpty
            ? int.parse(_minDurationController.text)
            : null,
        maxDuration: _maxDurationController.text.isNotEmpty
            ? int.parse(_maxDurationController.text)
            : null,
        requirements: _requirements,
        includes: _includes,
        excludes: _excludes,
        images: _images,
        videos: _videos,
        tags: _tags,
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        isActive: _isActive,
        isPopular: _isPopular,
        isRecommended: _isRecommended,
        createdAt: DateTime.now(),
      );

      await _serviceService.createService(service);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Услуга успешно добавлена'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления услуги: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
