import 'package:flutter/material.dart';
import '../../models/user_profile_enhanced.dart';

/// Редактор социальных ссылок
class SocialLinksEditor extends StatefulWidget {
  const SocialLinksEditor({
    super.key,
    required this.initialLinks,
  });

  final List<SocialLink> initialLinks;

  @override
  State<SocialLinksEditor> createState() => _SocialLinksEditorState();
}

class _SocialLinksEditorState extends State<SocialLinksEditor> {
  late List<SocialLink> _socialLinks;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _socialLinks = List.from(widget.initialLinks);
  }

  /// Добавить новую социальную ссылку
  void _addSocialLink() {
    showDialog(
      context: context,
      builder: (context) => _SocialLinkDialog(
        onSave: (link) {
          setState(() {
            _socialLinks.add(link);
          });
        },
      ),
    );
  }

  /// Редактировать социальную ссылку
  void _editSocialLink(int index) {
    showDialog(
      context: context,
      builder: (context) => _SocialLinkDialog(
        initialLink: _socialLinks[index],
        onSave: (link) {
          setState(() {
            _socialLinks[index] = link;
          });
        },
      ),
    );
  }

  /// Удалить социальную ссылку
  void _removeSocialLink(int index) {
    setState(() {
      _socialLinks.removeAt(index);
    });
  }

  /// Сохранить изменения
  void _saveChanges() {
    Navigator.of(context).pop(_socialLinks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Социальные сети'),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Кнопка добавления
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addSocialLink,
                icon: const Icon(Icons.add),
                label: const Text('Добавить ссылку'),
              ),
            ),
          ),

          // Список ссылок
          Expanded(
            child: _socialLinks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.link_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Социальные ссылки не добавлены',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Добавьте ссылки на ваши социальные сети',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _socialLinks.length,
                    itemBuilder: (context, index) {
                      final link = _socialLinks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getPlatformColor(link.platform),
                            child: Icon(
                              _getPlatformIcon(link.platform),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(link.platform),
                          subtitle: Text(link.url),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _editSocialLink(index),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                onPressed: () => _removeSocialLink(index),
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'telegram':
        return const Color(0xFF0088CC);
      case 'vk':
        return const Color(0xFF4C75A3);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'tiktok':
        return const Color(0xFF000000);
      default:
        return Colors.grey;
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'telegram':
        return Icons.telegram;
      case 'vk':
        return Icons.group;
      case 'youtube':
        return Icons.play_circle;
      case 'twitter':
        return Icons.alternate_email;
      case 'facebook':
        return Icons.facebook;
      case 'tiktok':
        return Icons.music_note;
      default:
        return Icons.link;
    }
  }
}

/// Диалог для добавления/редактирования социальной ссылки
class _SocialLinkDialog extends StatefulWidget {
  const _SocialLinkDialog({
    this.initialLink,
    required this.onSave,
  });

  final SocialLink? initialLink;
  final Function(SocialLink) onSave;

  @override
  State<_SocialLinkDialog> createState() => _SocialLinkDialogState();
}

class _SocialLinkDialogState extends State<_SocialLinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _platformController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialLink != null) {
      _platformController.text = widget.initialLink!.platform;
      _urlController.text = widget.initialLink!.url;
      _isVisible = widget.initialLink!.isVisible;
    }
  }

  @override
  void dispose() {
    _platformController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final link = SocialLink(
        platform: _platformController.text.trim(),
        url: _urlController.text.trim(),
        isVisible: _isVisible,
      );
      widget.onSave(link);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialLink == null ? 'Добавить ссылку' : 'Редактировать ссылку'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _platformController,
              decoration: const InputDecoration(
                labelText: 'Платформа',
                hintText: 'Instagram, Telegram, VK...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название платформы';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Ссылка',
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите ссылку';
                }
                if (!Uri.tryParse(value.trim())?.hasAbsolutePath ?? true) {
                  return 'Введите корректную ссылку';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Видимость'),
              subtitle: const Text('Показывать ссылку в профиле'),
              value: _isVisible,
              onChanged: (value) {
                setState(() {
                  _isVisible = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
