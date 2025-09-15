import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_event.dart';
import '../services/calendar_service.dart';

/// Экран создания/редактирования события
class CreateEventScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? specialistId;
  final DateTime? selectedDate;
  final CalendarEvent? event;

  const CreateEventScreen({
    super.key,
    required this.userId,
    this.specialistId,
    this.selectedDate,
    this.event,
  });

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  final CalendarService _calendarService = CalendarService();
  
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  bool _isAllDay = false;
  EventType _eventType = EventType.booking;
  EventStatus _eventStatus = EventStatus.scheduled;
  String? _reminderTime;
  String? _color;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.event != null) {
      // Редактирование существующего события
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _locationController.text = widget.event!.location;
      _startTime = widget.event!.startTime;
      _endTime = widget.event!.endTime;
      _isAllDay = widget.event!.isAllDay;
      _eventType = widget.event!.type;
      _eventStatus = widget.event!.status;
      _reminderTime = widget.event!.reminderTime;
      _color = widget.event!.color;
    } else if (widget.selectedDate != null) {
      // Создание нового события с предвыбранной датой
      _startTime = DateTime(
        widget.selectedDate!.year,
        widget.selectedDate!.month,
        widget.selectedDate!.day,
        DateTime.now().hour,
        DateTime.now().minute,
      );
      _endTime = _startTime.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event != null ? 'Редактировать событие' : 'Создать событие'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEvent,
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
              // Основная информация
              _buildBasicInfoSection(),
              
              const SizedBox(height: 24),
              
              // Время
              _buildTimeSection(),
              
              const SizedBox(height: 24),
              
              // Тип и статус
              _buildTypeAndStatusSection(),
              
              const SizedBox(height: 24),
              
              // Напоминания
              _buildReminderSection(),
              
              const SizedBox(height: 24),
              
              // Цвет
              _buildColorSection(),
              
              const SizedBox(height: 24),
              
              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveEvent,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(widget.event != null ? 'Обновить событие' : 'Создать событие'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Основная информация',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Заголовок
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Заголовок *',
                border: OutlineInputBorder(),
                hintText: 'Введите заголовок события',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Пожалуйста, введите заголовок';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Описание
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
                hintText: 'Введите описание события',
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Место
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Место',
                border: OutlineInputBorder(),
                hintText: 'Введите место проведения',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Время',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Весь день
            CheckboxListTile(
              title: const Text('Весь день'),
              value: _isAllDay,
              onChanged: (value) {
                setState(() {
                  _isAllDay = value ?? false;
                  if (_isAllDay) {
                    _startTime = DateTime(_startTime.year, _startTime.month, _startTime.day);
                    _endTime = DateTime(_endTime.year, _endTime.month, _endTime.day, 23, 59);
                  }
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Время начала
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Время начала'),
              subtitle: Text(_formatDateTime(_startTime)),
              onTap: _isAllDay ? null : _selectStartTime,
            ),
            
            // Время окончания
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Время окончания'),
              subtitle: Text(_formatDateTime(_endTime)),
              onTap: _isAllDay ? null : _selectEndTime,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeAndStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Тип и статус',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Тип события
            DropdownButtonFormField<EventType>(
              value: _eventType,
              decoration: const InputDecoration(
                labelText: 'Тип события',
                border: OutlineInputBorder(),
              ),
              items: EventType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeText(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _eventType = value ?? EventType.booking;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Статус события
            DropdownButtonFormField<EventStatus>(
              value: _eventStatus,
              decoration: const InputDecoration(
                labelText: 'Статус события',
                border: OutlineInputBorder(),
              ),
              items: EventStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusText(status)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _eventStatus = value ?? EventStatus.scheduled;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Напоминания',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _reminderTime,
              decoration: const InputDecoration(
                labelText: 'Напоминание',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Без напоминания')),
                DropdownMenuItem(value: '5m', child: Text('За 5 минут')),
                DropdownMenuItem(value: '15m', child: Text('За 15 минут')),
                DropdownMenuItem(value: '30m', child: Text('За 30 минут')),
                DropdownMenuItem(value: '1h', child: Text('За 1 час')),
                DropdownMenuItem(value: '1d', child: Text('За 1 день')),
              ],
              onChanged: (value) {
                setState(() {
                  _reminderTime = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSection() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Цвет события',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors.map((color) {
                final isSelected = _color == color.value.toRadixString(16);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _color = color.value.toRadixString(16);
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime),
      );

      if (time != null) {
        setState(() {
          _startTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          
          // Автоматически обновляем время окончания
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: _startTime,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime),
      );

      if (time != null) {
        setState(() {
          _endTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final event = CalendarEvent(
        id: widget.event?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        location: _locationController.text.trim(),
        specialistId: widget.specialistId ?? 'demo_specialist_id',
        specialistName: 'Демо Специалист',
        customerId: widget.userId,
        customerName: 'Демо Пользователь',
        bookingId: widget.event?.bookingId ?? 'demo_booking_id',
        status: _eventStatus,
        type: _eventType,
        isAllDay: _isAllDay,
        reminderTime: _reminderTime,
        color: _color,
        createdAt: widget.event?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (widget.event != null) {
        success = await _calendarService.updateEvent(event);
      } else {
        final eventId = await _calendarService.createEvent(event);
        success = eventId != null;
      }

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event != null 
                ? 'Событие обновлено' 
                : 'Событие создано'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка сохранения события'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getTypeText(EventType type) {
    switch (type) {
      case EventType.booking:
        return 'Бронирование';
      case EventType.consultation:
        return 'Консультация';
      case EventType.meeting:
        return 'Встреча';
      case EventType.reminder:
        return 'Напоминание';
      case EventType.deadline:
        return 'Дедлайн';
    }
  }

  String _getStatusText(EventStatus status) {
    switch (status) {
      case EventStatus.scheduled:
        return 'Запланировано';
      case EventStatus.confirmed:
        return 'Подтверждено';
      case EventStatus.cancelled:
        return 'Отменено';
      case EventStatus.completed:
        return 'Завершено';
      case EventStatus.postponed:
        return 'Перенесено';
    }
  }
}
