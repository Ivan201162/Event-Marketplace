import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/booking.dart';
import '../models/specialist.dart';
import '../providers/auth_providers.dart';
import '../services/booking_service.dart';
import '../services/specialist_service.dart';
import '../widgets/back_button_handler.dart';
import '../widgets/custom_text_field.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.specialistId});
  final String specialistId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final SpecialistService _specialistService = SpecialistService();
  final BookingService _bookingService = BookingService();
  final _formKey = GlobalKey<FormState>();

  Specialist? _specialist;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Контроллеры формы
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  // Выбранные значения
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _duration = 2; // часы
  double _totalPrice = 0;
  bool _advancePayment = false;
  double _advanceAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadSpecialist();
  }

  @override
  void dispose() {
    _eventTitleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _participantsController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialist() async {
    try {
      final specialist = await _specialistService.getSpecialistById(widget.specialistId);
      setState(() {
        _specialist = specialist;
        _isLoading = false;
        if (specialist != null) {
          _totalPrice = (specialist.price ?? 0) * _duration;
          _advanceAmount = _totalPrice * 0.3; // 30% аванс
        }
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки специалиста: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _calculateTotalPrice() {
    if (_specialist != null) {
      setState(() {
        _totalPrice = (_specialist!.price ?? 0) * _duration;
        _advanceAmount = _totalPrice * 0.3;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите дату и время мероприятия'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Получаем текущего пользователя
    final currentUserAsync = ref.read(currentUserProvider);
    if (currentUserAsync is! AsyncData || currentUserAsync.value == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Необходимо войти в систему'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    final currentUser = currentUserAsync.value!;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final booking = Booking(
        id: '',
        specialistId: widget.specialistId,
        specialistName: _specialist?.name ?? '',
        clientId: currentUser.uid,
        clientName: currentUser.displayName ?? '',
        service: _eventTitleController.text,
        date: eventDateTime,
        time: '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        duration: _duration,
        totalPrice: _totalPrice.toInt(),
        notes: _commentController.text,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        location: _addressController.text,
      );
      await _bookingService.createBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заявка успешно отправлена!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания заявки: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_specialist == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Бронирование'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: const Center(child: Text('Специалист не найден')),
      );
    }

    return BackButtonHandler(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Бронирование'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Информация о специалисте
                _buildSpecialistInfo(),
                const SizedBox(height: 24),

                // Форма бронирования
                _buildBookingForm(),
                const SizedBox(height: 24),

                // Стоимость
                _buildPriceSection(),
                const SizedBox(height: 24),

                // Кнопка отправки
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialistInfo() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: _specialist!.imageUrl != null
                ? NetworkImage(_specialist!.imageUrl!)
                : null,
            child: _specialist!.imageUrl == null
                ? Text(
                    _specialist!.name.isNotEmpty ? _specialist!.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _specialist!.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _specialist!.category?.name ?? 'Специалист',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _specialist!.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${(_specialist!.price ?? 0).toInt()}₽/час',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    ),
  );

  Widget _buildBookingForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Детали мероприятия', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),

      CustomTextField(
        controller: _eventTitleController,
        labelText: 'Название мероприятия *',
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Введите название мероприятия';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      CustomTextField(
        controller: _descriptionController,
        labelText: 'Описание мероприятия',
        maxLines: 3,
      ),
      const SizedBox(height: 16),

      CustomTextField(
        controller: _addressController,
        labelText: 'Адрес проведения *',
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Введите адрес проведения';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      CustomTextField(
        controller: _participantsController,
        labelText: 'Количество участников',
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),

      // Дата и время
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Дата мероприятия *',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                          : 'Выберите дату',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Время начала *',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedTime != null
                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : 'Выберите время',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Продолжительность
      const Text(
        'Продолжительность (часы)',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      Slider(
        value: _duration.toDouble(),
        min: 1,
        max: 12,
        divisions: 11,
        label: '$_duration часов',
        onChanged: (value) {
          setState(() {
            _duration = value.round();
          });
          _calculateTotalPrice();
        },
      ),
      const SizedBox(height: 16),

      CustomTextField(
        controller: _commentController,
        labelText: 'Дополнительные пожелания',
        maxLines: 3,
      ),
    ],
  );

  Widget _buildPriceSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Стоимость', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_duration часов × ${(_specialist!.price ?? 0).toInt()}₽'),
              Text('${_totalPrice.toInt()}₽'),
            ],
          ),
          const SizedBox(height: 8),

          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Итого:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '${_totalPrice.toInt()}₽',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Аванс
          CheckboxListTile(
            title: const Text('Оплатить аванс'),
            subtitle: Text('${_advanceAmount.toInt()}₽ (30%)'),
            value: _advancePayment,
            onChanged: (value) {
              setState(() {
                _advancePayment = value ?? false;
              });
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isSubmitting ? null : _submitBooking,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isSubmitting
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              'Отправить заявку',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    ),
  );
}
