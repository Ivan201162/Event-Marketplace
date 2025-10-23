import 'package:flutter/material.dart';

import '../models/app_user.dart';

/// Dialog for editing profile fields
class ProfileEditDialog extends StatefulWidget {
  final String field;
  final String currentValue;
  final void Function(String) onSave;

  const ProfileEditDialog({
    super.key,
    required this.field,
    required this.currentValue,
    required this.onSave,
  });

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late TextEditingController _controller;
  UserType? _selectedUserType;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);

    // Parse user type if field is 'type'
    if (widget.field == 'type') {
      _selectedUserType = UserType.values.firstWhere(
        (type) => type.name == widget.currentValue,
        orElse: () => UserType.individual,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getFieldTitle()),
      content: _buildContent(),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена')),
        ElevatedButton(onPressed: _save, child: const Text('Сохранить')),
      ],
    );
  }

  String _getFieldTitle() {
    switch (widget.field) {
      case 'name':
        return 'Изменить имя';
      case 'city':
        return 'Изменить город';
      case 'status':
        return 'Изменить статус';
      case 'type':
        return 'Изменить тип';
      default:
        return 'Изменить поле';
    }
  }

  Widget _buildContent() {
    if (widget.field == 'type') {
      return _buildUserTypeSelector();
    }

    return TextField(
      controller: _controller,
      decoration: InputDecoration(
          hintText: _getFieldHint(), border: const OutlineInputBorder()),
      maxLines: widget.field == 'status' ? 3 : 1,
    );
  }

  Widget _buildUserTypeSelector() {
    return SegmentedButton<UserType>(
      segments: UserType.values.map((type) {
        return ButtonSegment<UserType>(
          value: type,
          label: Text(type.displayName),
          icon: Icon(_getUserTypeIcon(type)),
        );
      }).toList(),
      selected: _selectedUserType != null ? {_selectedUserType!} : <UserType>{},
      onSelectionChanged: (Set<UserType> selection) {
        setState(() {
          _selectedUserType = selection.isNotEmpty ? selection.first : null;
        });
      },
    );
  }

  IconData _getUserTypeIcon(UserType type) {
    switch (type) {
      case UserType.physical:
        return Icons.person;
      case UserType.selfEmployed:
        return Icons.work;
      case UserType.individual:
        return Icons.business;
      case UserType.studio:
        return Icons.movie;
    }
  }

  String _getFieldHint() {
    switch (widget.field) {
      case 'name':
        return 'Введите ваше имя';
      case 'city':
        return 'Введите ваш город';
      case 'status':
        return 'Расскажите о себе';
      default:
        return 'Введите значение';
    }
  }

  void _save() {
    String newValue;

    if (widget.field == 'type') {
      newValue = _selectedUserType?.name ?? widget.currentValue;
    } else {
      newValue = _controller.text.trim();
    }

    if (newValue.isNotEmpty && newValue != widget.currentValue) {
      widget.onSave(newValue);
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop();
    }
  }
}
