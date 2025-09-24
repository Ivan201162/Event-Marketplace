import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_event.dart';
import '../services/calendar_service.dart';

/// Диалог для добавления/редактирования события
class AddEventDialog extends ConsumerStatefulWidget {
  const AddEventDialog({
    super.key,
    this.event,
    this.selectedDate,
    this.isBlockTime = false,
    required this.onEventCreated,
  });

  final CalendarEvent? event;
  final DateTime? selectedDate;
  final bool isBlockTime;
  final Function(CalendarEvent) onEventCreated;

  @override
  ConsumerState<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  late DateTime _startDate;
  late DateTime _endDate;
  late CalendarEventStatus _status;
  late CalendarEventType _type;
  late bool _isAllDay;
  late List<int> _reminderMinutes;
  late bool _isRecurring;
  
  final CalendarService _calendarService = CalendarService();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    if (widget.event != null) {
      // Редактирование существующего события
      final event = widget.event!;
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _locationController.text = event.location ?? '';
      _startDate = event.startDate;
      _endDate = event.endDate;
      _status = event.status;
      _type = event.type;
      _isAllDay = event.isAllDay;
      _reminderMinutes = List.from(event.reminderMinutes);
      _isRecurring = event.isRecurring;
    } else {
      // Создание нового события
      final baseDate = widget.selectedDate ?? DateTime.now();
      _startDate = DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 0);
      _endDate = _startDate.add(const Duration(hours: 1));
      _status = widget.isBlockTime 
          ? CalendarEventStatus.blocked 
          : CalendarEventStatus.personal;
      _type = widget.isBlockTime 
          ? CalendarEventType.blocked 
          : CalendarEventType.personal;
      _isAllDay = false;
      _reminderMinutes = [60, 1440]; // 1 час и 24 часа
      _isRecurring = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.event != null;
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Редактировать событие' : 'Добавить событие',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Форма
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок события
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Название события',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название события';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Описание
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание (необязательно)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Местоположение
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Местоположение (необязательно)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Даты и время
                      _buildDateTimeSection(),
                      
                      const SizedBox(height: 16),
                      
                      // Статус и тип
                      _buildStatusSection(),
                      
                      const SizedBox(height: 16),
                      
                      // Напоминания
                      _buildRemindersSection(),
                      
                      const SizedBox(height: 16),
                      
                      // Повторение
                      _buildRecurrenceSection(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Кнопки
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveEvent,
                    child: Text(isEditing ? 'Сохранить' : 'Создать'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дата и время',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Весь день
        CheckboxListTile(
          title: const Text('Весь день'),
          value: _isAllDay,
          onChanged: (value) {
            setState(() {
              _isAllDay = value ?? false;
              if (_isAllDay) {
                _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
                _endDate = _startDate.add(const Duration(days: 1));
              }
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        
        const SizedBox(height: 8),
        
        // Дата начала
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Дата начала'),
          subtitle: Text(_formatDate(_startDate)),
          onTap: _selectStartDate,
        ),
        
        // Время начала (если не весь день)
        if (!_isAllDay) ...[
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Время начала'),
            subtitle: Text(_formatTime(_startDate)),
            onTap: _selectStartTime,
          ),
        ],
        
        // Дата окончания
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Дата окончания'),
          subtitle: Text(_formatDate(_endDate)),
          onTap: _selectEndDate,
        ),
        
        // Время окончания (если не весь день)
        if (!_isAllDay) ...[
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Время окончания'),
            subtitle: Text(_formatTime(_endDate)),
            onTap: _selectEndTime,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Статус и тип',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Статус
        DropdownButtonFormField<CalendarEventStatus>(
          value: _status,
          decoration: const InputDecoration(
            labelText: 'Статус',
            border: OutlineInputBorder(),
          ),
          items: CalendarEventStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(_getStatusText(status)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _status = value;
              });
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Тип
        DropdownButtonFormField<CalendarEventType>(
          value: _type,
          decoration: const InputDecoration(
            labelText: 'Тип события',
            border: OutlineInputBorder(),
          ),
          items: CalendarEventType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getTypeText(type)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _type = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Напоминания',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          children: [
            _buildReminderChip('За 15 мин', 15),
            _buildReminderChip('За 1 час', 60),
            _buildReminderChip('За 24 часа', 1440),
            _buildReminderChip('За 1 неделю', 10080),
          ],
        ),
      ],
    );
  }

  Widget _buildReminderChip(String label, int minutes) {
    final isSelected = _reminderMinutes.contains(minutes);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _reminderMinutes.add(minutes);
          } else {
            _reminderMinutes.remove(minutes);
          }
        });
      },
    );
  }

  Widget _buildRecurrenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Повторение',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        CheckboxListTile(
          title: const Text('Повторяющееся событие'),
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value ?? false;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _startDate = DateTime(
          date.year,
          date.month,
          date.day,
          _startDate.hour,
          _startDate.minute,
        );
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _endDate = DateTime(
          date.year,
          date.month,
          date.day,
          _endDate.hour,
          _endDate.minute,
        );
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDate),
    );
    
    if (time != null) {
      setState(() {
        _startDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          time.hour,
          time.minute,
        );
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endDate),
    );
    
    if (time != null) {
      setState(() {
        _endDate = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final event = CalendarEvent(
        id: widget.event?.id ?? '',
        userId: 'current_user_id', // В реальном приложении получать из AuthService
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        status: _status,
        type: _type,
        isAllDay: _isAllDay,
        reminderMinutes: _reminderMinutes,
        isRecurring: _isRecurring,
        createdAt: widget.event?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.event != null) {
        await _calendarService.updateEvent(event);
      } else {
        await _calendarService.createEvent(event);
      }

      widget.onEventCreated(event);
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Ошибка сохранения события: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(CalendarEventStatus status) {
    switch (status) {
      case CalendarEventStatus.busy:
        return 'Занят';
      case CalendarEventStatus.free:
        return 'Свободен';
      case CalendarEventStatus.tentative:
        return 'Предварительно';
      case CalendarEventStatus.blocked:
        return 'Заблокирован';
      case CalendarEventStatus.personal:
        return 'Личное';
    }
  }

  String _getTypeText(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.booking:
        return 'Бронирование';
      case CalendarEventType.personal:
        return 'Личное событие';
      case CalendarEventType.blocked:
        return 'Заблокированное время';
      case CalendarEventType.reminder:
        return 'Напоминание';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
