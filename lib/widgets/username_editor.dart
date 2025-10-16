import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/transliterate.dart';

/// Виджет для редактирования username с транслитерацией
class UsernameEditor extends ConsumerStatefulWidget {
  const UsernameEditor({
    super.key,
    required this.initialUsername,
    required this.onChanged,
    this.enabled = true,
  });

  final String initialUsername;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  ConsumerState<UsernameEditor> createState() => _UsernameEditorState();
}

class _UsernameEditorState extends ConsumerState<UsernameEditor> {
  late TextEditingController _controller;
  String _currentUsername = '';
  bool _isValid = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
    _currentUsername = widget.initialUsername;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateUsername(String username) {
    setState(() {
      _currentUsername = username;

      if (username.isEmpty) {
        _isValid = false;
        _errorText = 'Username не может быть пустым';
      } else if (username.length < 3) {
        _isValid = false;
        _errorText = 'Username должен содержать минимум 3 символа';
      } else if (username.length > 20) {
        _isValid = false;
        _errorText = 'Username не может быть длиннее 20 символов';
      } else if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
        _isValid = false;
        _errorText =
            'Username может содержать только строчные буквы, цифры и подчеркивания';
      } else {
        _isValid = true;
        _errorText = null;
      }
    });

    if (_isValid) {
      widget.onChanged(username);
    }
  }

  void _generateFromName(String fullName) {
    if (fullName.isNotEmpty) {
      final generatedUsername =
          TransliterateUtils.transliterateNameToUsername(fullName);
      _controller.text = generatedUsername;
      _validateUsername(generatedUsername);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Username',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  onChanged: _validateUsername,
                  decoration: InputDecoration(
                    hintText: 'username',
                    prefixText: '@',
                    errorText: _errorText,
                    border: const OutlineInputBorder(),
                    helperText: 'Только строчные буквы, цифры и подчеркивания',
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 8),
              if (widget.enabled)
                IconButton(
                  onPressed: _showNameInputDialog,
                  icon: const Icon(Icons.auto_fix_high),
                  tooltip: 'Сгенерировать из имени',
                ),
            ],
          ),
          if (widget.enabled) ...[
            const SizedBox(height: 8),
            Text(
              '💡 Совет: Нажмите на кнопку генерации, чтобы создать username из вашего имени',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      );

  void _showNameInputDialog() {
    final nameController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Генерация username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Введите ваше полное имя для генерации username:'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Полное имя',
                hintText: 'Иван Иванов',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                _generateFromName(name);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Сгенерировать'),
          ),
        ],
      ),
    );
  }
}
