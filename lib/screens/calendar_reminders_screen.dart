import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/calendar_integration_service.dart';
import '../services/error_logging_service.dart';
import '../services/reminder_system_service.dart';

/// Экран календаря и напоминаний
class CalendarRemindersScreen extends ConsumerStatefulWidget {
  const CalendarRemindersScreen({super.key});

  @override
  ConsumerState<CalendarRemindersScreen> createState() =>
      _CalendarRemindersScreenState();
}

class _CalendarRemindersScreenState
    extends ConsumerState<CalendarRemindersScreen>
    with TickerProviderStateMixin {
  final CalendarIntegrationService _calendarService =
      CalendarIntegrationService();
  final ReminderSystemService _reminderService = ReminderSystemService();
  final ErrorLoggingService _errorLogger = ErrorLoggingService();

  late TabController _tabController;

  bool _isLoading = false;
  List<Map<String, dynamic>> _calendarEvents = [];
  List<Map<String, dynamic>> _reminders = [];
  Map<String, dynamic> _calendarStats = {};
  Map<String, dynamic> _reminderStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Здесь должен быть userId текущего пользователя
      const userId = 'current_user_id'; // Заменить на реальный ID

      await Future.wait([
        _loadCalendarEvents(userId),
        _loadReminders(userId),
        _loadStats(userId),
      ]);
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки данных: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCalendarEvents(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final events = await _calendarService.getUserCalendarEvents(
      userId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    if (mounted) {
      setState(() {
        _calendarEvents = events;
      });
    }
  }

  Future<void> _loadReminders(String userId) async {
    final reminders = await _reminderService.getUserReminders(
      userId,
      isActive: true,
    );

    if (mounted) {
      setState(() {
        _reminders = reminders;
      });
    }
  }

  Future<void> _loadStats(String userId) async {
    final calendarStats = await _calendarService.getCalendarStats(userId);
    final reminderStats = await _reminderService.getReminderStats(userId);

    if (mounted) {
      setState(() {
        _calendarStats = calendarStats;
        _reminderStats = reminderStats;
      });
    }
  }

  Future<void> _createEvent() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateEventScreen(),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _createReminder() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateReminderScreen(),
      ),
    );

    if (result == true) {
      _loadData();
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Календарь и Напоминания'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.calendar_today), text: 'События'),
              Tab(icon: Icon(Icons.alarm), text: 'Напоминания'),
              Tab(icon: Icon(Icons.analytics), text: 'Статистика'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildEventsTab(),
                  _buildRemindersTab(),
                  _buildStatsTab(),
                ],
              ),
        floatingActionButton: _buildFloatingActionButton(),
      );

  Widget _buildFloatingActionButton() => FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _createEvent();
          } else {
            _createReminder();
          }
        },
        backgroundColor: Colors.indigo,
        child: Icon(
          _tabController.index == 0 ? Icons.add : Icons.alarm_add,
          color: Colors.white,
        ),
      );

  Widget _buildEventsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_calendarEvents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Нет событий в календаре',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              ..._calendarEvents.map(_buildEventCard),
          ],
        ),
      );

  Widget _buildRemindersTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_reminders.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Нет активных напоминаний',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              ..._reminders.map(_buildReminderCard),
          ],
        ),
      );

  Widget _buildStatsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статистика календаря
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Статистика Календаря',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (_calendarStats.isNotEmpty) ...[
                      _buildStatRow(
                          'Всего событий', '${_calendarStats['totalEvents']}'),
                      _buildStatRow('Событий за месяц',
                          '${_calendarStats['monthlyEvents']}'),
                      _buildStatRow('Синхронизировано',
                          '${_calendarStats['syncedEvents']}'),
                      _buildStatRow('Процент синхронизации',
                          '${(_calendarStats['syncRate'] * 100).toStringAsFixed(1)}%'),
                    ] else
                      const Text('Нет данных'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Статистика напоминаний
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Статистика Напоминаний',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (_reminderStats.isNotEmpty) ...[
                      _buildStatRow('Всего напоминаний',
                          '${_reminderStats['totalReminders']}'),
                      _buildStatRow(
                          'Активных', '${_reminderStats['activeReminders']}'),
                      _buildStatRow('Сработавших',
                          '${_reminderStats['triggeredReminders']}'),
                      _buildStatRow('Повторяющихся',
                          '${_reminderStats['repeatingReminders']}'),
                    ] else
                      const Text('Нет данных'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildEventCard(Map<String, dynamic> event) {
    final startTime = (event['startTime'] as Timestamp).toDate();
    final endTime = (event['endTime'] as Timestamp).toDate();
    final isSynced = event['isSynced'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: isSynced ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isSynced)
                  const Icon(Icons.sync, color: Colors.green, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            if (event['description'] != null)
              Text(
                event['description'] as String,
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_formatDateTime(startTime)} - ${_formatDateTime(endTime)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (event['location'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    event['location'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final reminderTime = (reminder['nextReminderTime'] as Timestamp).toDate();
    final type = reminder['type'] as String;
    final isTriggered = reminder['isTriggered'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getReminderIcon(type),
                  color: isTriggered ? Colors.grey : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reminder['title'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isTriggered ? Colors.grey : null,
                    ),
                  ),
                ),
                if (isTriggered)
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reminder['message'] as String,
              style: TextStyle(
                fontSize: 14,
                color: isTriggered ? Colors.grey : null,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.alarm, size: 16),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(reminderTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: isTriggered ? Colors.grey : null,
                  ),
                ),
                const Spacer(),
                Text(
                  _getReminderTypeName(type),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  IconData _getReminderIcon(String type) {
    switch (type) {
      case 'notification':
        return Icons.notifications;
      case 'email':
        return Icons.email;
      case 'sms':
        return Icons.sms;
      case 'push':
        return Icons.push_pin;
      default:
        return Icons.alarm;
    }
  }

  String _getReminderTypeName(String type) {
    switch (type) {
      case 'notification':
        return 'Уведомление';
      case 'email':
        return 'Email';
      case 'sms':
        return 'SMS';
      case 'push':
        return 'Push';
      default:
        return 'Напоминание';
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

/// Экран создания события
class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final CalendarIntegrationService _calendarService =
      CalendarIntegrationService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
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

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      const userId = 'current_user_id'; // Заменить на реальный ID

      final success = await _calendarService.createCalendarEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        userId: userId,
      );

      if (success) {
        _showSuccessSnackBar('Событие создано успешно!');
        Navigator.of(context).pop(true);
      } else {
        _showErrorSnackBar('Ошибка создания события');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка создания события: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Создать событие'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Название события *',
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

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Место проведения',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Время начала
                      ListTile(
                        title: const Text('Время начала'),
                        subtitle: Text(_formatDateTime(_startTime)),
                        trailing: const Icon(Icons.access_time),
                        onTap: _selectStartTime,
                      ),

                      // Время окончания
                      ListTile(
                        title: const Text('Время окончания'),
                        subtitle: Text(_formatDateTime(_endTime)),
                        trailing: const Icon(Icons.access_time),
                        onTap: _selectEndTime,
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Создать событие',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      );

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

/// Экран создания напоминания
class CreateReminderScreen extends ConsumerStatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  ConsumerState<CreateReminderScreen> createState() =>
      _CreateReminderScreenState();
}

class _CreateReminderScreenState extends ConsumerState<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ReminderSystemService _reminderService = ReminderSystemService();

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  DateTime _reminderTime = DateTime.now().add(const Duration(hours: 1));
  ReminderType _selectedType = ReminderType.notification;
  final List<int> _selectedRepeatDays = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectReminderTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderTime),
      );

      if (time != null) {
        setState(() {
          _reminderTime = DateTime(
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

  Future<void> _createReminder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      const userId = 'current_user_id'; // Заменить на реальный ID

      final reminderId = await _reminderService.createReminder(
        userId: userId,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        reminderTime: _reminderTime,
        type: _selectedType,
        repeatDays: _selectedRepeatDays.isNotEmpty ? _selectedRepeatDays : null,
      );

      if (reminderId != null) {
        _showSuccessSnackBar('Напоминание создано успешно!');
        Navigator.of(context).pop(true);
      } else {
        _showErrorSnackBar('Ошибка создания напоминания');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка создания напоминания: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Создать напоминание'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Название напоминания *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название напоминания';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Сообщение *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите сообщение';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Время напоминания
                      ListTile(
                        title: const Text('Время напоминания'),
                        subtitle: Text(_formatDateTime(_reminderTime)),
                        trailing: const Icon(Icons.alarm),
                        onTap: _selectReminderTime,
                      ),

                      const SizedBox(height: 16),

                      // Тип напоминания
                      const Text(
                        'Тип напоминания',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ReminderType>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: ReminderType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Повторение
                      const Text(
                        'Повторение (дни недели)',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          'Пн',
                          'Вт',
                          'Ср',
                          'Чт',
                          'Пт',
                          'Сб',
                          'Вс',
                        ].asMap().entries.map((entry) {
                          final index = entry.key + 1; // 1-7 для дней недели
                          final dayName = entry.value;
                          final isSelected =
                              _selectedRepeatDays.contains(index);

                          return FilterChip(
                            label: Text(dayName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedRepeatDays.add(index);
                                } else {
                                  _selectedRepeatDays.remove(index);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createReminder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Создать напоминание',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      );

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}
