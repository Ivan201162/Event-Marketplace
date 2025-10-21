import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/availability_calendar.dart';
import '../services/availability_service.dart';

class TestAvailabilityScreen extends ConsumerStatefulWidget {
  const TestAvailabilityScreen({super.key});

  @override
  ConsumerState<TestAvailabilityScreen> createState() => _TestAvailabilityScreenState();
}

class _TestAvailabilityScreenState extends ConsumerState<TestAvailabilityScreen> {
  final AvailabilityService _availabilityService = AvailabilityService();
  final String _testSpecialistId = 'test_specialist_1';

  List<AvailabilityCalendar> _availabilityData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailabilityData();
  }

  Future<void> _loadAvailabilityData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now().add(const Duration(days: 30));

      final data = await _availabilityService.getSpecialistAvailability(
        _testSpecialistId,
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _availabilityData = data;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Тест календаря доступности'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadAvailabilityData,
          tooltip: 'Обновить данные',
        ),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Панель управления
              _buildControlPanel(),

              // Список данных
              Expanded(child: _buildAvailabilityList()),
            ],
          ),
  );

  Widget _buildControlPanel() => Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Управление календарем',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Кнопки действий
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _addBusyDate,
                icon: const Icon(Icons.block),
                label: const Text('Добавить занятую дату'),
              ),
              ElevatedButton.icon(
                onPressed: _addTimeSlot,
                icon: const Icon(Icons.schedule),
                label: const Text('Добавить временной слот'),
              ),
              ElevatedButton.icon(
                onPressed: _testAvailability,
                icon: const Icon(Icons.check),
                label: const Text('Проверить доступность'),
              ),
              ElevatedButton.icon(
                onPressed: _clearAllData,
                icon: const Icon(Icons.clear_all),
                label: const Text('Очистить все'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildAvailabilityList() {
    if (_availabilityData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет данных о доступности'),
            Text('Добавьте занятые даты или временные слоты'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availabilityData.length,
      itemBuilder: (context, index) {
        final availability = _availabilityData[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              availability.isAvailable ? Icons.check_circle : Icons.block,
              color: availability.isAvailable ? Colors.green : Colors.red,
            ),
            title: Text(
              '${availability.date.day}.${availability.date.month}.${availability.date.year}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(availability.isAvailable ? 'Доступен' : 'Занят'),
                if (availability.note != null) Text('Примечание: ${availability.note}'),
                if (availability.timeSlots.isNotEmpty)
                  Text('Слотов: ${availability.timeSlots.length}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [Icon(Icons.edit), SizedBox(width: 8), Text('Редактировать')],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Удалить', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteAvailability(availability);
                }
              },
            ),
            onTap: () => _showAvailabilityDetails(availability),
          ),
        );
      },
    );
  }

  Future<void> _addBusyDate() async {
    final date = await _selectDate();
    if (date == null) return;

    final note = await _showNoteDialog('Примечание (необязательно)');

    final success = await _availabilityService.addBusyDate(_testSpecialistId, date, note: note);

    if (success) {
      _loadAvailabilityData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Занятая дата добавлена')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка добавления даты')));
      }
    }
  }

  Future<void> _addTimeSlot() async {
    final date = await _selectDate();
    if (date == null) return;

    final timeSlot = await _showTimeSlotDialog();
    if (timeSlot == null) return;

    final success = await _availabilityService.addTimeSlot(_testSpecialistId, date, timeSlot);

    if (success) {
      _loadAvailabilityData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Временной слот добавлен')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка добавления слота')));
      }
    }
  }

  Future<void> _testAvailability() async {
    final date = await _selectDate();
    if (date == null) return;

    final time = await _selectTime();
    if (time == null) return;

    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    final isAvailable = await _availabilityService.isSpecialistAvailable(
      _testSpecialistId,
      dateTime,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAvailable
                ? 'Специалист доступен в ${dateTime.day}.${dateTime.month}.${dateTime.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}'
                : 'Специалист занят в ${dateTime.day}.${dateTime.month}.${dateTime.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
          ),
          backgroundColor: isAvailable ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все данные'),
        content: const Text('Вы уверены, что хотите удалить все данные о доступности?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      // Удаляем все записи
      for (final availability in _availabilityData) {
        await _availabilityService.removeBusyDate(_testSpecialistId, availability.date);
      }

      _loadAvailabilityData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Все данные удалены')));
      }
    }
  }

  Future<void> _deleteAvailability(AvailabilityCalendar availability) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись'),
        content: Text(
          'Удалить запись за ${availability.date.day}.${availability.date.month}.${availability.date.year}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final success = await _availabilityService.removeBusyDate(
        _testSpecialistId,
        availability.date,
      );

      if (success) {
        _loadAvailabilityData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Запись удалена')));
        }
      }
    }
  }

  void _showAvailabilityDetails(AvailabilityCalendar availability) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${availability.date.day}.${availability.date.month}.${availability.date.year}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  availability.isAvailable ? Icons.check_circle : Icons.block,
                  color: availability.isAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(availability.isAvailable ? 'Доступен' : 'Занят'),
              ],
            ),
            if (availability.note != null) ...[
              const SizedBox(height: 8),
              Text('Примечание: ${availability.note}'),
            ],
            if (availability.timeSlots.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Временные слоты:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...availability.timeSlots.map(_buildTimeSlotInfo),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  Widget _buildTimeSlotInfo(TimeSlot slot) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: slot.isAvailable ? Colors.green.shade50 : Colors.red.shade50,
      border: Border.all(color: slot.isAvailable ? Colors.green : Colors.red),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      children: [
        Icon(
          slot.isAvailable ? Icons.check_circle : Icons.block,
          color: slot.isAvailable ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
          style: const TextStyle(fontSize: 12),
        ),
        if (slot.note != null) ...[
          const Spacer(),
          Text(slot.note!, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ],
    ),
  );

  Future<DateTime?> _selectDate() async => showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );

  Future<TimeOfDay?> _selectTime() async =>
      showTimePicker(context: context, initialTime: TimeOfDay.now());

  Future<String?> _showNoteDialog(String title) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Введите примечание',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Future<TimeSlot?> _showTimeSlotDialog() async {
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    String? note;

    return showDialog<TimeSlot>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить временной слот'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Время начала'),
                subtitle: Text(
                  startTime != null
                      ? '${startTime!.hour}:${startTime!.minute.toString().padLeft(2, '0')}'
                      : 'Выберите время',
                ),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) {
                    setState(() {
                      startTime = time;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('Время окончания'),
                subtitle: Text(
                  endTime != null
                      ? '${endTime!.hour}:${endTime!.minute.toString().padLeft(2, '0')}'
                      : 'Выберите время',
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: startTime ?? TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      endTime = time;
                    });
                  }
                },
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Примечание (необязательно)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => note = value,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: (startTime != null && endTime != null)
                  ? () {
                      final now = DateTime.now();
                      final start = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        startTime!.hour,
                        startTime!.minute,
                      );
                      final end = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        endTime!.hour,
                        endTime!.minute,
                      );

                      final timeSlot = TimeSlot(
                        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
                        startTime: start,
                        endTime: end,
                        note: note,
                      );

                      Navigator.pop(context, timeSlot);
                    }
                  : null,
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
