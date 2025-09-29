import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive_utils.dart';
import '../providers/security_provider.dart';
import '../widgets/responsive_layout.dart';

/// Виджет для отображения настроек безопасности
class SecuritySettingsWidget extends ConsumerWidget {
  const SecuritySettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(securityProvider);
    final securityStats = ref.watch(securityStatsProvider);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: Color(securityState.statusColor),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: ResponsiveText(
                  'Настройки безопасности',
                  isTitle: true,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(securityProvider.notifier).refresh(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Статус шифрования
          _buildStatusRow(
            'Шифрование данных',
            securityState.securityStatus,
            Color(securityState.statusColor),
          ),

          // Время последнего обновления
          if (securityState.lastUpdate != null)
            _buildStatusRow(
              'Последнее обновление',
              _formatDateTime(securityState.lastUpdate!),
              Colors.grey[600]!,
            ),

          // Количество зашифрованных элементов
          securityStats.when(
            data: (stats) => _buildStatusRow(
              'Зашифрованных элементов',
              '${stats.encryptedItemsCount}',
              Colors.grey[600]!,
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Ошибка: $error'),
          ),

          const SizedBox(height: 16),

          // Кнопки действий
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: securityState.isLoading
                      ? null
                      : () => _showEncryptionDialog(context, ref),
                  icon: Icon(
                    securityState.isEncryptionEnabled
                        ? Icons.lock_open
                        : Icons.lock,
                  ),
                  label: Text(
                    securityState.isEncryptionEnabled
                        ? 'Отключить шифрование'
                        : 'Включить шифрование',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: securityState.isEncryptionEnabled
                        ? Colors.red
                        : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: securityState.isLoading ||
                          !securityState.isEncryptionEnabled
                      ? null
                      : () => _showUpdateKeyDialog(context, ref),
                  icon: const Icon(Icons.key),
                  label: const Text('Обновить ключ'),
                ),
              ),
            ],
          ),

          // Ошибки
          if (securityState.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResponsiveText(
                      securityState.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(
              label,
              isSubtitle: true,
            ),
            ResponsiveText(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч. назад';
    } else {
      return '${difference.inDays} дн. назад';
    }
  }

  void _showEncryptionDialog(BuildContext context, WidgetRef ref) {
    final securityState = ref.read(securityProvider);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          securityState.isEncryptionEnabled
              ? 'Отключить шифрование'
              : 'Включить шифрование',
        ),
        content: Text(
          securityState.isEncryptionEnabled
              ? 'Вы уверены, что хотите отключить шифрование? Это может снизить безопасность ваших данных.'
              : 'Включение шифрования повысит безопасность ваших данных. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (securityState.isEncryptionEnabled) {
                ref.read(securityProvider.notifier).disableEncryption();
              } else {
                ref.read(securityProvider.notifier).enableEncryption();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  securityState.isEncryptionEnabled ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(
              securityState.isEncryptionEnabled ? 'Отключить' : 'Включить',
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateKeyDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обновить ключ шифрования'),
        content: const Text(
          'Обновление ключа шифрования перешифрует все ваши данные. Это может занять некоторое время.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(securityProvider.notifier).updateEncryptionKey();
            },
            child: const Text('Обновить'),
          ),
        ],
      ),
    );
  }
}

