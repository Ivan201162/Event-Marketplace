import 'package:flutter/material.dart';

/// Виджет для выбора типа вложения
class AttachmentPicker extends StatelessWidget {
  const AttachmentPicker({
    super.key,
    required this.onImageSelected,
    required this.onVideoSelected,
    required this.onFileSelected,
    required this.onAudioSelected,
  });
  final VoidCallback onImageSelected;
  final VoidCallback onVideoSelected;
  final VoidCallback onFileSelected;
  final VoidCallback onAudioSelected;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Выберите тип вложения',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    context,
                    icon: Icons.photo,
                    label: 'Фото',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      onImageSelected();
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: Icons.videocam,
                    label: 'Видео',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      onVideoSelected();
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: Icons.attach_file,
                    label: 'Файл',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      onFileSelected();
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: Icons.mic,
                    label: 'Аудио',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      onAudioSelected();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    context,
                    icon: Icons.location_on,
                    label: 'Местоположение',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _showLocationPicker(context);
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: Icons.contact_phone,
                    label: 'Контакты',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      _showContactPicker(context);
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Событие',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(context);
                      _showEventPicker(context);
                    },
                  ),
                  _buildAttachmentOption(
                    context,
                    icon: Icons.poll,
                    label: 'Опрос',
                    color: Colors.pink,
                    onTap: () {
                      Navigator.pop(context);
                      _showPollCreator(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена')),
            ],
          ),
        ),
      );

  Widget _buildAttachmentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  void _showLocationPicker(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отправить местоположение'),
        content: const Text(
            'Функция отправки местоположения будет добавлена в следующих версиях.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  void _showContactPicker(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отправить контакт'),
        content: const Text(
            'Функция отправки контактов будет добавлена в следующих версиях.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  void _showEventPicker(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отправить событие'),
        content: const Text(
            'Функция отправки событий будет добавлена в следующих версиях.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  void _showPollCreator(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать опрос'),
        content: const Text(
            'Функция создания опросов будет добавлена в следующих версиях.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }
}
