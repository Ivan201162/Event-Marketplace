import 'package:flutter/material.dart';
import '../../models/user_profile_enhanced.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_overlay.dart';

/// Экран настроек конфиденциальности
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _userProfileService = UserProfileService();

  UserProfileEnhanced? _currentProfile;
  bool _isLoading = false;
  bool _isSaving = false;

  // Настройки конфиденциальности
  MessagePermission _whoCanMessage = MessagePermission.registered;
  CommentPermission _whoCanComment = CommentPermission.registered;
  MentionPermission _whoCanMention = MentionPermission.registered;
  bool _hideFromSearch = false;
  List<String> _hideStoriesFrom = [];
  bool _closeFriendsOnly = false;
  bool _archiveStories = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Загрузить профиль пользователя
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _userProfileService.getCurrentUserProfile();
      if (profile != null) {
        setState(() {
          _currentProfile = profile;
          final settings = profile.privacySettings;
          if (settings != null) {
            _whoCanMessage = settings.whoCanMessage;
            _whoCanComment = settings.whoCanComment;
            _whoCanMention = settings.whoCanMention;
            _hideFromSearch = settings.hideFromSearch;
            _hideStoriesFrom = List.from(settings.hideStoriesFrom);
            _closeFriendsOnly = settings.closeFriendsOnly;
            _archiveStories = settings.archiveStories;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки профиля: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Сохранить настройки
  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final userId = _currentProfile?.id;
      if (userId == null) {
        _showErrorSnackBar('Пользователь не авторизован');
        return;
      }

      final settings = PrivacySettings(
        whoCanMessage: _whoCanMessage,
        whoCanComment: _whoCanComment,
        whoCanMention: _whoCanMention,
        hideFromSearch: _hideFromSearch,
        hideStoriesFrom: _hideStoriesFrom,
        closeFriendsOnly: _closeFriendsOnly,
        archiveStories: _archiveStories,
      );

      await _userProfileService.updatePrivacySettings(userId, settings);

      _showSuccessSnackBar('Настройки конфиденциальности сохранены');
    } catch (e) {
      _showErrorSnackBar('Ошибка сохранения: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Управление скрытием историй
  Future<void> _manageHiddenStories() async {
    // TODO: Реализовать управление скрытием историй
    _showInfoSnackBar('Управление скрытием историй будет реализовано');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Конфиденциальность',
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Сохранить'),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Кто может писать сообщения
            _buildMessagePermissionsSection(),
            const SizedBox(height: 16),

            // Кто может комментировать
            _buildCommentPermissionsSection(),
            const SizedBox(height: 16),

            // Кто может упоминать
            _buildMentionPermissionsSection(),
            const SizedBox(height: 16),

            // Поиск
            _buildSearchSection(),
            const SizedBox(height: 16),

            // Истории
            _buildStoriesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagePermissionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Кто может писать сообщения',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...MessagePermission.values
                .map((permission) => RadioListTile<MessagePermission>(
                      title: Text(_getMessagePermissionTitle(permission)),
                      subtitle:
                          Text(_getMessagePermissionDescription(permission)),
                      value: permission,
                      groupValue: _whoCanMessage,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _whoCanMessage = value);
                        }
                      },
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentPermissionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Кто может комментировать',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...CommentPermission.values
                .map((permission) => RadioListTile<CommentPermission>(
                      title: Text(_getCommentPermissionTitle(permission)),
                      subtitle:
                          Text(_getCommentPermissionDescription(permission)),
                      value: permission,
                      groupValue: _whoCanComment,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _whoCanComment = value);
                        }
                      },
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildMentionPermissionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Кто может упоминать',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...MentionPermission.values
                .map((permission) => RadioListTile<MentionPermission>(
                      title: Text(_getMentionPermissionTitle(permission)),
                      subtitle:
                          Text(_getMentionPermissionDescription(permission)),
                      value: permission,
                      groupValue: _whoCanMention,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _whoCanMention = value);
                        }
                      },
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Поиск',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Скрыть от поиска'),
              subtitle: const Text(
                  'Ваш профиль не будет отображаться в результатах поиска'),
              value: _hideFromSearch,
              onChanged: (value) {
                setState(() => _hideFromSearch = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Истории',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Только для близких друзей'),
              subtitle:
                  const Text('Истории будут видны только близким друзьям'),
              value: _closeFriendsOnly,
              onChanged: (value) {
                setState(() => _closeFriendsOnly = value);
              },
            ),
            SwitchListTile(
              title: const Text('Архивировать истории'),
              subtitle: const Text('Автоматически архивировать истории'),
              value: _archiveStories,
              onChanged: (value) {
                setState(() => _archiveStories = value);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off),
              title: const Text('Скрыть истории от пользователей'),
              subtitle:
                  Text('Скрыто от ${_hideStoriesFrom.length} пользователей'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _manageHiddenStories,
            ),
          ],
        ),
      ),
    );
  }

  String _getMessagePermissionTitle(MessagePermission permission) {
    switch (permission) {
      case MessagePermission.all:
        return 'Все пользователи';
      case MessagePermission.registered:
        return 'Только зарегистрированные';
      case MessagePermission.followers:
        return 'Только подписчики';
      case MessagePermission.none:
        return 'Никто';
    }
  }

  String _getMessagePermissionDescription(MessagePermission permission) {
    switch (permission) {
      case MessagePermission.all:
        return 'Любой пользователь может написать вам сообщение';
      case MessagePermission.registered:
        return 'Только зарегистрированные пользователи могут писать сообщения';
      case MessagePermission.followers:
        return 'Только ваши подписчики могут писать сообщения';
      case MessagePermission.none:
        return 'Никто не может писать вам сообщения';
    }
  }

  String _getCommentPermissionTitle(CommentPermission permission) {
    switch (permission) {
      case CommentPermission.all:
        return 'Все пользователи';
      case CommentPermission.registered:
        return 'Только зарегистрированные';
      case CommentPermission.followers:
        return 'Только подписчики';
      case CommentPermission.none:
        return 'Никто';
    }
  }

  String _getCommentPermissionDescription(CommentPermission permission) {
    switch (permission) {
      case CommentPermission.all:
        return 'Любой пользователь может комментировать ваши посты';
      case CommentPermission.registered:
        return 'Только зарегистрированные пользователи могут комментировать';
      case CommentPermission.followers:
        return 'Только ваши подписчики могут комментировать';
      case CommentPermission.none:
        return 'Никто не может комментировать ваши посты';
    }
  }

  String _getMentionPermissionTitle(MentionPermission permission) {
    switch (permission) {
      case MentionPermission.all:
        return 'Все пользователи';
      case MentionPermission.registered:
        return 'Только зарегистрированные';
      case MentionPermission.followers:
        return 'Только подписчики';
      case MentionPermission.none:
        return 'Никто';
    }
  }

  String _getMentionPermissionDescription(MentionPermission permission) {
    switch (permission) {
      case MentionPermission.all:
        return 'Любой пользователь может упоминать вас';
      case MentionPermission.registered:
        return 'Только зарегистрированные пользователи могут упоминать';
      case MentionPermission.followers:
        return 'Только ваши подписчики могут упоминать';
      case MentionPermission.none:
        return 'Никто не может упоминать вас';
    }
  }
}
