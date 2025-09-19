import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/specialist.dart';
import '../providers/firestore_providers.dart';
import '../providers/specialist_providers.dart';
import 'calendar_widget.dart';

/// Виджет бронирования
class BookingWidget extends ConsumerStatefulWidget {
  const BookingWidget({
    super.key,
    required this.specialist,
  });
  final Specialist specialist;

  @override
  ConsumerState<BookingWidget> createState() => _BookingWidgetState();
}

class _BookingWidgetState extends ConsumerState<BookingWidget> {
  DateTime? _selectedDate;
  DateTime? _selectedTime;
  int _selectedHours = 2;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Забронировать ${widget.specialist.name}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Информация о специалисте
              _buildSpecialistInfo(),

              const SizedBox(height: 24),

              // Выбор даты
              _buildDateSelection(),

              const SizedBox(height: 24),

              // Выбор времени
              if (_selectedDate != null) _buildTimeSelection(),

              const SizedBox(height: 24),

              // Выбор продолжительности
              _buildDurationSelection(),

              const SizedBox(height: 24),

              // Дополнительные заметки
              _buildNotesSection(),

              const Spacer(),

              // Кнопки
              _buildActionButtons(),
            ],
          ),
        ),
      );

  /// Построить информацию о специалисте
  Widget _buildSpecialistInfo() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                widget.specialist.name.isNotEmpty
                    ? widget.specialist.name[0].toUpperCase()
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
                    widget.specialist.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.specialist.categoryDisplayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${widget.specialist.hourlyRate.toStringAsFixed(0)} ₽/час',
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

  /// Построить выбор даты
  Widget _buildDateSelection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Выберите дату',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                          : 'Выберите дату',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  /// Построить выбор времени
  Widget _buildTimeSelection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Выберите время',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedTime != null
                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : 'Выберите время',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedTime != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  /// Построить выбор продолжительности
  Widget _buildDurationSelection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Продолжительность',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _selectedHours > 1
                    ? () => setState(() => _selectedHours--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text(
                  '$_selectedHours ${_getHoursText(_selectedHours)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _selectedHours < 12
                    ? () => setState(() => _selectedHours++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Стоимость: ${(widget.specialist.hourlyRate * _selectedHours).toStringAsFixed(0)} ₽',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );

  /// Построить секцию заметок
  Widget _buildNotesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Дополнительные заметки (необязательно)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Опишите детали мероприятия...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      );

  /// Построить кнопки действий
  Widget _buildActionButtons() {
    final canBook = _selectedDate != null && _selectedTime != null;
    final totalPrice = widget.specialist.hourlyRate * _selectedHours;

    return Column(
      children: [
        // Итоговая стоимость
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Итого:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${totalPrice.toStringAsFixed(0)} ₽',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Кнопки
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: canBook ? _createBooking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Забронировать'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Выбрать дату
  Future<void> _selectDate() async {
    // Показываем календарь с блокировкой занятых дат
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Выберите дату',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: CalendarWidget(
                  specialistId: widget.specialist.id,
                  initialDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                      _selectedTime = null; // Сброс времени при смене даты
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Выбрать время
  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime != null
          ? TimeOfDay.fromDateTime(_selectedTime!)
          : const TimeOfDay(hour: 10, minute: 0),
    );

    if (time != null) {
      setState(() {
        _selectedTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  /// Получить текст для часов
  String _getHoursText(int hours) {
    if (hours == 1) return 'час';
    if (hours >= 2 && hours <= 4) return 'часа';
    return 'часов';
  }

  /// Создать бронирование
  Future<void> _createBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите дату и время'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Определяем время окончания
      final endTime = _selectedTime!.add(Duration(hours: _selectedHours));

      // Проверяем конфликты бронирования
      final hasConflict =
          await ref.read(firestoreServiceProvider).hasBookingConflict(
                widget.specialist.id,
                _selectedTime!,
                endTime,
              );

      if (hasConflict) {
        Navigator.of(context).pop(); // Закрываем индикатор загрузки
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Выбранное время уже занято'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Создаем бронирование
      final booking = Booking(
        id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
        eventId: 'event_${DateTime.now().millisecondsSinceEpoch}',
        eventTitle: 'Услуга специалиста ${widget.specialist.name}',
        userId: 'current_user_id', // TODO: Получить ID текущего пользователя
        userName: 'Текущий пользователь', // TODO: Получить имя пользователя
        userEmail: 'user@example.com', // TODO: Получить email пользователя
        userPhone: '+7 (999) 123-45-67', // TODO: Получить телефон пользователя
        status: BookingStatus.pending,
        bookingDate: DateTime.now(),
        eventDate: _selectedTime!,
        participantsCount: 1,
        totalPrice: widget.specialist.hourlyRate * _selectedHours,
        notes: 'Бронирование через приложение',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем бронирование с интеграцией календаря
      await ref
          .read(firestoreServiceProvider)
          .addOrUpdateBookingWithCalendar(booking);

      Navigator.of(context).pop(); // Закрываем индикатор загрузки
      Navigator.of(context).pop(); // Закрываем диалог бронирования

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Бронирование ${widget.specialist.name} создано'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Закрываем индикатор загрузки
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка создания бронирования: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Виджет для отображения доступных временных слотов
class TimeSlotsWidget extends ConsumerWidget {
  const TimeSlotsWidget({
    super.key,
    required this.specialistId,
    required this.selectedDate,
    this.selectedTime,
    required this.onTimeSelected,
  });
  final String specialistId;
  final DateTime selectedDate;
  final DateTime? selectedTime;
  final Function(DateTime) onTimeSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeSlotsAsync = ref.watch(
      specialistTimeSlotsProvider(
        SpecialistTimeSlotsParams(
          specialistId: specialistId,
          date: selectedDate,
        ),
      ),
    );

    return timeSlotsAsync.when(
      data: (timeSlots) {
        if (timeSlots.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'На эту дату нет доступных временных слотов',
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Доступные временные слоты:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: timeSlots.map((timeSlot) {
                final isSelected = selectedTime != null &&
                    selectedTime!.hour == timeSlot.hour &&
                    selectedTime!.minute == timeSlot.minute;

                return GestureDetector(
                  onTap: () => onTimeSelected(timeSlot),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Ошибка загрузки временных слотов: $error',
          style: TextStyle(color: Colors.red[700]),
        ),
      ),
    );
  }
}
