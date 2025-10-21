import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/advertisement.dart';
import '../../services/advertisement_service.dart';

class CreateAdvertisementScreen extends StatefulWidget {
  const CreateAdvertisementScreen({super.key});

  @override
  State<CreateAdvertisementScreen> createState() => _CreateAdvertisementScreenState();
}

class _CreateAdvertisementScreenState extends State<CreateAdvertisementScreen> {
  final AdvertisementService _advertisementService = AdvertisementService();
  final _formKey = GlobalKey<FormState>();

  // Контроллеры формы
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _budgetController = TextEditingController();
  final _targetUrlController = TextEditingController();

  // Выбранные значения
  AdType _selectedType = AdType.banner;
  AdPlacement _selectedPlacement = AdPlacement.topBanner;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedCategory;
  String? _selectedTargetAudience;

  bool _isLoading = false;

  // Списки для выбора
  final List<String> _regions = ['Москва', 'Санкт-Петербург', 'Новосибирск', 'Екатеринбург'];
  final List<String> _cities = ['Москва', 'Санкт-Петербург', 'Новосибирск', 'Екатеринбург'];
  final List<String> _categories = ['Фотографы', 'Видеографы', 'Организаторы', 'Диджеи'];
  final List<String> _targetAudiences = ['Все', '18-25 лет', '26-35 лет', '36-45 лет', '45+ лет'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _budgetController.dispose();
    _targetUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать рекламу'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAdvertisement,
            child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              _buildSectionHeader('Основная информация', Icons.info),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название рекламы',
                  hintText: 'Введите название рекламного объявления',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название рекламы';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Опишите ваше рекламное объявление',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Тип и размещение
              _buildSectionHeader('Тип и размещение', Icons.campaign),
              const SizedBox(height: 16),

              DropdownButtonFormField<AdType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип рекламы',
                  border: OutlineInputBorder(),
                ),
                items: AdType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(_getTypeText(type)));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<AdPlacement>(
                initialValue: _selectedPlacement,
                decoration: const InputDecoration(
                  labelText: 'Размещение',
                  border: OutlineInputBorder(),
                ),
                items: AdPlacement.values.map((placement) {
                  return DropdownMenuItem(
                    value: placement,
                    child: Text(_getPlacementText(placement)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPlacement = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Даты
              _buildSectionHeader('Период показа', Icons.calendar_today),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Начало'),
                      subtitle: Text(_formatDate(_startDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Окончание'),
                      subtitle: Text(_formatDate(_endDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Цена и бюджет
              _buildSectionHeader('Цена и бюджет', Icons.attach_money),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Цена за показ (₽)',
                  hintText: 'Введите цену за показ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите цену за показ';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Введите корректную цену';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Бюджет (₽)',
                  hintText: 'Введите общий бюджет (необязательно)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Таргетинг
              _buildSectionHeader('Таргетинг', Icons.gps_fixed),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedRegion,
                decoration: const InputDecoration(
                  labelText: 'Регион',
                  border: OutlineInputBorder(),
                ),
                items: _regions.map((region) {
                  return DropdownMenuItem(value: region, child: Text(region));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                decoration: const InputDecoration(labelText: 'Город', border: OutlineInputBorder()),
                items: _cities.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedTargetAudience,
                decoration: const InputDecoration(
                  labelText: 'Целевая аудитория',
                  border: OutlineInputBorder(),
                ),
                items: _targetAudiences.map((audience) {
                  return DropdownMenuItem(value: audience, child: Text(audience));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTargetAudience = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Ссылка
              _buildSectionHeader('Ссылка', Icons.link),
              const SizedBox(height: 16),

              TextFormField(
                controller: _targetUrlController,
                decoration: const InputDecoration(
                  labelText: 'Целевая ссылка',
                  hintText: 'https://example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 32),

              // Кнопка создания
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAdvertisement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Создать рекламу', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _getTypeText(AdType type) {
    switch (type) {
      case AdType.banner:
        return 'Баннер';
      case AdType.inline:
        return 'Встроенная';
      case AdType.profileBoost:
        return 'Продвижение профиля';
      case AdType.sponsoredPost:
        return 'Спонсорский пост';
      case AdType.categoryAd:
        return 'Реклама в категории';
      case AdType.searchAd:
        return 'Реклама в поиске';
    }
  }

  String _getPlacementText(AdPlacement placement) {
    switch (placement) {
      case AdPlacement.topBanner:
        return 'Верхний баннер';
      case AdPlacement.bottomBanner:
        return 'Нижний баннер';
      case AdPlacement.betweenPosts:
        return 'Между постами';
      case AdPlacement.profileHeader:
        return 'Заголовок профиля';
      case AdPlacement.searchResults:
        return 'Результаты поиска';
      case AdPlacement.categoryList:
        return 'Список категорий';
      case AdPlacement.homeFeed:
        return 'Лента новостей';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _saveAdvertisement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?['id'];

      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final price = double.parse(_priceController.text);
      final budget = _budgetController.text.isNotEmpty
          ? double.parse(_budgetController.text)
          : null;

      final adId = await _advertisementService.createAdvertisement(
        userId: userId,
        type: _selectedType,
        placement: _selectedPlacement,
        startDate: _startDate,
        endDate: _endDate,
        price: price,
        title: _titleController.text,
        description: _descriptionController.text,
        targetUrl: _targetUrlController.text,
        region: _selectedRegion,
        city: _selectedCity,
        category: _selectedCategory,
        targetAudience: _selectedTargetAudience,
        budget: budget,
      );

      if (adId != null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Рекламное объявление успешно создано'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Не удалось создать рекламное объявление');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
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
