import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_providers.dart';
import '../providers/specialist_providers.dart';
import '../models/specialist.dart';
import '../models/booking.dart';

/// Экран формы бронирования
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
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedHours = 2;
  String? _selectedService;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final specialistAsync = ref.watch(specialistProvider(widget.specialistId));
    final bookingFormState = ref.watch(bookingFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бронирование'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: specialistAsync.when(
        data: (specialist) {
          if (specialist == null) {
            return const Center(child: Text('Специалист не найден'));
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
                    ref.invalidate(specialistProvider(widget.specialistId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingForm(Specialist specialist) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о специалисте
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: specialist.avatar != null
                          ? NetworkImage(specialist.avatar!)
                          : null,
                      child: specialist.avatar == null
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            specialist.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            specialist.specialization,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                specialist.rating?.toStringAsFixed(1) ?? '0.0',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Выбор услуги
            Text(
              'Выберите услугу',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedService,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Выберите услугу',
              ),
              items: specialist.services?.map((service) {
                    return DropdownMenuItem(
                      value: service,
                      child: Text(service),
                    );
                  }).toList() ??
                  [],
              onChanged: (value) {
                setState(() {
                  _selectedService = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Выберите услугу';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Выбор даты
            Text(
              'Выберите дату',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                      : 'Выберите дату',
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Выбор времени
            Text(
              'Выберите время',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
                child: Text(
                  _selectedTime != null
                      ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                      : 'Выберите время',
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Продолжительность
            Text(
              'Продолжительность (часы)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Slider(
              value: _selectedHours.toDouble(),
              min: 1,
              max: 8,
              divisions: 7,
              label: '$_selectedHours ч.',
              onChanged: (value) {
                setState(() {
                  _selectedHours = value.round();
                });
              },
            ),

            const SizedBox(height: 24),

            // Дополнительные пожелания
            Text(
              'Дополнительные пожелания',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Опишите ваши пожелания...',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Кнопка бронирования
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: bookingFormState.isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: bookingFormState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Забронировать'),
              ),
            ),

            if (bookingFormState.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bookingFormState.errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _submitBooking() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату и время')),
      );
      return;
    }

    final eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    ref
        .read(bookingFormProvider.notifier)
        .createBooking(
          specialistId: widget.specialistId,
          eventDate: eventDateTime,
          duration: Duration(hours: _selectedHours),
          service: _selectedService!,
          notes: _notesController.text.trim(),
        )
        .then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Бронирование создано успешно')),
        );
        Navigator.of(context).pop();
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $error')),
        );
      }
    });
  }
}
