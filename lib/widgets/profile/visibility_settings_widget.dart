import 'package:event_marketplace_app/models/user_profile_enhanced.dart';
import 'package:flutter/material.dart';

/// Виджет настроек видимости профиля
class VisibilitySettingsWidget extends StatefulWidget {
  const VisibilitySettingsWidget({
    super.key,
    this.initialSettings,
  });

  final ProfileVisibilitySettings? initialSettings;

  @override
  State<VisibilitySettingsWidget> createState() =>
      _VisibilitySettingsWidgetState();
}

class _VisibilitySettingsWidgetState extends State<VisibilitySettingsWidget> {
  late ProfileVisibilitySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings ?? const ProfileVisibilitySettings();
  }

  void _saveSettings() {
    Navigator.of(context).pop(_settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки видимости'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Общая видимость профиля
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Видимость профиля',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Кто может видеть ваш профиль',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ...ProfileVisibility.values
                      .map((visibility) => RadioListTile<ProfileVisibility>(
                            title: Text(_getVisibilityTitle(visibility)),
                            subtitle:
                                Text(_getVisibilityDescription(visibility)),
                            value: visibility,
                            groupValue: _settings.profileVisibility,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _settings = ProfileVisibilitySettings(
                                    profileVisibility: value,
                                    showPhone: _settings.showPhone,
                                    showEmail: _settings.showEmail,
                                    showCity: _settings.showCity,
                                    showActivity: _settings.showActivity,
                                    showFollowers: _settings.showFollowers,
                                    showFollowing: _settings.showFollowing,
                                  );
                                });
                              }
                            },
                          ),),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Детальные настройки
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Детальные настройки',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Показывать телефон'),
                    subtitle: const Text('Отображать номер телефона в профиле'),
                    value: _settings.showPhone,
                    onChanged: (value) {
                      setState(() {
                        _settings = ProfileVisibilitySettings(
                          profileVisibility: _settings.profileVisibility,
                          showPhone: value,
                          showEmail: _settings.showEmail,
                          showCity: _settings.showCity,
                          showActivity: _settings.showActivity,
                          showFollowers: _settings.showFollowers,
                          showFollowing: _settings.showFollowing,
                        );
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Показывать email'),
                    subtitle: const Text('Отображать email в профиле'),
                    value: _settings.showEmail,
                    onChanged: (value) {
                      setState(() {
                        _settings = ProfileVisibilitySettings(
                          profileVisibility: _settings.profileVisibility,
                          showPhone: _settings.showPhone,
                          showEmail: value,
                          showCity: _settings.showCity,
                          showActivity: _settings.showActivity,
                          showFollowers: _settings.showFollowers,
                          showFollowing: _settings.showFollowing,
                        );
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Показывать город'),
                    subtitle: const Text('Отображать город в профиле'),
                    value: _settings.showCity,
                    onChanged: (value) {
                      setState(() {
                        _settings = ProfileVisibilitySettings(
                          profileVisibility: _settings.profileVisibility,
                          showPhone: _settings.showPhone,
                          showEmail: _settings.showEmail,
                          showCity: value,
                          showActivity: _settings.showActivity,
                          showFollowers: _settings.showFollowers,
                          showFollowing: _settings.showFollowing,
                        );
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Показывать активность'),
                    subtitle:
                        const Text('Отображать время последней активности'),
                    value: _settings.showActivity,
                    onChanged: (value) {
                      setState(() {
                        _settings = ProfileVisibilitySettings(
                          profileVisibility: _settings.profileVisibility,
                          showPhone: _settings.showPhone,
                          showEmail: _settings.showEmail,
                          showCity: _settings.showCity,
                          showActivity: value,
                          showFollowers: _settings.showFollowers,
                          showFollowing: _settings.showFollowing,
                        );
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Показывать подписчиков'),
                    subtitle: const Text('Отображать количество подписчиков'),
                    value: _settings.showFollowers,
                    onChanged: (value) {
                      setState(() {
                        _settings = ProfileVisibilitySettings(
                          profileVisibility: _settings.profileVisibility,
                          showPhone: _settings.showPhone,
                          showEmail: _settings.showEmail,
                          showCity: _settings.showCity,
                          showActivity: _settings.showActivity,
                          showFollowers: value,
                          showFollowing: _settings.showFollowing,
                        );
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Показывать подписки'),
                    subtitle: const Text('Отображать количество подписок'),
                    value: _settings.showFollowing,
                    onChanged: (value) {
                      setState(() {
                        _settings = ProfileVisibilitySettings(
                          profileVisibility: _settings.profileVisibility,
                          showPhone: _settings.showPhone,
                          showEmail: _settings.showEmail,
                          showCity: _settings.showCity,
                          showActivity: _settings.showActivity,
                          showFollowers: _settings.showFollowers,
                          showFollowing: value,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Информационная карточка
          Card(
            color: Colors.blue[50],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Настройки видимости помогают контролировать, какая информация о вас доступна другим пользователям.',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getVisibilityTitle(ProfileVisibility visibility) {
    switch (visibility) {
      case ProfileVisibility.all:
        return 'Все пользователи';
      case ProfileVisibility.registered:
        return 'Только зарегистрированные';
      case ProfileVisibility.followers:
        return 'Только подписчики';
      case ProfileVisibility.private:
        return 'Приватный';
    }
  }

  String _getVisibilityDescription(ProfileVisibility visibility) {
    switch (visibility) {
      case ProfileVisibility.all:
        return 'Ваш профиль виден всем пользователям, включая гостей';
      case ProfileVisibility.registered:
        return 'Профиль виден только зарегистрированным пользователям';
      case ProfileVisibility.followers:
        return 'Профиль виден только вашим подписчикам';
      case ProfileVisibility.private:
        return 'Профиль скрыт от всех пользователей';
    }
  }
}
