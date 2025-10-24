import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/request.dart';
import '../../providers/requests_providers.dart';

/// Экран создания заявки
class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();

  String _selectedCategory = 'Другое';
  String _selectedSubCategory = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<String> _attachments = [];

  final List<String> _categories = [
    'Свадьба',
    'Корпоратив',
    'День рождения',
    'Детский праздник',
    'Выпускной',
    'Другое',
  ];

  final Map<String, List<String>> _subCategories = {
    'Свадьба': ['Церемония', 'Банкет', 'Фотосессия', 'Музыка'],
    'Корпоратив': ['Конференция', 'Тимбилдинг', 'Праздник', 'Презентация'],
    'День рождения': ['Детский', 'Взрослый', 'Юбилей', 'Сюрприз'],
    'Детский праздник': ['День рождения', 'Выпускной', 'Новый год', 'Другое'],
    'Выпускной': ['Школьный', 'Университетский', 'Детский сад'],
    'Другое': [],
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать заявку'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _saveRequest,
            child: const Text('Сохранить'),
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название заявки';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Категория
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория *',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                    _selectedSubCategory = '';
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Подкатегория
              if (_subCategories[_selectedCategory]!.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedSubCategory.isEmpty ? null : _selectedSubCategory,
                  decoration: const InputDecoration(
                    labelText: 'Подкатегория',
                    border: OutlineInputBorder(),
                  ),
                  items: _subCategories[_selectedCategory]!.map((subCategory) {
                    return DropdownMenuItem(
                      value: subCategory,
                      child: Text(subCategory),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubCategory = value ?? '';
                    });
                  },
                ),
              
              const SizedBox(height: 16),
              
              // Город
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Город *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите город';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Дата и время
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Дата *',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                              : 'Выберите дату',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Время',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Выберите время',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Бюджет
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _budgetMinController,
                      decoration: const InputDecoration(
                        labelText: 'Бюджет от (₽)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _budgetMaxController,
                      decoration: const InputDecoration(
                        labelText: 'Бюджет до (₽)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите описание';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Вложения
              Row(
                children: [
                  const Text('Вложения:'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _addAttachment,
                  ),
                ],
              ),
              
              if (_attachments.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _attachments.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.attach_file),
                      title: Text(_attachments[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeAttachment(index),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _addAttachment() {
    // TODO: Реализовать добавление вложений
    setState(() {
      _attachments.add('Вложение ${_attachments.length + 1}');
    });
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _saveRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату')),
      );
      return;
    }

    try {
      final request = Request(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        subCategory: _selectedSubCategory,
        city: _cityController.text,
        budgetMin: int.tryParse(_budgetMinController.text) ?? 0,
        budgetMax: int.tryParse(_budgetMaxController.text) ?? 0,
        dateTime: _selectedDate!,
        time: _selectedTime,
        attachments: _attachments,
        status: 'OPEN',
        ownerId: 'current_user_id', // TODO: Получить ID текущего пользователя
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(requestsProvider.notifier).createRequest(request);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заявка создана успешно')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания заявки: $e')),
        );
      }
    }
  }
}