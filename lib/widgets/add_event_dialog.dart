import 'package:flutter/material.dart';

import '../models/event_calendar.dart';
import '../services/event_calendar_service.dart';

/// Диалог добавления/редактирования события
class AddEventDialog extends StatefulWidget {
  const AddEventDialog({
    super.key,
    required this.userId,
    required this.initialDate,
    this.existingEvent,
    required this.onEventCreated,
  });

  final String userId;
  final DateTime initialDate;
  final CalendarEvent? existingEvent;
  final VoidCallback onEventCreated;

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final EventCalendarService _calendarService = EventCalendarService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 12, minute: 0);
  EventType _selectedType = EventType.other;
  bool _hasReminder = false;
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;
  bool _isRecurring = false;
  RecurringFrequency _recurringFrequency = RecurringFrequency.yearly;
  int _recurringInterval = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    
    _titleController = TextEditingController(text: widget.existingEvent?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existingEvent?.description ?? '');
    _locationController = TextEditingController(text: widget.existingEvent?.location ?? '');
    
    if (widget.existingEvent != null) {
      _selectedType = widget.existingEvent!.type;
      _hasReminder = widget.existingEvent!.reminderTime != null;
      _isRecurring = widget.existingEvent!.isRecurring;
      
      if (widget.existingEvent!.reminderTime != null) {
        _reminderDate = widget.existingEvent!.reminderTime!;
        _reminderTime = TimeOfDay.fromDateTime(widget.existingEvent!.reminderTime!);
      }
      
      if (widget.existingEvent!.recurringPattern != null) {
        _recurringFrequency = widget.existingEvent!.recurringPattern!.frequency;
        _recurringInterval = widget.existingEvent!.recurringPattern!.interval;
      }
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
  Widget build(BuildContext context) => AlertDialog(
      title: Text(widget.existingEvent != null ? 'Редактировать событие' : 'Добавить событие'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название события',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите название события';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EventType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Тип события',
                    border: OutlineInputBorder(),
                  ),
                  items: EventType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Text(type.icon),
                          const SizedBox(width: 8),
                          Text(type.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Дата',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_formatDate(_selectedDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Время',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_formatTime(_selectedTime)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание (необязательно)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Место проведения (необязательно)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Напоминание'),
                  value: _hasReminder,
                  onChanged: (value) {
                    setState(() {
                      _hasReminder = value ?? false;
                    });
                  },
                ),
                if (_hasReminder) ...[
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectReminderDate(),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Дата напоминания',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_reminderDate != null 
                                ? _formatDate(_reminderDate!)
                                : 'Выберите дату'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectReminderTime(),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Время напоминания',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_reminderTime != null 
                                ? _formatTime(_reminderTime!)
                                : 'Выберите время'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Повторяющееся событие'),
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value ?? false;
                    });
                  },
                ),
                if (_isRecurring) ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<RecurringFrequency>(
                          value: _recurringFrequency,
                          decoration: const InputDecoration(
                            labelText: 'Частота',
                            border: OutlineInputBorder(),
                          ),
                          items: RecurringFrequency.values.map((frequency) {
                            return DropdownMenuItem(
                              value: frequency,
                              child: Text(_getFrequencyDisplayName(frequency)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _recurringFrequency = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _recurringInterval.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Интервал',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _recurringInterval = int.tryParse(value) ?? 1;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveEvent,
          child: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingEvent != null ? 'Сохранить' : 'Добавить'),
        ),
      ],
    );

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _selectReminderDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? _selectedDate,
      firstDate: DateTime.now(),
      lastDate: _selectedDate,
    );
    
    if (date != null) {
      setState(() {
        _reminderDate = date;
      });
    }
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    
    if (time != null) {
      setState(() {
        _reminderTime = time;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getFrequencyDisplayName(RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return 'Ежедневно';
      case RecurringFrequency.weekly:
        return 'Еженедельно';
      case RecurringFrequency.monthly:
        return 'Ежемесячно';
      case RecurringFrequency.yearly:
        return 'Ежегодно';
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_hasReminder && (_reminderDate == null || _reminderTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите дату и время напоминания'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      DateTime? reminderDateTime;
      if (_hasReminder && _reminderDate != null && _reminderTime != null) {
        reminderDateTime = DateTime(
          _reminderDate!.year,
          _reminderDate!.month,
          _reminderDate!.day,
          _reminderTime!.hour,
          _reminderTime!.minute,
        );
      }

      RecurringPattern? recurringPattern;
      if (_isRecurring) {
        recurringPattern = RecurringPattern(
          frequency: _recurringFrequency,
          interval: _recurringInterval,
        );
      }

      final event = CalendarEvent(
        id: widget.existingEvent?.id ?? '',
        userId: widget.userId,
        title: _titleController.text,
        date: eventDateTime,
        type: _selectedType,
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : null,
        location: _locationController.text.isNotEmpty 
            ? _locationController.text 
            : null,
        reminderTime: reminderDateTime,
        isRecurring: _isRecurring,
        recurringPattern: recurringPattern,
        relatedBookingId: widget.existingEvent?.relatedBookingId,
        createdAt: widget.existingEvent?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingEvent != null) {
        await _calendarService.updateEvent(event);
      } else {
        await _calendarService.createEvent(event);
      }

      widget.onEventCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения события: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
