import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/auth_providers.dart';

/// Экран настройки рабочего времени специалиста
class WorkingHoursSettingsScreen extends ConsumerStatefulWidget {
  const WorkingHoursSettingsScreen({super.key});

  @override
  ConsumerState<WorkingHoursSettingsScreen> createState() => _WorkingHoursSettingsScreenState();
}

class _WorkingHoursSettingsScreenState extends ConsumerState<WorkingHoursSettingsScreen> {
  final Map<String, bool> _selectedDays = {
    'monday': false,
    'tuesday': false,
    'wednesday': false,
    'thursday': false,
    'friday': false,
    'saturday': false,
    'sunday': false,
  };

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  /// Загрузить текущие настройки рабочего времени
  Future<void> _loadCurrentSettings() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final specialistDoc = await FirebaseFirestore.instance
          .collection('specialists')
          .where('userId', isEqualTo: currentUser.value?.id)
          .limit(1)
          .get();

      if (specialistDoc.docs.isNotEmpty) {
        final data = specialistDoc.docs.first.data();
        final workingHours = data['workingHours'] as Map<String, dynamic>?;

        if (workingHours != null) {
          setState(() {
            // Загружаем выбранные дни
            for (final day in _selectedDays.keys) {
              _selectedDays[day] = (workingHours['days']?[day] as bool?) ?? false;
            }

            // Загружаем время
            final startHour = workingHours['startHour'] as int? ?? 9;
            final startMinute = workingHours['startMinute'] as int? ?? 0;
            final endHour = workingHours['endHour'] as int? ?? 18;
            final endMinute = workingHours['endMinute'] as int? ?? 0;

            _startTime = TimeOfDay(hour: startHour, minute: startMinute);
            _endTime = TimeOfDay(hour: endHour, minute: endMinute);
          });
        }
      }
    } catch (e) {
      print('Error loading working hours settings: $e');
    }
  }

  /// Сохранить настройки рабочего времени
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final specialistDoc = await FirebaseFirestore.instance
          .collection('specialists')
          .where('userId', isEqualTo: currentUser.value?.id)
          .limit(1)
          .get();

      if (specialistDoc.docs.isNotEmpty) {
        final docId = specialistDoc.docs.first.id;
        
        await FirebaseFirestore.instance
            .collection('specialists')
            .doc(docId)
            .update({
          'workingHours': {
            'days': _selectedDays,
            'startHour': _startTime.hour,
            'startMinute': _startTime.minute,
            'endHour': _endTime.hour,
            'endMinute': _endTime.minute,
            'updatedAt': Timestamp.now(),
          },
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Настройки рабочего времени сохранены'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
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

  /// Выбрать время начала работы
  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  /// Выбрать время окончания работы
  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рабочее время'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информационная карточка
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Настройка уведомлений',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Уведомления от клиентов будут приходить только в указанное рабочее время. В остальное время они будут отложены до утра.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Дни недели
            Text(
              'Рабочие дни',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ..._selectedDays.keys.map((day) {
              final dayNames = {
                'monday': 'Понедельник',
                'tuesday': 'Вторник',
                'wednesday': 'Среда',
                'thursday': 'Четверг',
                'friday': 'Пятница',
                'saturday': 'Суббота',
                'sunday': 'Воскресенье',
              };

              return CheckboxListTile(
                title: Text(dayNames[day]!),
                value: _selectedDays[day],
                onChanged: (bool? value) {
                  setState(() {
                    _selectedDays[day] = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),

            const SizedBox(height: 24),

            // Время работы
            Text(
              'Время работы',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Начало работы'),
                      subtitle: Text(_startTime.format(context)),
                      onTap: _selectStartTime,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.access_time_filled),
                      title: const Text('Окончание работы'),
                      subtitle: Text(_endTime.format(context)),
                      onTap: _selectEndTime,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Кнопка сохранения
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Сохранить настройки',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Дополнительная информация
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Совет',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Рекомендуем установить рабочее время с 9:00 до 18:00 для максимальной отзывчивости клиентам.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
