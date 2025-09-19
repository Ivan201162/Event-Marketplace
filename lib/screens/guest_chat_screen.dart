import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class GuestChatScreen extends ConsumerStatefulWidget {
  const GuestChatScreen({
    super.key,
    this.specialistId,
    this.eventId,
  });
  final String? specialistId;
  final String? eventId;

  @override
  ConsumerState<GuestChatScreen> createState() => _GuestChatScreenState();
}

class _GuestChatScreenState extends ConsumerState<GuestChatScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  // Вложения
  final List<File> _attachments = [];
  bool _showAttachmentOptions = false;
  bool _isGuestMode = true;
  String? _guestId;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Гостевой чат'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            if (_isGuestMode)
              TextButton(
                onPressed: _switchToSpecialistMode,
                child: const Text('Я специалист'),
              ),
          ],
        ),
        body: _isGuestMode ? _buildGuestMode() : _buildSpecialistMode(),
      );

  Widget _buildGuestMode() => Column(
        children: [
          // Информация о госте
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Информация о госте',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Поля ввода информации
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя *',
                    hintText: 'Введите ваше имя',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'your@email.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Телефон',
                    hintText: '+7 (999) 123-45-67',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),

          // Сообщения
          Expanded(
            child: _buildMessagesList(),
          ),

          // Поле ввода сообщения
          _buildMessageInput(),
        ],
      );

  Widget _buildSpecialistMode() => Column(
        children: [
          // Информация о специалисте
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Режим специалиста',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        'Просмотр сообщений от гостей',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _switchToGuestMode,
                  child: const Text('Режим гостя'),
                ),
              ],
            ),
          ),

          // Сообщения
          Expanded(
            child: _buildMessagesList(),
          ),

          // Поле ввода сообщения
          _buildMessageInput(),
        ],
      );

  Widget _buildMessagesList() {
    // TODO: Реализовать получение сообщений из Firestore
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Гостевой чат',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Отправьте сообщение организатору мероприятия',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() => Column(
        children: [
          // Вложения
          if (_attachments.isNotEmpty) _buildAttachmentsPreview(),

          // Поле ввода сообщения
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                // Опции вложений
                if (_showAttachmentOptions) _buildAttachmentOptions(),

                Row(
                  children: [
                    // Кнопка вложений
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showAttachmentOptions = !_showAttachmentOptions;
                        });
                      },
                      icon: Icon(
                        _showAttachmentOptions
                            ? Icons.close
                            : Icons.attach_file,
                        color: _showAttachmentOptions ? Colors.red : null,
                      ),
                    ),

                    // Поле ввода
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        decoration: InputDecoration(
                          hintText: _isGuestMode
                              ? 'Сообщение организатору...'
                              : 'Ответ гостю...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty ||
                              _attachments.isNotEmpty) {
                            _sendMessage();
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Кнопка отправки
                    FloatingActionButton.small(
                      onPressed: _canSendMessage() ? _sendMessage : null,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  bool _canSendMessage() {
    if (_isGuestMode) {
      return _nameController.text.trim().isNotEmpty &&
          (_messageController.text.trim().isNotEmpty ||
              _attachments.isNotEmpty);
    } else {
      return _messageController.text.trim().isNotEmpty ||
          _attachments.isNotEmpty;
    }
  }

  Future<void> _sendMessage() async {
    if (!_canSendMessage()) return;

    try {
      // TODO: Реализовать отправку сообщения в Firestore
      // Создать или получить chatId
      // Отправить сообщение с вложениями

      final message = _messageController.text.trim();
      final attachments = _attachments.map((file) => file.path).toList();

      // Показать уведомление об успешной отправке
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сообщение отправлено'),
          backgroundColor: Colors.green,
        ),
      );

      // Очистить поля
      _messageController.clear();
      setState(() {
        _attachments.clear();
        _showAttachmentOptions = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _switchToGuestMode() {
    setState(() {
      _isGuestMode = true;
    });
  }

  void _switchToSpecialistMode() {
    setState(() {
      _isGuestMode = false;
    });
  }

  /// Загрузка изображений
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _attachments.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  /// Загрузка видео
  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      setState(() {
        _attachments.add(File(video.path));
      });
    }
  }

  /// Загрузка аудио
  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _attachments.addAll(result.files.map((file) => File(file.path!)));
      });
    }
  }

  /// Загрузка документов
  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
    );

    if (result != null) {
      setState(() {
        _attachments.addAll(result.files.map((file) => File(file.path!)));
      });
    }
  }

  /// Удаление вложения
  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  /// Отправка в WhatsApp
  Future<void> _sendToWhatsApp() async {
    if (_attachments.isEmpty) return;

    final phoneNumber = widget
        .specialistId; // Предполагаем, что specialistId - это номер телефона
    if (phoneNumber == null) return;

    final message = _messageController.text.isNotEmpty
        ? _messageController.text
        : 'Файлы для мероприятия';
    final encodedMessage = Uri.encodeComponent(message);

    final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp не установлен')),
        );
      }
    }
  }

  /// Отправка в Telegram
  Future<void> _sendToTelegram() async {
    if (_attachments.isEmpty) return;

    final username =
        widget.specialistId; // Предполагаем, что specialistId - это username
    if (username == null) return;

    final message = _messageController.text.isNotEmpty
        ? _messageController.text
        : 'Файлы для мероприятия';
    final encodedMessage = Uri.encodeComponent(message);

    final telegramUrl = 'https://t.me/$username?text=$encodedMessage';

    if (await canLaunchUrl(Uri.parse(telegramUrl))) {
      await launchUrl(Uri.parse(telegramUrl));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telegram не установлен')),
        );
      }
    }
  }

  /// Построение превью вложений
  Widget _buildAttachmentsPreview() => Container(
        height: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _attachments.length,
          itemBuilder: (context, index) {
            final file = _attachments[index];
            return Container(
              width: 80,
              margin: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.withOpacity(0.1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getFileIcon(file.path),
                          size: 32,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          file.path.split('/').last,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeAttachment(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

  /// Построение опций вложений
  Widget _buildAttachmentOptions() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Прикрепить файлы:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),

            // Кнопки типов файлов
            Row(
              children: [
                _buildAttachmentButton(
                  icon: Icons.photo,
                  label: 'Фото',
                  onTap: _pickImages,
                ),
                const SizedBox(width: 12),
                _buildAttachmentButton(
                  icon: Icons.videocam,
                  label: 'Видео',
                  onTap: _pickVideo,
                ),
                const SizedBox(width: 12),
                _buildAttachmentButton(
                  icon: Icons.audiotrack,
                  label: 'Аудио',
                  onTap: _pickAudio,
                ),
                const SizedBox(width: 12),
                _buildAttachmentButton(
                  icon: Icons.description,
                  label: 'Документы',
                  onTap: _pickDocuments,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Кнопки мессенджеров
            if (_attachments.isNotEmpty) ...[
              Text(
                'Отправить через мессенджер:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMessengerButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: Colors.green,
                    onTap: _sendToWhatsApp,
                  ),
                  const SizedBox(width: 12),
                  _buildMessengerButton(
                    icon: Icons.telegram,
                    label: 'Telegram',
                    color: Colors.blue,
                    onTap: _sendToTelegram,
                  ),
                ],
              ),
            ],
          ],
        ),
      );

  /// Кнопка типа вложения
  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(icon, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

  /// Кнопка мессенджера
  Widget _buildMessengerButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
        ),
      );

  /// Получить иконку файла по расширению
  IconData _getFileIcon(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audiotrack;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }
}
