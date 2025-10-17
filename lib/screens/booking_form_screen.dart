import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/stubs/stubs.dart';
import '../models/specialist.dart';
import '../models/specialist_team.dart';
import '../providers/booking_providers.dart';
import '../providers/specialist_providers.dart';
import '../services/team_service.dart';
import 'team_screen.dart';

/// Экран формы бронирования
class BookingFormScreen extends ConsumerStatefulWidget {
  const BookingFormScreen({
    super.key,
    required this.specialistId,
    this.selectedDate,
  });
  final String specialistId;
  final DateTime? selectedDate;

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _teamService = TeamService();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedHours = 2;
  String? _selectedService;
  bool _isTeamBooking = false;
  String? _selectedTeamId;
  double _advancePercentage = 30;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

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
                onPressed: () => ref.invalidate(specialistProvider(widget.specialistId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingForm(Specialist specialist) => SingleChildScrollView(
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
                        backgroundImage:
                            specialist.avatar != null ? NetworkImage(specialist.avatar!) : null,
                        child:
                            specialist.avatar == null ? const Icon(Icons.person, size: 30) : null,
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
                              specialist.specialization ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  specialist.rating.toStringAsFixed(1) ?? '0.0',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
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

              // Выбор типа бронирования
              Text(
                'Тип бронирования',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        title: const Text('Индивидуальный специалист'),
                        subtitle: const Text('Бронирование одного специалиста'),
                        value: false,
                        groupValue: _isTeamBooking,
                        onChanged: (value) {
                          setState(() {
                            _isTeamBooking = value!;
                            _selectedTeamId = null;
                          });
                        },
                      ),
                      RadioListTile<bool>(
                        title: const Text('Команда специалистов'),
                        subtitle: const Text('Бронирование команды специалистов'),
                        value: true,
                        groupValue: _isTeamBooking,
                        onChanged: (value) {
                          setState(() {
                            _isTeamBooking = value!;
                          });
                        },
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
                initialValue: _selectedService,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Выберите услугу',
                ),
                items: specialist.services
                        .map(
                          (service) => DropdownMenuItem(
                            value: service,
                            child: Text(service),
                          ),
                        )
                        .toList() ??
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

              // Управление командой (если выбран тип "Команда специалистов")
              if (_isTeamBooking) ...[
                _buildTeamManagement(),
                const SizedBox(height: 24),
              ],

              // Настройки оплаты
              Text(
                'Настройки оплаты',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Аванс (%)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _advancePercentage,
                        min: 10,
                        max: 50,
                        divisions: 8,
                        label: '${_advancePercentage.toStringAsFixed(0)}%',
                        onChanged: (value) {
                          setState(() {
                            _advancePercentage = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Аванс: ${_advancePercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Остаток: ${(100 - _advancePercentage).toStringAsFixed(0)}%',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Аванс блокируется при подтверждении бронирования. Остаток переводится после завершения мероприятия.',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                  onPressed: _submitBooking,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Забронировать'),
                ),
              ),

              // TODO(developer): Add error handling
              // if (bookingFormState.errorMessage != null) ...[
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
                        'Error message', // bookingFormState.errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

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

  Widget _buildTeamManagement() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Управление командой',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (_selectedTeamId == null) ...[
                const Text(
                  'Создайте команду специалистов для этого мероприятия',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _createTeam,
                    icon: const Icon(Icons.group_add),
                    label: const Text('Создать команду'),
                  ),
                ),
              ] else ...[
                StreamBuilder<SpecialistTeam?>(
                  stream: _teamService.watchTeam(_selectedTeamId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final team = snapshot.data;
                    if (team == null) {
                      return const Text('Команда не найдена');
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.teamName ?? 'Команда специалистов',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('Специалистов: ${team.specialistCount}'),
                                  Text('Статус: ${team.status.displayName}'),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editTeam(team),
                                  tooltip: 'Редактировать команду',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () => _viewTeam(team),
                                  tooltip: 'Просмотреть команду',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      );

  Future<void> _createTeam() async {
    final teamNameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать команду'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: teamNameController,
              decoration: const InputDecoration(
                labelText: 'Название команды',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание команды',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (result ?? false) {
      try {
        final eventDateTime = _selectedDate != null && _selectedTime != null
            ? DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                _selectedTime!.hour,
                _selectedTime!.minute,
              )
            : null;

        final team = await _teamService.createTeam(
          organizerId: 'current_user_id', // TODO(developer): Get from auth
          eventId: 'event_${DateTime.now().millisecondsSinceEpoch}',
          eventTitle: _selectedService ?? 'Мероприятие',
          eventDate: eventDateTime,
          teamName: teamNameController.text.trim().isEmpty ? null : teamNameController.text.trim(),
          description:
              descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        setState(() {
          _selectedTeamId = team.id;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Команда создана успешно')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка создания команды: $e')),
          );
        }
      }
    }
  }

  void _editTeam(SpecialistTeam team) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TeamScreen(
          teamId: team.id,
        ),
      ),
    );
  }

  void _viewTeam(SpecialistTeam team) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TeamScreen(
          teamId: team.id,
          isEditable: false,
        ),
      ),
    );
  }

  void _submitBooking() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату и время')),
      );
      return;
    }

    if (_isTeamBooking && _selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Создайте команду специалистов')),
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

    // TODO(developer): Implement booking creation
    // ref
    //     .read(bookingFormProvider.notifier)
    //     .createBooking(
    //       specialistId: widget.specialistId,
    //       eventDate: eventDateTime,
    //       duration: Duration(hours: _selectedHours),
    //       service: _selectedService!,
    //       notes: _notesController.text.trim(),
    //       isTeamBooking: _isTeamBooking,
    //       teamId: _selectedTeamId,
    //     )
    //     .then((_) {

    // Stub implementation
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isTeamBooking
                  ? 'Бронирование команды создано успешно'
                  : 'Бронирование создано успешно',
            ),
          ),
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