/// Виджет для валидации пароля
class PasswordValidationWidget extends ConsumerWidget {
  const PasswordValidationWidget({
    super.key,
    this.label,
    this.hint,
    this.onChanged,
    this.validator,
  });
  final String? label;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordState = ref.watch(passwordValidationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Поле ввода пароля
        TextFormField(
          decoration: InputDecoration(
            labelText: label ?? 'Пароль',
            hintText: hint ?? 'Введите пароль',
            suffixIcon: IconButton(
              icon: Icon(
                passwordState.isVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () => ref
                  .read(passwordValidationProvider.notifier)
                  .toggleVisibility(),
            ),
            border: const OutlineInputBorder(),
          ),
          obscureText: !passwordState.isVisible,
          onChanged: (value) {
            ref.read(passwordValidationProvider.notifier).updatePassword(value);
            onChanged?.call(value);
          },
          validator: validator,
        ),

        // Индикатор силы пароля
        if (passwordState.password.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildStrengthIndicator(passwordState),
        ],

        // Ошибки валидации
        if (passwordState.validation != null &&
            passwordState.validation!.errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...passwordState.validation!.errors.map(
            (error) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStrengthIndicator(PasswordValidationState state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: state.strengthProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(state.strengthColor)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                state.strengthDescription,
                style: TextStyle(
                  color: Color(state.strengthColor),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Сила пароля: ${state.validation!.strength.score}/5',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      );
}

/// Виджет для отображения статистики безопасности
class SecurityStatsWidget extends ConsumerWidget {
  const SecurityStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityStats = ref.watch(securityStatsProvider);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics),
              SizedBox(width: 12),
              ResponsiveText(
                'Статистика безопасности',
                isTitle: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          securityStats.when(
            data: (stats) => Column(
              children: [
                _buildStatRow(
                  'Статус шифрования',
                  stats.isEncryptionEnabled ? 'Включено' : 'Отключено',
                  Icons.security,
                  stats.isEncryptionEnabled ? Colors.green : Colors.red,
                ),
                _buildStatRow(
                  'Зашифрованных элементов',
                  '${stats.encryptedItemsCount}',
                  Icons.lock,
                  Colors.blue,
                ),
                _buildStatRow(
                  'Наличие ключа',
                  stats.hasEncryptionKey ? 'Есть' : 'Отсутствует',
                  Icons.key,
                  stats.hasEncryptionKey ? Colors.green : Colors.red,
                ),
                if (stats.lastEncryptionUpdate != null)
                  _buildStatRow(
                    'Последнее обновление',
                    stats.formattedLastUpdate,
                    Icons.update,
                    Colors.grey[600]!,
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Ошибка: $error'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ResponsiveText(
                label,
                isSubtitle: true,
              ),
            ),
            ResponsiveText(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      );
}

/// Виджет для отображения рекомендаций по безопасности
class SecurityRecommendationsWidget extends ConsumerWidget {
  const SecurityRecommendationsWidget({
    super.key,
    required this.dataType,
  });
  final String dataType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSecurity = ref.read(dataSecurityProvider);
    final recommendations = dataSecurity.getSecurityRecommendations(dataType);
    final securityLevel = dataSecurity.getSecurityLevel(dataType);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSecurityIcon(securityLevel),
                color: _getSecurityColor(securityLevel),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: ResponsiveText(
                  'Рекомендации по безопасности',
                  isTitle: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Уровень безопасности
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getSecurityColor(securityLevel).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getSecurityColor(securityLevel)),
            ),
            child: Text(
              'Уровень: ${_getSecurityLevelName(securityLevel)}',
              style: TextStyle(
                color: _getSecurityColor(securityLevel),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Рекомендации
          ...recommendations.map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ResponsiveText(
                      recommendation,
                      isSubtitle: true,
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

  IconData _getSecurityIcon(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.low:
        return Icons.info;
      case SecurityLevel.medium:
        return Icons.warning;
      case SecurityLevel.high:
        return Icons.security;
      case SecurityLevel.critical:
        return Icons.dangerous;
    }
  }

  Color _getSecurityColor(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.low:
        return Colors.blue;
      case SecurityLevel.medium:
        return Colors.orange;
      case SecurityLevel.high:
        return Colors.red;
      case SecurityLevel.critical:
        return Colors.purple;
    }
  }

  String _getSecurityLevelName(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.low:
        return 'Низкий';
      case SecurityLevel.medium:
        return 'Средний';
      case SecurityLevel.high:
        return 'Высокий';
      case SecurityLevel.critical:
        return 'Критический';
    }
  }
}
