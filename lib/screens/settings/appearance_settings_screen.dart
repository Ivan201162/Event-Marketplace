import 'package:flutter/material.dart';
import '../../models/user_profile_enhanced.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/appearance/theme_preview_widget.dart';

/// Экран настроек внешнего вида
class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  final _userProfileService = UserProfileService();

  UserProfileEnhanced? _currentProfile;
  bool _isLoading = false;
  bool _isSaving = false;

  // Настройки внешнего вида
  AppTheme _selectedTheme = AppTheme.system;
  FontSize _selectedFontSize = FontSize.medium;
  TabPosition _selectedTabPosition = TabPosition.bottom;
  bool _animationsEnabled = true;
  String? _customBackground;

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
          final settings = profile.appearanceSettings;
          if (settings != null) {
            _selectedTheme = settings.theme;
            _selectedFontSize = settings.fontSize;
            _selectedTabPosition = settings.tabPosition;
            _animationsEnabled = settings.animationsEnabled;
            _customBackground = settings.customBackground;
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

      final settings = AppearanceSettings(
        theme: _selectedTheme,
        fontSize: _selectedFontSize,
        tabPosition: _selectedTabPosition,
        animationsEnabled: _animationsEnabled,
        customBackground: _customBackground,
      );

      await _userProfileService.updateAppearanceSettings(userId, settings);
      
      _showSuccessSnackBar('Настройки сохранены');
    } catch (e) {
      _showErrorSnackBar('Ошибка сохранения: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Показать предпросмотр темы
  Future<void> _showThemePreview() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ThemePreviewWidget(
          selectedTheme: _selectedTheme,
          selectedFontSize: _selectedFontSize,
          onThemeSelected: (theme) {
            setState(() => _selectedTheme = theme);
          },
          onFontSizeSelected: (fontSize) {
            setState(() => _selectedFontSize = fontSize);
          },
        ),
      ),
    );
  }

  /// Выбрать кастомный фон
  Future<void> _selectCustomBackground() async {
    // TODO: Реализовать выбор кастомного фона
    _showInfoSnackBar('Выбор кастомного фона будет реализован');
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
        title: 'Внешний вид',
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
            // Тема
            _buildThemeSection(),
            const SizedBox(height: 16),

            // Размер шрифта
            _buildFontSizeSection(),
            const SizedBox(height: 16),

            // Позиция вкладок
            _buildTabPositionSection(),
            const SizedBox(height: 16),

            // Анимации
            _buildAnimationsSection(),
            const SizedBox(height: 16),

            // Кастомный фон
            _buildCustomBackgroundSection(),
            const SizedBox(height: 16),

            // Предпросмотр
            _buildPreviewSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Тема',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ...AppTheme.values.map((theme) => RadioListTile<AppTheme>(
              title: Text(_getThemeTitle(theme)),
              subtitle: Text(_getThemeDescription(theme)),
              value: theme,
              groupValue: _selectedTheme,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTheme = value);
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Размер шрифта',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ...FontSize.values.map((fontSize) => RadioListTile<FontSize>(
              title: Text(_getFontSizeTitle(fontSize)),
              subtitle: Text(_getFontSizeDescription(fontSize)),
              value: fontSize,
              groupValue: _selectedFontSize,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFontSize = value);
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPositionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Расположение вкладок',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ...TabPosition.values.map((position) => RadioListTile<TabPosition>(
              title: Text(_getTabPositionTitle(position)),
              subtitle: Text(_getTabPositionDescription(position)),
              value: position,
              groupValue: _selectedTabPosition,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTabPosition = value);
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Анимации',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Включить анимации'),
              subtitle: const Text('Плавные переходы и анимации в приложении'),
              value: _animationsEnabled,
              onChanged: (value) {
                setState(() => _animationsEnabled = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBackgroundSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Кастомный фон',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Выбрать фон'),
              subtitle: Text(_customBackground ?? 'Фон не выбран'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selectCustomBackground,
            ),
            
            if (_customBackground != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _customBackground = null);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Удалить фон'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Предпросмотр',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showThemePreview,
                icon: const Icon(Icons.preview),
                label: const Text('Предпросмотр темы'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeTitle(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Светлая';
      case AppTheme.dark:
        return 'Тёмная';
      case AppTheme.system:
        return 'Системная';
    }
  }

  String _getThemeDescription(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Светлая тема для дневного использования';
      case AppTheme.dark:
        return 'Тёмная тема для ночного использования';
      case AppTheme.system:
        return 'Следовать системным настройкам';
    }
  }

  String _getFontSizeTitle(FontSize fontSize) {
    switch (fontSize) {
      case FontSize.small:
        return 'Маленький';
      case FontSize.medium:
        return 'Средний';
      case FontSize.large:
        return 'Большой';
      case FontSize.extraLarge:
        return 'Очень большой';
    }
  }

  String _getFontSizeDescription(FontSize fontSize) {
    switch (fontSize) {
      case FontSize.small:
        return 'Компактный текст';
      case FontSize.medium:
        return 'Стандартный размер';
      case FontSize.large:
        return 'Увеличенный текст';
      case FontSize.extraLarge:
        return 'Максимальный размер';
    }
  }

  String _getTabPositionTitle(TabPosition position) {
    switch (position) {
      case TabPosition.bottom:
        return 'Внизу';
      case TabPosition.side:
        return 'Сбоку';
    }
  }

  String _getTabPositionDescription(TabPosition position) {
    switch (position) {
      case TabPosition.bottom:
        return 'Вкладки в нижней части экрана';
      case TabPosition.side:
        return 'Вкладки в боковой панели';
    }
  }
}
