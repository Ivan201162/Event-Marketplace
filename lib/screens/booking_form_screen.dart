import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist.dart';
import '../models/booking.dart';
import '../providers/specialist_providers.dart';
import '../providers/calendar_providers.dart';
import '../providers/payment_providers.dart';
import '../providers/firestore_providers.dart';
import '../services/firestore_service.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  final String specialistId;

  const BookingFormScreen({
    super.key,
    required this.specialistId,
  });

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  DateTime? _selectedDate;
  DateTime? _selectedStartTime;
  DateTime? _selectedEndTime;
  int _selectedDuration = 2;
  double _totalPrice = 0.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _eventLocationController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final specialistAsync = ref.watch(specialistProvider(widget.specialistId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать заявку'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: specialistAsync.when(
        data: (specialist) {
          if (specialist == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Специалист не найден'),
                ],
              ),
            );
          }

          return _buildBookingForm(specialist);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(specialistProvider(widget.specialistId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Построить форму бронирования
  Widget _buildBookingForm(Specialist specialist) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Информация о специалисте
          _buildSpecialistInfo(specialist),

          // Форма
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Основная информация о мероприятии
                  _buildEventInfoSection(),

                  const SizedBox(height: 24),

                  // Дата и время
                  _buildDateTimeSection(specialist),

                  const SizedBox(height: 24),

                  // Контактная информация
                  _buildContactInfoSection(),

                  const SizedBox(height: 24),

                  // Дополнительные пожелания
                  _buildSpecialRequestsSection(),

                  const SizedBox(height: 24),

                  // Расчет стоимости
                  _buildPriceCalculation(specialist),

                  const SizedBox(height: 24),

                  // Кнопка создания заявки
                  _buildSubmitButton(specialist),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Построить информацию о специалисте
  Widget _buildSpecialistInfo(Specialist specialist) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              specialist.name.isNotEmpty
                  ? specialist.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  specialist.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  specialist.categoryDisplayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${specialist.hourlyRate.toStringAsFixed(0)} ₽/час',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Построить секцию информации о мероприятии
  Widget _buildEventInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Информация о мероприятии',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Название мероприятия
        TextFormField(
          controller: _eventNameController,
          decoration: const InputDecoration(
            labelText: 'Название мероприятия *',
            hintText: 'Например: Свадьба Анны и Михаила',
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

        // Описание мероприятия
        TextFormField(
          controller: _eventDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Описание мероприятия',
            hintText: 'Расскажите подробнее о вашем мероприятии...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),

        const SizedBox(height: 16),

        // Место проведения
        TextFormField(
          controller: _eventLocationController,
          decoration: const InputDecoration(
            labelText: 'Место проведения *',
            hintText: 'Адрес или название места',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Введите место проведения';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Построить секцию даты и времени
  Widget _buildDateTimeSection(Specialist specialist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Дата и время',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Выбор даты
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                        : 'Выберите дату *',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null
                          ? Colors.black
                          : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Выбор времени начала
        if (_selectedDate != null) ...[
          InkWell(
            onTap: () => _selectStartTime(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedStartTime != null
                          ? '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}'
                          : 'Время начала *',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedStartTime != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Продолжительность
          _buildDurationSelector(specialist),

          const SizedBox(height: 16),

          // Время окончания
          if (_selectedStartTime != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    'Время окончания: ${_getEndTime()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  /// Построить селектор продолжительности
  Widget _buildDurationSelector(Specialist specialist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Продолжительность',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: _selectedDuration > 1
                  ? () => setState(() => _selectedDuration--)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Text(
                '$_selectedDuration ${_getHoursText(_selectedDuration)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: _selectedDuration < 12
                  ? () => setState(() => _selectedDuration++)
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Стоимость: ${(specialist.hourlyRate * _selectedDuration).toStringAsFixed(0)} ₽',
          style: TextStyle(
            fontSize: 14,
            color: Colors.green[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Построить секцию контактной информации
  Widget _buildContactInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Контактная информация',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Телефон
        TextFormField(
          controller: _contactPhoneController,
          decoration: const InputDecoration(
            labelText: 'Телефон *',
            hintText: '+7 (999) 123-45-67',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Введите номер телефона';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Email
        TextFormField(
          controller: _contactEmailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'example@email.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Введите корректный email';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Построить секцию дополнительных пожеланий
  Widget _buildSpecialRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Дополнительные пожелания',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _specialRequestsController,
          decoration: const InputDecoration(
            labelText: 'Особые требования или пожелания',
            hintText: 'Опишите любые особые требования...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  /// Построить расчет стоимости
  Widget _buildPriceCalculation(Specialist specialist) {
    final basePrice = specialist.hourlyRate * _selectedDuration;
    final prepayment = basePrice * 0.3; // 30% предоплата
    final finalPayment = basePrice * 0.7; // 70% доплата

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Расчет стоимости',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow(
              'Стоимость за $_selectedDuration ${_getHoursText(_selectedDuration)}',
              basePrice.toStringAsFixed(0)),
          _buildPriceRow('Предоплата (30%)', prepayment.toStringAsFixed(0)),
          _buildPriceRow('Доплата (70%)', finalPayment.toStringAsFixed(0)),
          const Divider(),
          _buildPriceRow(
            'Итого',
            basePrice.toStringAsFixed(0),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  /// Построить строку цены
  Widget _buildPriceRow(String label, String price, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '$price ₽',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green[700] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Построить кнопку отправки
  Widget _buildSubmitButton(Specialist specialist) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _submitBooking(specialist),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Создать заявку',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Выбрать дату
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _selectedStartTime = null; // Сброс времени при смене даты
      });
    }
  }

  /// Выбрать время начала
  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime != null
          ? TimeOfDay.fromDateTime(_selectedStartTime!)
          : const TimeOfDay(hour: 10, minute: 0),
    );

    if (time != null) {
      setState(() {
        _selectedStartTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  /// Получить время окончания
  String _getEndTime() {
    if (_selectedStartTime == null) return '';

    final endTime = _selectedStartTime!.add(Duration(hours: _selectedDuration));
    return '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  /// Получить текст для часов
  String _getHoursText(int hours) {
    if (hours == 1) return 'час';
    if (hours >= 2 && hours <= 4) return 'часа';
    return 'часов';
  }

  /// Отправить заявку
  Future<void> _submitBooking(Specialist specialist) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите дату и время'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Создание заявки
      final booking = Booking(
        id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
        customerId: 'customer_1', // TODO: Получить из аутентификации
        specialistId: specialist.id,
        eventDate: _selectedStartTime!,
        status: 'pending',
        prepayment: specialist.hourlyRate * _selectedDuration * 0.3,
        totalPrice: specialist.hourlyRate * _selectedDuration,
        prepaymentPaid: false,
        paymentStatus: 'pending',
      );

      // Сохранение заявки
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.addOrUpdateBooking(booking);

      // Показать успешное сообщение
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заявка успешно создана!'),
            backgroundColor: Colors.green,
          ),
        );

        // Вернуться на предыдущий экран
        Navigator.of(context).pop();
      }
    } catch (e) {
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
}
