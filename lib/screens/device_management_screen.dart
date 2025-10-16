import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/security_settings.dart';
import '../providers/auth_providers.dart';
import '../services/security_service.dart';

/// Экран управления устройствами
class DeviceManagementScreen extends ConsumerStatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  ConsumerState<DeviceManagementScreen> createState() =>
      _DeviceManagementScreenState();
}

class _DeviceManagementScreenState
    extends ConsumerState<DeviceManagementScreen> {
  final SecurityService _securityService = SecurityService();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Управление устройствами'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: Consumer(
          builder: (context, ref, child) {
            final currentUser = ref.watch(authServiceProvider).currentUser;

            if (currentUser == null) {
              return const Center(
                child: Text('Пользователь не авторизован'),
              );
            }

            return StreamBuilder<List<SecurityDevice>>(
              stream: _securityService.getUserDevices(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Ошибка: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }

                final devices = snapshot.data ?? [];

                if (devices.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Текущее устройство
                    _buildCurrentDeviceCard(),

                    const SizedBox(height: 16),

                    // Список устройств
                    _buildDevicesList(devices),
                  ],
                );
              },
            );
          },
        ),
      );

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Нет подключенных устройств',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Устройства, с которых вы входили в аккаунт, будут отображаться здесь',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildCurrentDeviceCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.phone_android,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Текущее устройство',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Это устройство',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Активно',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDeviceInfoItem(
                      icon: Icons.info,
                      label: 'Тип',
                      value: 'Мобильное устройство',
                    ),
                  ),
                  Expanded(
                    child: _buildDeviceInfoItem(
                      icon: Icons.access_time,
                      label: 'Последний вход',
                      value: 'Сейчас',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildDevicesList(List<SecurityDevice> devices) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Все устройства',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...devices.map(_buildDeviceCard),
        ],
      );

  Widget _buildDeviceCard(SecurityDevice device) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getDeviceIcon(device.deviceType),
                    color: _getDeviceStatusColor(device),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.deviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          device.deviceType,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDeviceStatusChip(device),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDeviceInfoItem(
                      icon: Icons.info,
                      label: 'ОС',
                      value: device.osVersion,
                    ),
                  ),
                  Expanded(
                    child: _buildDeviceInfoItem(
                      icon: Icons.apps,
                      label: 'Версия приложения',
                      value: device.appVersion,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildDeviceInfoItem(
                      icon: Icons.access_time,
                      label: 'Первый вход',
                      value: _formatDateTime(device.firstSeen),
                    ),
                  ),
                  Expanded(
                    child: _buildDeviceInfoItem(
                      icon: Icons.schedule,
                      label: 'Последний вход',
                      value: _formatDateTime(device.lastSeen),
                    ),
                  ),
                ],
              ),

              if (device.lastIpAddress != null) ...[
                const SizedBox(height: 8),
                _buildDeviceInfoItem(
                  icon: Icons.location_on,
                  label: 'IP адрес',
                  value: device.lastIpAddress!,
                ),
              ],

              const SizedBox(height: 12),

              // Действия
              Row(
                children: [
                  if (!device.isTrusted)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _trustDevice(device),
                        icon: const Icon(Icons.verified_user, size: 16),
                        label: const Text('Доверять'),
                      ),
                    ),
                  if (!device.isTrusted) const SizedBox(width: 8),
                  if (!device.isBlocked)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _blockDevice(device),
                        icon: const Icon(Icons.block, size: 16),
                        label: const Text('Заблокировать'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  if (device.isBlocked)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _unblockDevice(device),
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Разблокировать'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildDeviceInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildDeviceStatusChip(SecurityDevice device) {
    if (device.isBlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Заблокировано',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (device.isTrusted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Доверенное',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Неизвестно',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
      case 'android':
      case 'ios':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet;
      case 'desktop':
      case 'windows':
      case 'macos':
      case 'linux':
        return Icons.computer;
      case 'web':
        return Icons.web;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getDeviceStatusColor(SecurityDevice device) {
    if (device.isBlocked) {
      return Colors.red;
    } else if (device.isTrusted) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  Future<void> _trustDevice(SecurityDevice device) async {
    try {
      final currentUser = await ref.read(authServiceProvider).getCurrentUser();
      if (currentUser != null) {
        await _securityService.trustDevice(device.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Устройство добавлено в доверенные'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _blockDevice(SecurityDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заблокировать устройство'),
        content: Text(
          'Вы уверены, что хотите заблокировать устройство "${device.deviceName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        final currentUser =
            await ref.read(authServiceProvider).getCurrentUser();
        if (currentUser != null) {
          await _securityService.blockDevice(device.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Устройство заблокировано'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unblockDevice(SecurityDevice device) async {
    try {
      final currentUser = await ref.read(authServiceProvider).getCurrentUser();
      if (currentUser != null) {
        await _securityService.unblockDevice(device.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Устройство разблокировано'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
