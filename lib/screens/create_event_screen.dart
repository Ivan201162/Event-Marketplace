import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import '../providers/auth_providers.dart';
import '../providers/event_providers.dart';

/// Экран создания/редактирования события
class CreateEventScreen extends ConsumerStatefulWidget {
  // Для редактирования существующего события

  const CreateEventScreen({
    super.key,
    this.event,
  });
  final Event? event;

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _requirementsController = TextEditingController();

  DateTime _eventDate = DateTime.now();
  DateTime? _endDate;
  EventCategory _category = EventCategory.other;
  int _maxParticipants = 50;
  double _price = 0;
  bool _isPublic = true;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();

    if (widget.event != null) {
      // Редактирование существующего события
      final event = widget.event!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _locationController.text = event.location;
      _priceController.text = event.price.toString();
      _maxParticipantsController.text = event.maxParticipants.toString();
      _contactInfoController.text = event.contactInfo ?? '';
      _requirementsController.text = event.requirements ?? '';
      _eventDate = event.date;
      _endDate = event.endDate;
      _category = event.category;
      _maxParticipants = event.maxParticipants;
      _price = event.price;
      _isPublic = event.isPublic;
      _tags = List.from(event.tags);
    } else {
      // Установка значений по умолчанию
      _maxParticipantsController.text = _maxParticipants.toString();
      _priceController.text = _price.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _maxParticipantsController.dispose();
    _contactInfoController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createEventState = ref.watch(createEventProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.event != null
              ? 'Редактировать мероприятие'
              : 'Создать мероприятие',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: createEventState.isLoading ? null : _saveEvent,
            child: createEventState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Сохранить'),
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

              // Дата и время
              _buildDateTimeSection(),

              const SizedBox(height: 24),

              // Категория и цена
              _buildCategoryAndPriceSection(),

              const SizedBox(height: 24),

              // Участники и настройки
              _buildParticipantsAndSettingsSection(),

              const SizedBox(height: 24),

              // Дополнительная информация
              _buildAdditionalInfoSection(),

              const SizedBox(height: 24),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: createEventState.isLoading ? null : _saveEvent,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: createEventState.isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Сохранение...'),
                          ],
                        )
                      : Text(
                          widget.event != null
                              ? 'Обновить мероприятие'
                              : 'Создать мероприятие',
                        ),
                ),
              ),

              if (createEventState.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          createEventState.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() => Card(
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

              // Название мероприятия
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название мероприятия *',
                  border: OutlineInputBorder(),
                  hintText: 'Введите название мероприятия',
                  prefixIcon: Icon(Icons.event),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите название мероприятия';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание *',
                  border: OutlineInputBorder(),
                  hintText: 'Опишите ваше мероприятие',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите описание мероприятия';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Место проведения
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Место проведения *',
                  border: OutlineInputBorder(),
                  hintText: 'Введите адрес или название места',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите место проведения';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildDateTimeSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Дата и время',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Дата мероприятия
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Дата мероприятия'),
                subtitle: Text(_formatDate(_eventDate)),
                onTap: _selectDate,
              ),

              const SizedBox(height: 16),

              // Дата окончания (опционально)
              ListTile(
                leading: const Icon(Icons.event_available),
                title: const Text('Дата окончания (опционально)'),
                subtitle: Text(
                  _endDate != null ? _formatDate(_endDate!) : 'Не указана',
                ),
                onTap: _selectEndDate,
                trailing: _endDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _endDate = null;
                          });
                        },
                      )
                    : null,
              ),
            ],
          ),
        ),
      );

  Widget _buildCategoryAndPriceSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Категория и цена',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Категория мероприятия
              DropdownButtonFormField<EventCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Категория мероприятия',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: EventCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(category.categoryIcon, size: 20),
                            const SizedBox(width: 8),
                            Text(category.categoryName),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value ?? EventCategory.other;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Цена
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Цена (₽)',
                  border: OutlineInputBorder(),
                  hintText: '0 - для бесплатного мероприятия',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _price = double.tryParse(value) ?? 0.0;
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildParticipantsAndSettingsSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Участники и настройки',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Максимальное количество участников
              TextFormField(
                controller: _maxParticipantsController,
                decoration: const InputDecoration(
                  labelText: 'Максимальное количество участников',
                  border: OutlineInputBorder(),
                  hintText: '50',
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _maxParticipants = int.tryParse(value) ?? 50;
                },
              ),

              const SizedBox(height: 16),

              // Публичность мероприятия
              SwitchListTile(
                title: const Text('Публичное мероприятие'),
                subtitle: const Text(
                  'Другие пользователи смогут найти и забронировать ваше мероприятие',
                ),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildAdditionalInfoSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Дополнительная информация',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Контактная информация
              TextFormField(
                controller: _contactInfoController,
                decoration: const InputDecoration(
                  labelText: 'Контактная информация',
                  border: OutlineInputBorder(),
                  hintText: 'Телефон, email или другие способы связи',
                  prefixIcon: Icon(Icons.contact_phone),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Требования к участникам
              TextFormField(
                controller: _requirementsController,
                decoration: const InputDecoration(
                  labelText: 'Требования к участникам',
                  border: OutlineInputBorder(),
                  hintText: 'Возраст, опыт, специальные требования',
                  prefixIcon: Icon(Icons.info),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      );

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_eventDate),
      );

      if (time != null) {
        setState(() {
          _eventDate = DateTime(
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

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _eventDate,
      firstDate: _eventDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate ?? _eventDate),
      );

      if (time != null) {
        setState(() {
          _endDate = DateTime(
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

    final currentUser = ref.read(currentUserProvider);
    currentUser.whenData((user) async {
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пользователь не авторизован'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final createEventNotifier = ref.read(createEventProvider.notifier);

      // Обновляем состояние формы
      createEventNotifier.updateTitle(_titleController.text.trim());
      createEventNotifier.updateDescription(_descriptionController.text.trim());
      createEventNotifier.updateDate(_eventDate);
      createEventNotifier.updateEndDate(_endDate);
      createEventNotifier.updateLocation(_locationController.text.trim());
      createEventNotifier.updatePrice(_price);
      createEventNotifier.updateCategory(_category);
      createEventNotifier.updateMaxParticipants(_maxParticipants);
      createEventNotifier.updateContactInfo(
        _contactInfoController.text.trim().isEmpty
            ? null
            : _contactInfoController.text.trim(),
      );
      createEventNotifier.updateRequirements(
        _requirementsController.text.trim().isEmpty
            ? null
            : _requirementsController.text.trim(),
      );
      createEventNotifier.updateIsPublic(_isPublic);

      if (widget.event != null) {
        // Редактирование существующего события
        try {
          final eventService = ref.read(eventServiceProvider);
          final updatedEvent = widget.event!.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            date: _eventDate,
            endDate: _endDate,
            location: _locationController.text.trim(),
            price: _price,
            category: _category,
            maxParticipants: _maxParticipants,
            contactInfo: _contactInfoController.text.trim().isEmpty
                ? null
                : _contactInfoController.text.trim(),
            requirements: _requirementsController.text.trim().isEmpty
                ? null
                : _requirementsController.text.trim(),
            isPublic: _isPublic,
            updatedAt: DateTime.now(),
          );

          await eventService.updateEvent(widget.event!.id, updatedEvent);

          if (context.mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Мероприятие обновлено'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка обновления: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Создание нового события
        final eventId = await createEventNotifier.createEvent(
          Event(
            id: '',
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            date: _eventDate,
            endDate: _endDate,
            location: _locationController.text.trim(),
            price: _price,
            category: _category,
            maxParticipants: _maxParticipants,
            contactInfo: _contactInfoController.text.trim().isEmpty
                ? null
                : _contactInfoController.text.trim(),
            requirements: _requirementsController.text.trim().isEmpty
                ? null
                : _requirementsController.text.trim(),
            isPublic: _isPublic,
            organizerId: user.id,
            organizerName: user.displayNameOrEmail,
            organizerPhoto: user.photoURL,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            participantsCount: 0,
            status: EventStatus.active,
          ),
        );

        if (eventId != null && context.mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Мероприятие создано'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  String _formatDate(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}
