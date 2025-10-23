import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/supabase_service.dart';

/// Экран создания заявки
class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedCategory;
  DateTime? _selectedDeadline;
  bool _isLoading = false;

  final List<String> _categories = [
    'Фотография',
    'Видеосъемка',
    'Декор',
    'Кейтеринг',
    'Музыка',
    'Анимация',
    'Ведущий',
    'Диджей',
    'Флористика',
    'Другое',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _createRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final budget = _budgetController.text.trim().isEmpty
          ? null
          : double.tryParse(_budgetController.text.trim());

      final request = await SupabaseService.createRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        budget: budget,
        deadline: _selectedDeadline,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      if (request != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Заявка создана успешно!'),
              backgroundColor: Colors.green),
        );
        context.pop();
      } else {
        throw Exception('Не удалось создать заявку');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка создания заявки: $e'),
              backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать заявку'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createRequest,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Создать', style: TextStyle(color: Colors.white)),
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
              // Заголовок
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название заявки *',
                  border: OutlineInputBorder(),
                  hintText: 'Краткое описание того, что нужно сделать',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название заявки';
                  }
                  if (value.trim().length < 5) {
                    return 'Название должно содержать минимум 5 символов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Описание
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Подробное описание',
                  border: OutlineInputBorder(),
                  hintText: 'Опишите детали задачи, требования, пожелания...',
                ),
              ),
              const SizedBox(height: 24),

              // Категория
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория *',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                      value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите категорию';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Бюджет
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Бюджет (₽)',
                  border: OutlineInputBorder(),
                  hintText: 'Укажите примерный бюджет',
                  prefixText: '₽ ',
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final budget = double.tryParse(value.trim());
                    if (budget == null) {
                      return 'Введите корректную сумму';
                    }
                    if (budget < 0) {
                      return 'Бюджет не может быть отрицательным';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Местоположение
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Местоположение',
                  border: OutlineInputBorder(),
                  hintText: 'Город или адрес проведения мероприятия',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 24),

              // Срок выполнения
              InkWell(
                onTap: _selectDeadline,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Срок выполнения',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDeadline != null
                        ? '${_selectedDeadline!.day}.${_selectedDeadline!.month}.${_selectedDeadline!.year}'
                        : 'Выберите дату',
                    style: TextStyle(
                      color: _selectedDeadline != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Информация
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: theme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'После создания заявки специалисты смогут откликнуться на неё. Вы сможете выбрать подходящего исполнителя.',
                        style:
                            TextStyle(color: theme.primaryColor, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
