import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  ConsumerState<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _participantsController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _prepaymentController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedSpecialistId;
  bool _isLoading = false;

  final List<Map<String, String>> _specialists = [
    {'id': 'specialist1', 'name': 'Александр Иванов', 'category': 'Свадьбы и корпоративы'},
    {'id': 'specialist2', 'name': 'Мария Смирнова', 'category': 'Детские праздники'},
    {'id': 'specialist3', 'name': 'Дмитрий Петров', 'category': 'Банкеты и фуршеты'},
  ];

  @override
  void dispose() {
    _eventTitleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _participantsController.dispose();
    _totalPriceController.dispose();
    _prepaymentController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null || _selectedSpecialistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните все обязательные поля'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final bookingData = {
        'customerId': currentUser.uid,
        'specialistId': _selectedSpecialistId!,
        'eventTitle': _eventTitleController.text.trim(),
        'eventDate': Timestamp.fromDate(eventDateTime),
        'totalPrice': double.parse(_totalPriceController.text),
        'prepayment': double.parse(_prepaymentController.text),
        'status': 'pending',
        'message': _descriptionController.text.trim(),
        'customerName': _customerNameController.text.trim(),
        'customerPhone': _customerPhoneController.text.trim(),
        'customerEmail': _customerEmailController.text.trim(),
        'description': _descriptionController.text.trim(),
        'participantsCount': int.parse(_participantsController.text),
        'address': _addressController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('bookings').add(bookingData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заявка успешно создана!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания заявки: $e'),
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

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Создать заявку'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              _buildSectionTitle('Основная информация'),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _eventTitleController,
                decoration: const InputDecoration(
                  labelText: 'Название мероприятия *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название мероприятия';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание мероприятия',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Дата и время
              _buildSectionTitle('Дата и время'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Дата мероприятия *',
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
                          labelText: 'Время мероприятия *',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedTime != null
                              ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                              : 'Выберите время',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Место проведения
              _buildSectionTitle('Место проведения'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Адрес мероприятия',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Участники
              _buildSectionTitle('Участники'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _participantsController,
                decoration: const InputDecoration(
                  labelText: 'Количество участников *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите количество участников';
                  }
                  final count = int.tryParse(value);
                  if (count == null || count <= 0) {
                    return 'Введите корректное количество участников';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Специалист
              _buildSectionTitle('Специалист'),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedSpecialistId,
                decoration: const InputDecoration(
                  labelText: 'Выберите специалиста *',
                  border: OutlineInputBorder(),
                ),
                items: _specialists.map((specialist) => DropdownMenuItem<String>(
                    value: specialist['id'],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(specialist['name']!),
                        Text(
                          specialist['category']!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSpecialistId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите специалиста';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Стоимость
              _buildSectionTitle('Стоимость'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Общая стоимость (₽) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите стоимость';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Введите корректную стоимость';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _prepaymentController,
                      decoration: const InputDecoration(
                        labelText: 'Предоплата (₽) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите предоплату';
                        }
                        final prepayment = double.tryParse(value);
                        if (prepayment == null || prepayment <= 0) {
                          return 'Введите корректную предоплату';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Контактная информация
              _buildSectionTitle('Контактная информация'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Ваше имя *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите ваше имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _customerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите телефон';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _customerEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите email';
                  }
                  if (!value.contains('@')) {
                    return 'Введите корректный email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Кнопка создания
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createBooking,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Создать заявку'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  Widget _buildSectionTitle(String title) => Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
}