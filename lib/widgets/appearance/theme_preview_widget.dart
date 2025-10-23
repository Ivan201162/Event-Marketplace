import 'package:flutter/material.dart';
import '../../models/user_profile_enhanced.dart';

/// Виджет предпросмотра темы
class ThemePreviewWidget extends StatefulWidget {
  const ThemePreviewWidget({
    super.key,
    required this.selectedTheme,
    required this.selectedFontSize,
    required this.onThemeSelected,
    required this.onFontSizeSelected,
  });

  final AppTheme selectedTheme;
  final FontSize selectedFontSize;
  final Function(AppTheme) onThemeSelected;
  final Function(FontSize) onFontSizeSelected;

  @override
  State<ThemePreviewWidget> createState() => _ThemePreviewWidgetState();
}

class _ThemePreviewWidgetState extends State<ThemePreviewWidget> {
  late AppTheme _currentTheme;
  late FontSize _currentFontSize;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.selectedTheme;
    _currentFontSize = widget.selectedFontSize;
  }

  /// Применить настройки
  void _applySettings() {
    widget.onThemeSelected(_currentTheme);
    widget.onFontSizeSelected(_currentFontSize);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Предпросмотр темы'),
        actions: [
          TextButton(
            onPressed: _applySettings,
            child: const Text('Применить'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Настройки
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Выбор темы
                Row(
                  children: [
                    const Text('Тема: '),
                    Expanded(
                      child: SegmentedButton<AppTheme>(
                        segments: AppTheme.values.map((theme) => ButtonSegment<AppTheme>(
                          value: theme,
                          label: Text(_getThemeTitle(theme)),
                        )).toList(),
                        selected: {_currentTheme},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _currentTheme = selection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Выбор размера шрифта
                Row(
                  children: [
                    const Text('Шрифт: '),
                    Expanded(
                      child: SegmentedButton<FontSize>(
                        segments: FontSize.values.map((fontSize) => ButtonSegment<FontSize>(
                          value: fontSize,
                          label: Text(_getFontSizeTitle(fontSize)),
                        )).toList(),
                        selected: {_currentFontSize},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _currentFontSize = selection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Предпросмотр
          Expanded(
            child: _buildPreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _getThemeColor(_currentTheme),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              'Предпросмотр темы',
              style: TextStyle(
                fontSize: _getFontSize(_currentFontSize) * 1.5,
                fontWeight: FontWeight.bold,
                color: _getTextColor(_currentTheme),
              ),
            ),
            const SizedBox(height: 16),

            // Карточка
            Card(
              color: _getCardColor(_currentTheme),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Пример карточки',
                      style: TextStyle(
                        fontSize: _getFontSize(_currentFontSize) * 1.2,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(_currentTheme),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Это пример текста в выбранной теме. '
                      'Здесь можно увидеть, как будет выглядеть контент '
                      'с выбранными настройками.',
                      style: TextStyle(
                        fontSize: _getFontSize(_currentFontSize),
                        color: _getTextColor(_currentTheme),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Кнопки
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: Text(
                    'Основная кнопка',
                    style: TextStyle(fontSize: _getFontSize(_currentFontSize)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {},
                  child: Text(
                    'Вторичная кнопка',
                    style: TextStyle(fontSize: _getFontSize(_currentFontSize)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Список
            Text(
              'Пример списка',
              style: TextStyle(
                fontSize: _getFontSize(_currentFontSize) * 1.1,
                fontWeight: FontWeight.bold,
                color: _getTextColor(_currentTheme),
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(3, (index) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _getAccentColor(_currentTheme),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getFontSize(_currentFontSize),
                  ),
                ),
              ),
              title: Text(
                'Элемент списка ${index + 1}',
                style: TextStyle(
                  fontSize: _getFontSize(_currentFontSize),
                  color: _getTextColor(_currentTheme),
                ),
              ),
              subtitle: Text(
                'Описание элемента ${index + 1}',
                style: TextStyle(
                  fontSize: _getFontSize(_currentFontSize) * 0.9,
                  color: _getTextColor(_currentTheme).withOpacity(0.7),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _getThemeColor(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return Colors.grey[100]!;
      case AppTheme.dark:
        return Colors.grey[900]!;
      case AppTheme.system:
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]!
            : Colors.grey[100]!;
    }
  }

  Color _getTextColor(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return Colors.black87;
      case AppTheme.dark:
        return Colors.white;
      case AppTheme.system:
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87;
    }
  }

  Color _getCardColor(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return Colors.white;
      case AppTheme.dark:
        return Colors.grey[800]!;
      case AppTheme.system:
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]!
            : Colors.white;
    }
  }

  Color _getAccentColor(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return Colors.blue;
      case AppTheme.dark:
        return Colors.blue[300]!;
      case AppTheme.system:
        return Colors.blue;
    }
  }

  double _getFontSize(FontSize fontSize) {
    switch (fontSize) {
      case FontSize.small:
        return 12.0;
      case FontSize.medium:
        return 14.0;
      case FontSize.large:
        return 16.0;
      case FontSize.extraLarge:
        return 18.0;
    }
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

  String _getFontSizeTitle(FontSize fontSize) {
    switch (fontSize) {
      case FontSize.small:
        return 'Малый';
      case FontSize.medium:
        return 'Средний';
      case FontSize.large:
        return 'Большой';
      case FontSize.extraLarge:
        return 'Очень большой';
    }
  }
}
