import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/guest_service.dart';

/// Экран создания события для гостей
class CreateGuestEventScreen extends ConsumerStatefulWidget {
  const CreateGuestEventScreen({super.key, required this.organizerId});
  final String organizerId;

  @override
  ConsumerState<CreateGuestEventScreen> createState() => _CreateGuestEventScreenState();
}

class _CreateGuestEventScreenState extends ConsumerState<CreateGuestEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxGuestsController = TextEditingController();

  final GuestService _guestService = GuestService();

  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 2));
  bool _isPublic = true;
  bool _allowGreetings = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxGuestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Создать событие для гостей')),
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

            // Настройки
            _buildSettingsSection(),

            const SizedBox(height: 24),

            // Кнопка создания
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createEvent,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Создать событие'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildBasicInfoSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Основная информация',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Название события
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Название события *',
              border: OutlineInputBorder(),
              hintText: 'Введите название события',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, введите название события';
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
              labelText: 'Место проведения *',
              border: OutlineInputBorder(),
              hintText: 'Введите место проведения',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, введите место проведения';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Максимальное количество гостей
          TextFormField(
            controller: _maxGuestsController,
            decoration: const InputDecoration(
              labelText: 'Максимальное количество гостей *',
              border: OutlineInputBorder(),
              hintText: 'Введите максимальное количество гостей',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Пожалуйста, введите максимальное количество гостей';
              }
              final count = int.tryParse(value);
              if (count == null || count <= 0) {
                return 'Пожалуйста, введите корректное количество гостей';
              }
              return null;
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildTimeSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Время проведения',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Дата и время начала
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Дата и время начала'),
            subtitle: Text(_formatDateTime(_startTime)),
            onTap: _selectStartTime,
          ),

          // Дата и время окончания
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Дата и время окончания'),
            subtitle: Text(_formatDateTime(_endTime)),
            onTap: _selectEndTime,
          ),
        ],
      ),
    ),
  );

  Widget _buildSettingsSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Настройки события',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Публичное событие
          SwitchListTile(
            title: const Text('Публичное событие'),
            subtitle: const Text('Событие будет видно всем пользователям'),
            value: _isPublic,
            onChanged: (value) {
              setState(() {
                _isPublic = value;
              });
            },
          ),

          // Разрешить поздравления
          SwitchListTile(
            title: const Text('Разрешить поздравления'),
            subtitle: const Text('Гости смогут загружать поздравления и фото'),
            value: _allowGreetings,
            onChanged: (value) {
              setState(() {
                _allowGreetings = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Информация о возможностях
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Возможности события',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Гости смогут регистрироваться по ссылке\n'
                  '• QR коды для быстрой регистрации\n'
                  '• Отслеживание статуса гостей\n'
                  '• Загрузка поздравлений и фото\n'
                  '• Статистика посещаемости',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

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
          _startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

          // Автоматически обновляем время окончания
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(hours: 2));
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
          _endTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
      final eventId = await _guestService.createGuestEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startTime,
        endDate: _endTime,
        location: _locationController.text.trim(),
        organizerName: 'Демо Организатор', // TODO(developer): Получить из контекста
      );

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Событие успешно создано'), backgroundColor: Colors.green),
      );
    } on Exception catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}
