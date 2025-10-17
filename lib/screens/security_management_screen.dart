import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/security_audit.dart';
import '../services/security_service.dart';
import '../ui/ui.dart' hide ResponsiveCard;
import '../widgets/responsive_layout.dart';

/// Экран управления безопасностью
class SecurityManagementScreen extends ConsumerStatefulWidget {
  const SecurityManagementScreen({super.key});

  @override
  ConsumerState<SecurityManagementScreen> createState() => _SecurityManagementScreenState();
}

class _SecurityManagementScreenState extends ConsumerState<SecurityManagementScreen> {
  final SecurityService _securityService = SecurityService();
  List<SecurityAudit> _audits = [];
  List<SecurityPolicy> _policies = [];
  SecurityStatistics? _statistics;
  bool _isLoading = true;
  String _selectedTab = 'overview';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        body: Column(
          children: [
            // Вкладки
            _buildTabs(),

            // Контент
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'overview'
                      ? _buildOverviewTab()
                      : _selectedTab == 'audits'
                          ? _buildAuditsTab()
                          : _selectedTab == 'policies'
                              ? _buildPoliciesTab()
                              : _selectedTab == 'statistics'
                                  ? _buildStatisticsTab()
                                  : _buildEncryptionTab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton('overview', 'Обзор', Icons.security),
            ),
            Expanded(
              child: _buildTabButton('audits', 'Аудит', Icons.assignment),
            ),
            Expanded(
              child: _buildTabButton('policies', 'Политики', Icons.policy),
            ),
            Expanded(
              child: _buildTabButton('statistics', 'Статистика', Icons.analytics),
            ),
            Expanded(
              child: _buildTabButton('encryption', 'Шифрование', Icons.lock),
            ),
          ],
        ),
      );

  Widget _buildTabButton(String tab, String title, IconData icon) {
    final isSelected = _selectedTab == tab;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
        if (tab == 'statistics') {
          _loadStatistics();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() => SingleChildScrollView(
        child: Column(
          children: [
            // Основная статистика
            ResponsiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ResponsiveText(
                    'Обзор безопасности',
                    isTitle: true,
                  ),
                  const SizedBox(height: 16),
                  if (_statistics == null)
                    const Center(child: Text('Статистика не загружена'))
                  else
                    Column(
                      children: [
                        // Основные метрики
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Всего событий',
                                '${_statistics!.totalEvents}',
                                Colors.blue,
                                Icons.security,
                              ),
                            ),
                            Expanded(
                              child: _buildStatCard(
                                'Критических',
                                '${_statistics!.criticalEvents}',
                                Colors.red,
                                Icons.warning,
                              ),
                            ),
                            Expanded(
                              child: _buildStatCard(
                                'Разрешено',
                                '${_statistics!.resolvedEvents}',
                                Colors.green,
                                Icons.check_circle,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Уровень риска
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                _getRiskColor(_statistics!.overallRiskLevel).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getRiskColor(_statistics!.overallRiskLevel),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getRiskIcon(_statistics!.overallRiskLevel),
                                color: _getRiskColor(
                                  _statistics!.overallRiskLevel,
                                ),
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Общий уровень риска',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getRiskColor(
                                          _statistics!.overallRiskLevel,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _statistics!.overallRiskLevel.displayName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _getRiskColor(
                                          _statistics!.overallRiskLevel,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Последние события
            ResponsiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const ResponsiveText(
                        'Последние события',
                        isTitle: true,
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _loadAudits,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Обновить'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_audits.isEmpty)
                    const Center(child: Text('События не найдены'))
                  else
                    ..._audits.take(5).map(_buildAuditCard),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildAuditsTab() => Column(
        children: [
          // Заголовок с фильтрами
          ResponsiveCard(
            child: Row(
              children: [
                const ResponsiveText(
                  'События аудита',
                  isTitle: true,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadAudits,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),

          // Список событий
          Expanded(
            child: _audits.isEmpty
                ? const Center(child: Text('События аудита не найдены'))
                : ListView.builder(
                    itemCount: _audits.length,
                    itemBuilder: (context, index) {
                      final audit = _audits[index];
                      return _buildAuditCard(audit);
                    },
                  ),
          ),
        ],
      );

  Widget _buildAuditCard(SecurityAudit audit) {
    final levelColor = _getLevelColor(audit.level);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(
                _getLevelIcon(audit.level),
                color: levelColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audit.eventType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      audit.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              _buildLevelChip(audit.level),
              if (!audit.isResolved)
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAuditAction(value, audit),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'resolve',
                      child: ListTile(
                        leading: Icon(Icons.check),
                        title: Text('Разрешить'),
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Метаданные
          if (audit.userId != null || audit.ipAddress != null) ...[
            Row(
              children: [
                if (audit.userId != null) ...[
                  _buildInfoChip('Пользователь', audit.userId!, Colors.blue),
                  const SizedBox(width: 8),
                ],
                if (audit.ipAddress != null) _buildInfoChip('IP', audit.ipAddress!, Colors.green),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(audit.timestamp),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (audit.isResolved) ...[
                const Spacer(),
                Text(
                  'Разрешено: ${_formatDateTime(audit.resolvedAt!)}',
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPoliciesTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                const ResponsiveText(
                  'Политики безопасности',
                  isTitle: true,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadPolicies,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showCreatePolicyDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Создать'),
                ),
              ],
            ),
          ),

          // Список политик
          Expanded(
            child: _policies.isEmpty
                ? const Center(child: Text('Политики не найдены'))
                : ListView.builder(
                    itemCount: _policies.length,
                    itemBuilder: (context, index) {
                      final policy = _policies[index];
                      return _buildPolicyCard(policy);
                    },
                  ),
          ),
        ],
      );

  Widget _buildPolicyCard(SecurityPolicy policy) {
    final severityColor = _getLevelColor(policy.severity);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(
                _getPolicyIcon(policy.type),
                color: severityColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      policy.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              _buildLevelChip(policy.severity),
              PopupMenuButton<String>(
                onSelected: (value) => _handlePolicyAction(value, policy),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Редактировать'),
                    ),
                  ),
                  PopupMenuItem(
                    value: policy.isEnabled ? 'disable' : 'enable',
                    child: ListTile(
                      leading: Icon(
                        policy.isEnabled ? Icons.pause : Icons.play_arrow,
                      ),
                      title: Text(policy.isEnabled ? 'Отключить' : 'Включить'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Удалить'),
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              _buildInfoChip('Тип', policy.type.displayName, Colors.blue),
              const SizedBox(width: 8),
              _buildInfoChip(
                'Статус',
                policy.isEnabled ? 'Включена' : 'Отключена',
                policy.isEnabled ? Colors.green : Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Роли
          if (policy.affectedRoles.isNotEmpty) ...[
            Text(
              'Затронутые роли:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: policy.affectedRoles
                  .map(
                    (role) => Chip(
                      label: Text(role),
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 12),

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создана: ${_formatDateTime(policy.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Обновлена: ${_formatDateTime(policy.updatedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() => SingleChildScrollView(
        child: Column(
          children: [
            // Основная статистика
            ResponsiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ResponsiveText(
                    'Статистика безопасности',
                    isTitle: true,
                  ),
                  const SizedBox(height: 16),
                  if (_statistics == null)
                    const Center(child: Text('Статистика не загружена'))
                  else
                    Column(
                      children: [
                        // Основные метрики
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Всего событий',
                                '${_statistics!.totalEvents}',
                                Colors.blue,
                                Icons.security,
                              ),
                            ),
                            Expanded(
                              child: _buildStatCard(
                                'Критических',
                                '${_statistics!.criticalEvents}',
                                Colors.red,
                                Icons.warning,
                              ),
                            ),
                            Expanded(
                              child: _buildStatCard(
                                'Высоких',
                                '${_statistics!.highEvents}',
                                Colors.orange,
                                Icons.error,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Разрешено',
                                '${_statistics!.resolvedEvents}',
                                Colors.green,
                                Icons.check_circle,
                              ),
                            ),
                            Expanded(
                              child: _buildStatCard(
                                'Неразрешенных',
                                '${_statistics!.unresolvedEvents}',
                                Colors.red,
                                Icons.pending,
                              ),
                            ),
                            Expanded(
                              child: _buildStatCard(
                                'Процент разрешения',
                                '${(_statistics!.resolutionRate * 100).toStringAsFixed(1)}%',
                                Colors.purple,
                                Icons.percent,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // События по типам
                        if (_statistics!.eventsByType.isNotEmpty) ...[
                          Text(
                            'События по типам:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._statistics!.eventsByType.entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key),
                                      Text('${entry.value}'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: entry.value / _statistics!.totalEvents,
                                    backgroundColor: Colors.grey.withValues(alpha: 0.3),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildEncryptionTab() => SingleChildScrollView(
        child: Column(
          children: [
            // Информация о шифровании
            ResponsiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ResponsiveText(
                    'Шифрование',
                    isTitle: true,
                  ),

                  const SizedBox(height: 16),

                  // Активные ключи
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Активные ключи',
                          '${_securityService.getActiveEncryptionKeys().length}',
                          Colors.blue,
                          Icons.vpn_key,
                        ),
                      ),
                      Expanded(
                        child: _buildStatCard(
                          'Алгоритм',
                          'AES-256-CBC',
                          Colors.green,
                          Icons.lock,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Действия
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showCreateKeyDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Создать ключ'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _testEncryption,
                          icon: const Icon(Icons.security),
                          label: const Text('Тест шифрования'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Информация о безопасности
            ResponsiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ResponsiveText(
                    'Информация о безопасности',
                    isTitle: true,
                  ),
                  const SizedBox(height: 16),
                  _buildSecurityInfoItem('Версия шифрования', 'AES-256-CBC'),
                  _buildSecurityInfoItem('Хеширование', 'SHA-256'),
                  _buildSecurityInfoItem('Длина ключа', '256 бит'),
                  _buildSecurityInfoItem('Режим шифрования', 'CBC'),
                  _buildSecurityInfoItem('Заполнение', 'PKCS7'),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildLevelChip(SecurityLevel level) {
    final color = _getLevelColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        level.displayName,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _buildSecurityInfoItem(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 150,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const Text(': '),
            Expanded(
              child: Text(value),
            ),
          ],
        ),
      );

  Color _getLevelColor(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.info:
        return Colors.blue;
      case SecurityLevel.low:
        return Colors.green;
      case SecurityLevel.medium:
        return Colors.orange;
      case SecurityLevel.high:
        return Colors.red;
      case SecurityLevel.critical:
        return Colors.purple;
    }
  }

  IconData _getLevelIcon(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.info:
        return Icons.info;
      case SecurityLevel.low:
        return Icons.check_circle;
      case SecurityLevel.medium:
        return Icons.warning;
      case SecurityLevel.high:
        return Icons.error;
      case SecurityLevel.critical:
        return Icons.dangerous;
    }
  }

  Color _getRiskColor(SecurityLevel level) => _getLevelColor(level);

  IconData _getRiskIcon(SecurityLevel level) => _getLevelIcon(level);

  IconData _getPolicyIcon(SecurityPolicyType type) {
    switch (type) {
      case SecurityPolicyType.authentication:
        return Icons.login;
      case SecurityPolicyType.authorization:
        return Icons.admin_panel_settings;
      case SecurityPolicyType.dataProtection:
        return Icons.shield;
      case SecurityPolicyType.networkSecurity:
        return Icons.network_check;
      case SecurityPolicyType.auditLogging:
        return Icons.assignment;
      case SecurityPolicyType.encryption:
        return Icons.lock;
      case SecurityPolicyType.accessControl:
        return Icons.security;
      case SecurityPolicyType.sessionManagement:
        return Icons.schedule;
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _securityService.initialize();
      await Future.wait([
        _loadAudits(),
        _loadPolicies(),
        _loadStatistics(),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки данных: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAudits() async {
    try {
      final audits = await _securityService.getSecurityAudits(limit: 50);
      setState(() {
        _audits = audits;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки событий аудита: $e');
      }
    }
  }

  Future<void> _loadPolicies() async {
    try {
      final policies = _securityService.getActivePolicies();
      setState(() {
        _policies = policies;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки политик: $e');
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final statistics = await _securityService.getSecurityStatistics();
      setState(() {
        _statistics = statistics;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки статистики: $e');
      }
    }
  }

  void _handleAuditAction(String action, SecurityAudit audit) {
    switch (action) {
      case 'resolve':
        _resolveAudit(audit);
        break;
    }
  }

  void _resolveAudit(SecurityAudit audit) {
    // TODO(developer): Реализовать разрешение события аудита
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Разрешение события "${audit.eventType}" будет реализовано'),
      ),
    );
  }

  void _handlePolicyAction(String action, SecurityPolicy policy) {
    switch (action) {
      case 'edit':
        _editPolicy(policy);
        break;
      case 'enable':
      case 'disable':
        _togglePolicy(policy);
        break;
      case 'delete':
        _deletePolicy(policy);
        break;
    }
  }

  void _editPolicy(SecurityPolicy policy) {
    // TODO(developer): Реализовать редактирование политики
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Редактирование политики "${policy.name}" будет реализовано'),
      ),
    );
  }

  void _togglePolicy(SecurityPolicy policy) {
    // TODO(developer): Реализовать включение/отключение политики
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${policy.isEnabled ? 'Отключение' : 'Включение'} политики "${policy.name}" будет реализовано',
        ),
      ),
    );
  }

  void _deletePolicy(SecurityPolicy policy) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить политику'),
        content: Text('Вы уверены, что хотите удалить политику "${policy.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _securityService.deleteSecurityPolicy(policy.id);
                _loadPolicies();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Политика удалена'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка удаления политики: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showCreatePolicyDialog() {
    // TODO(developer): Реализовать диалог создания политики
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание политики безопасности будет реализовано'),
      ),
    );
  }

  void _showCreateKeyDialog() {
    // TODO(developer): Реализовать диалог создания ключа шифрования
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание ключа шифрования будет реализовано'),
      ),
    );
  }

  void _testEncryption() {
    // TODO(developer): Реализовать тест шифрования
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Тест шифрования будет реализован'),
      ),
    );
  }
}
