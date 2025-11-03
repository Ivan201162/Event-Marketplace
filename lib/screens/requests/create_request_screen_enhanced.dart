import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';

/// Экран создания заявки
class CreateRequestScreenEnhanced extends StatefulWidget {
  const CreateRequestScreenEnhanced({super.key});

  @override
  State<CreateRequestScreenEnhanced> createState() => _CreateRequestScreenEnhancedState();
}

class _CreateRequestScreenEnhancedState extends State<CreateRequestScreenEnhanced> {
  final _formKey = GlobalKey<FormState>();
  final _eventTypeController = TextEditingController();
  final _eventTypeCustomController = TextEditingController();
  final _timeController = TextEditingController();
  final _cityController = TextEditingController();
  final _venueController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _guestsCountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedEventType;
  DateTime? _selectedDate;
  List<String> _attachmentUrls = [];
  List<File> _selectedFiles = [];
  bool _isUploading = false;
  bool _isSubmitting = false;

  final List<String> _eventTypes = [
    'Выпускной',
    'Детский праздник',
    'Тимбилдинг',
    'Свадьба',
    'Юбилей',
    'Бизнес-ивент',
    'Конференция',
    'Выставка',
    'Концерт',
    'Мастер-класс',
    'Фестиваль',
    'Промо-акция',
    'Корпоратив',
    'Новый год',
    'Выпускной в саду',
    'Бар-мицва',
    'Девичник',
    'Мальчишник',
    'Презентация',
    'Открытие',
    'Награждение',
    'Семейный праздник',
    'День рождения',
    'Фотосессия',
    'Видеосъемка',
    'DJ',
    'Ведущий',
    'Декор',
    'Кейтеринг',
    'Анимация',
    'Музыкальная группа',
    'Фейерверк',
    'Другое',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("REQUEST_CREATE_OPENED");
    });
  }

  @override
  void dispose() {
    _eventTypeController.dispose();
    _eventTypeCustomController.dispose();
    _timeController.dispose();
    _cityController.dispose();
    _venueController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _guestsCountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final files = result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .where((file) {
          final size = file.lengthSync();
          if (size > 10 * 1024 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Файл ${file.path.split('/').last} превышает 10 МБ')),
            );
            return false;
          }
          return true;
        }).toList();

        if (_selectedFiles.length + files.length > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Максимум 10 файлов')),
          );
          files.removeRange(10 - _selectedFiles.length, files.length);
        }

        setState(() {
          _selectedFiles.addAll(files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка выбора файлов: $e')),
      );
    }
  }

  Future<void> _uploadFiles(String requestId) async {
    if (_selectedFiles.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final storage = FirebaseStorage.instance;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final urls = <String>[];

      for (final file in _selectedFiles) {
        final fileName = file.path.split('/').last;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ref = storage.ref().child('uploads/requests/${user.uid}/$requestId/${timestamp}_$fileName');

        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        urls.add(url);
      }

      setState(() {
        _attachmentUrls = urls;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      throw Exception('Ошибка загрузки файлов: $e');
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEventType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите тип мероприятия')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final requestRef = FirebaseFirestore.instance.collection('requests').doc();
      final requestId = requestRef.id;

      // Загружаем файлы если есть
      if (_selectedFiles.isNotEmpty) {
        await _uploadFiles(requestId);
      }

      final eventType = _selectedEventType == 'Другое'
          ? _eventTypeCustomController.text.trim()
          : _selectedEventType!;

      await requestRef.set({
        'eventType': eventType,
        'eventTypeCustom': _selectedEventType == 'Другое' ? eventType : null,
        'date': Timestamp.fromDate(_selectedDate!),
        'time': _timeController.text.trim().isEmpty ? null : _timeController.text.trim(),
        'city': _cityController.text.trim(),
        'venue': _venueController.text.trim().isEmpty ? null : _venueController.text.trim(),
        'budgetMin': _budgetMinController.text.trim().isEmpty
            ? null
            : double.tryParse(_budgetMinController.text.trim()),
        'budgetMax': _budgetMaxController.text.trim().isEmpty
            ? null
            : double.tryParse(_budgetMaxController.text.trim()),
        'guestsCount': _guestsCountController.text.trim().isEmpty
            ? null
            : int.tryParse(_guestsCountController.text.trim()),
        'description': _descriptionController.text.trim(),
        'attachments': _attachmentUrls,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'new',
      });

      debugLog("REQUEST_PUBLISHED:$requestId");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заявка опубликована')),
        );
        context.pop(); // Возвращаемся на предыдущий экран
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.pop();
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Создать заявку'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Тип мероприятия
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Тип мероприятия *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEventType,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _eventTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedEventType = value);
                      },
                      validator: (v) => v == null ? 'Обязательное поле' : null,
                    ),
                    if (_selectedEventType == 'Другое') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _eventTypeCustomController,
                        decoration: const InputDecoration(
                          labelText: 'Введите свой вариант *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v?.trim().isEmpty ?? true ? 'Обязательное поле' : null,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Дата и время
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Дата *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate != null
                                  ? DateFormat('dd.MM.yyyy').format(_selectedDate!)
                                  : 'Выберите дату',
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: 'Время (опционально)',
                        hintText: 'например, 18:00',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Город
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Город *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Обязательное поле' : null,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Место проведения
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _venueController,
                  decoration: const InputDecoration(
                    labelText: 'Место проведения (опционально)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Бюджет
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Бюджет (опционально)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _budgetMinController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'От',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _budgetMaxController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'До',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Количество гостей
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _guestsCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Количество гостей (опционально)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Описание
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Описание *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Обязательное поле' : null,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Вложения
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Вложения (опционально)', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_selectedFiles.length}/10', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Прикрепить файлы'),
                      onPressed: _selectedFiles.length >= 10 ? null : _pickFiles,
                    ),
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...List.generate(_selectedFiles.length, (index) {
                        final file = _selectedFiles[index];
                        return ListTile(
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(file.path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() => _selectedFiles.removeAt(index));
                            },
                          ),
                        );
                      }),
                    ],
                    if (_isUploading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: (_isSubmitting || _isUploading) ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting || _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Опубликовать заявку', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
      ),
    );
  }
}
