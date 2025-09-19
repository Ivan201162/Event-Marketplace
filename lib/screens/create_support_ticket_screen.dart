import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/support_ticket.dart';
import '../providers/auth_providers.dart';
import '../services/support_service.dart';

/// Экран создания тикета поддержки
class CreateSupportTicketScreen extends ConsumerStatefulWidget {
  const CreateSupportTicketScreen({super.key});

  @override
  ConsumerState<CreateSupportTicketScreen> createState() =>
      _CreateSupportTicketScreenState();
}

class _CreateSupportTicketScreenState
    extends ConsumerState<CreateSupportTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  final SupportService _supportService = SupportService();

  SupportCategory _selectedCategory = SupportCategory.general;
  SupportPriority _selectedPriority = SupportPriority.medium;
  final List<File> _attachments = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Создать тикет поддержки'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _submitTicket,
              child: const Text('Отправить'),
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

                // Категория и приоритет
                _buildCategoryAndPrioritySection(),

                const SizedBox(height: 24),

                // Вложения
                _buildAttachmentsSection(),

                const SizedBox(height: 24),

                // Кнопка отправки
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitTicket,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Отправить тикет'),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Тема
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Тема *',
                  border: OutlineInputBorder(),
                  hintText: 'Кратко опишите проблему',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите тему';
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
                  hintText: 'Подробно опишите проблему или вопрос',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите описание';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildCategoryAndPrioritySection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Категория и приоритет',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Категория
              DropdownButtonFormField<SupportCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория *',
                  border: OutlineInputBorder(),
                ),
                items: SupportCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(category.icon, size: 20),
                            const SizedBox(width: 8),
                            Text(category.categoryText),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? SupportCategory.general;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Приоритет
              DropdownButtonFormField<SupportPriority>(
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Приоритет',
                  border: OutlineInputBorder(),
                ),
                items: SupportPriority.values
                    .map(
                      (priority) => DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: priority.priorityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(priority.priorityText),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value ?? SupportPriority.medium;
                  });
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildAttachmentsSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Вложения',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_attachments.length}/5',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Кнопка добавления файлов
              if (_attachments.length < 5)
                OutlinedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Добавить файлы'),
                ),

              const SizedBox(height: 16),

              // Список вложений
              if (_attachments.isNotEmpty) ...[
                const Text(
                  'Выбранные файлы:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ..._attachments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getFileIcon(file.path),
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.path.split('/').last,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeAttachment(index),
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 8),

              // Информация о поддерживаемых форматах
              Text(
                'Поддерживаемые форматы: изображения, документы (до 10 МБ)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'pdf',
          'doc',
          'docx',
          'txt',
        ],
      );

      if (result != null) {
        final files = result.files.map((file) => File(file.path!)).toList();
        setState(() {
          _attachments.addAll(files);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора файлов: $e');
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  IconData _getFileIcon(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.attach_file;
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(authServiceProvider).currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('Пользователь не авторизован');
        return;
      }

      final ticketId = await _supportService.createTicket(
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'Пользователь',
        userEmail: currentUser.email ?? '',
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        attachments: _attachments.isNotEmpty ? _attachments : null,
      );

      if (ticketId != null) {
        Navigator.pop(context, true);
        _showSuccessSnackBar('Тикет поддержки создан успешно');
      } else {
        _showErrorSnackBar('Ошибка создания тикета поддержки');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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
