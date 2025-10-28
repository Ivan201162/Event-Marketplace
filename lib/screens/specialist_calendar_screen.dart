import 'package:event_marketplace_app/models/specialist_schedule.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/providers/calendar_providers.dart';
import 'package:event_marketplace_app/widgets/calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpecialistCalendarScreen extends ConsumerStatefulWidget {
  const SpecialistCalendarScreen({super.key});

  @override
  ConsumerState<SpecialistCalendarScreen> createState() =>
      _SpecialistCalendarScreenState();
}

class _SpecialistCalendarScreenState
    extends ConsumerState<SpecialistCalendarScreen> {
  @override
  void initState() {
    super.initState();
    // Инициализируем календарь с текущим пользователем
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null && currentUser.isSpecialist) {
        ref
            .read(calendarStateProvider.notifier)
            .selectSpecialist(currentUser.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final calendarState = ref.watch(calendarStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мое расписание'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddEventDialog(context),),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showAnalyticsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () => _showTestDataDialog(context),
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null || !user.isSpecialist) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Доступно только для специалистов',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Статистика
                _buildStatsCard(context, user.id),

                const SizedBox(height: 16),

                // Календарь
                CalendarWidget(
                  specialistId: user.id,
                  showTimeSlots: true,
                  onDateSelected: (date) {
                    // Обработка выбора даты
                  },
                ),

                const SizedBox(height: 16),

                // Быстрые действия
                _buildQuickActionsCard(context, user.id),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
            ],
          ),
        ),
      ),
    );
  }

  /// Карточка статистики
  Widget _buildStatsCard(BuildContext context, String specialistId) {
    final scheduleAsync = ref.watch(specialistScheduleProvider(specialistId));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            scheduleAsync.when(
              data: (schedule) {
                final totalEvents = schedule?.events.length ?? 0;
                final bookingEvents = schedule?.events
                        .where((e) => e.type == ScheduleEventType.booking)
                        .length ??
                    0;
                final unavailableEvents = schedule?.events
                        .where((e) => e.type == ScheduleEventType.unavailable)
                        .length ??
                    0;
                final vacationEvents = schedule?.events
                        .where((e) => e.type == ScheduleEventType.vacation)
                        .length ??
                    0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                        context, 'Всего событий', totalEvents, Colors.blue,),
                    _buildStatItem(
                        context, 'Бронирования', bookingEvents, Colors.green,),
                    _buildStatItem(context, 'Недоступность', unavailableEvents,
                        Colors.red,),
                    _buildStatItem(
                        context, 'Отпуск', vacationEvents, Colors.orange,),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Ошибка: $error'),
            ),
          ],
        ),
      ),
    );
  }

  /// Элемент статистики
  Widget _buildStatItem(
          BuildContext context, String label, int count, Color color,) =>
      Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle,),
            child: Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color,),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  /// Карточка быстрых действий
  Widget _buildQuickActionsCard(BuildContext context, String specialistId) =>
      Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Быстрые действия',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showAddUnavailableDialog(context, specialistId),
                      icon: const Icon(Icons.block),
                      label: const Text('Недоступность'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showAddVacationDialog(context, specialistId),
                      icon: const Icon(Icons.beach_access),
                      label: const Text('Отпуск'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showTestDataDialog(context),
                  icon: const Icon(Icons.science),
                  label: const Text('Добавить тестовые данные'),
                ),
              ),
            ],
          ),
        ),
      );

  /// Показать диалог добавления события
  void _showAddEventDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить событие'),
        content: const Text('Выберите тип события для добавления'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO(developer): Показать форму добавления события
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  /// Показать диалог добавления недоступности
  void _showAddUnavailableDialog(BuildContext context, String specialistId) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить недоступность'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    hintText: 'Например: Техническое обслуживание',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Описание (необязательно)',),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    startDate == null
                        ? 'Выберите дату начала'
                        : 'Начало: ${_formatDate(startDate!)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  title: Text(
                    endDate == null
                        ? 'Выберите дату окончания'
                        : 'Окончание: ${_formatDate(endDate!)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => endDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    startDate == null ||
                    endDate == null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(
                      content: Text('Заполните все обязательные поля'),),);
                  return;
                }

                try {
                  await ref
                      .read(calendarServiceProvider)
                      .createUnavailableEvent(
                        specialistId: specialistId,
                        startDate: startDate!,
                        endDate: endDate!,
                        reason: titleController.text.isEmpty
                            ? null
                            : titleController.text,
                      );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(
                        content: Text('Недоступность добавлена'),),);
                  }
                } on Exception catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                  }
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  /// Показать диалог добавления отпуска
  void _showAddVacationDialog(BuildContext context, String specialistId) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить отпуск'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    hintText: 'Например: Ежегодный отпуск',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Описание (необязательно)',),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    startDate == null
                        ? 'Выберите дату начала'
                        : 'Начало: ${_formatDate(startDate!)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  title: Text(
                    endDate == null
                        ? 'Выберите дату окончания'
                        : 'Окончание: ${_formatDate(endDate!)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => endDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    startDate == null ||
                    endDate == null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(
                      content: Text('Заполните все обязательные поля'),),);
                  return;
                }

                try {
                  await ref.read(calendarServiceProvider).createVacationEvent(
                        specialistId: specialistId,
                        startDate: startDate!,
                        endDate: endDate!,
                        reason: titleController.text.isEmpty
                            ? null
                            : titleController.text,
                      );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                        const SnackBar(content: Text('Отпуск добавлен')),);
                  }
                } on Exception catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                  }
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  /// Показать диалог тестовых данных
  void _showTestDataDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тестовые данные'),
        content:
            const Text('Добавить тестовые данные календаря для разработки?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(calendarServiceProvider)
                    .addTestData('current_specialist');
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(
                      content: Text('Тестовые данные добавлены'),),);
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                }
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  /// Форматировать дату
  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';

  /// Показать диалог аналитики
  void _showAnalyticsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Аналитика календаря'),
        content: const Text(
            'Здесь будет отображаться аналитика календаря специалиста',),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),),
        ],
      ),
    );
  }
}
