import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist.dart';
import '../models/specialist_team.dart';
import '../providers/specialist_providers.dart';
import '../services/team_service.dart';

/// Экран управления командой специалистов
class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({
    super.key,
    required this.teamId,
    this.isEditable = true,
  });

  final String teamId;
  final bool isEditable;

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  final TeamService _teamService = TeamService();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _teamNameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Команда специалистов'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            if (widget.isEditable)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showAddSpecialistDialog,
                tooltip: 'Добавить специалиста',
              ),
          ],
        ),
        body: StreamBuilder<SpecialistTeam?>(
          stream: _teamService.watchTeam(widget.teamId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
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

            final team = snapshot.data;
            if (team == null) {
              return const Center(child: Text('Команда не найдена'));
            }

            return _buildTeamContent(team);
          },
        ),
      );

  Widget _buildTeamContent(SpecialistTeam team) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о команде
            _buildTeamInfo(team),

            const SizedBox(height: 24),

            // Статус команды
            _buildTeamStatus(team),

            const SizedBox(height: 24),

            // Список специалистов
            _buildSpecialistsList(team),

            const SizedBox(height: 24),

            // Информация об оплате
            if (team.totalPrice != null) _buildPaymentInfo(team),

            const SizedBox(height: 24),

            // Действия
            if (widget.isEditable) _buildActions(team),
          ],
        ),
      );

  Widget _buildTeamInfo(SpecialistTeam team) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Информация о команде',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Название команды
              if (team.teamName != null) ...[
                _buildInfoRow('Название:', team.teamName!),
                const SizedBox(height: 8),
              ],

              // Описание
              if (team.description != null) ...[
                _buildInfoRow('Описание:', team.description!),
                const SizedBox(height: 8),
              ],

              // Мероприятие
              if (team.eventTitle != null) ...[
                _buildInfoRow('Мероприятие:', team.eventTitle!),
                const SizedBox(height: 8),
              ],

              // Дата мероприятия
              if (team.eventDate != null) ...[
                _buildInfoRow(
                  'Дата:',
                  '${team.eventDate!.day}.${team.eventDate!.month}.${team.eventDate!.year}',
                ),
                const SizedBox(height: 8),
              ],

              // Место проведения
              if (team.eventLocation != null) ...[
                _buildInfoRow('Место:', team.eventLocation!),
                const SizedBox(height: 8),
              ],

              // Заметки
              if (team.notes != null) ...[
                _buildInfoRow('Заметки:', team.notes!),
              ],
            ],
          ),
        ),
      );

  Widget _buildInfoRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      );

  Widget _buildTeamStatus(SpecialistTeam team) {
    Color statusColor;
    IconData statusIcon;

    switch (team.status) {
      case TeamStatus.draft:
        statusColor = Colors.orange;
        statusIcon = Icons.edit;
        break;
      case TeamStatus.confirmed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TeamStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case TeamStatus.active:
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle;
        break;
      case TeamStatus.completed:
        statusColor = Colors.grey;
        statusIcon = Icons.done_all;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.status.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    team.status.description,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistsList(SpecialistTeam team) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Специалисты (${team.specialistCount})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (widget.isEditable && team.status == TeamStatus.draft)
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showAddSpecialistDialog,
                      tooltip: 'Добавить специалиста',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (team.specialists.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'В команде пока нет специалистов',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...team.specialists.map(
                  (specialistId) => _buildSpecialistItem(team, specialistId),
                ),
            ],
          ),
        ),
      );

  Widget _buildSpecialistItem(SpecialistTeam team, String specialistId) =>
      FutureBuilder<Specialist?>(
        future: ref.read(specialistProvider(specialistId).future),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Загрузка...'),
            );
          }

          final specialist = snapshot.data;
          if (specialist == null) {
            return ListTile(
              leading: const Icon(Icons.person_off, color: Colors.red),
              title: const Text('Специалист не найден'),
              trailing: widget.isEditable && team.status == TeamStatus.draft
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeSpecialist(specialistId),
                    )
                  : null,
            );
          }

          final role = team.getSpecialistRole(specialistId);
          final payment = team.getSpecialistPayment(specialistId);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: specialist.avatar != null
                    ? NetworkImage(specialist.avatar!)
                    : null,
                child:
                    specialist.avatar == null ? const Icon(Icons.person) : null,
              ),
              title: Text(specialist.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (role != null) Text('Роль: $role'),
                  if (payment > 0)
                    Text('Оплата: ${payment.toStringAsFixed(0)} ₽'),
                  Text(specialist.specialization ?? ''),
                ],
              ),
              trailing: widget.isEditable && team.status == TeamStatus.draft
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeSpecialist(specialistId),
                      tooltip: 'Удалить из команды',
                    )
                  : null,
              onTap: () => _showSpecialistDetails(specialist, role, payment),
            ),
          );
        },
      );

  Widget _buildPaymentInfo(SpecialistTeam team) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Информация об оплате',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                'Общая стоимость:',
                '${team.totalPrice!.toStringAsFixed(0)} ₽',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Общая оплата:',
                '${team.totalPaymentAmount.toStringAsFixed(0)} ₽',
              ),
              if (team.paymentSplit.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Распределение оплаты:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                ...team.paymentSplit.entries.map(
                  (entry) => FutureBuilder<Specialist?>(
                    future: ref.read(specialistProvider(entry.key).future),
                    builder: (context, snapshot) {
                      final specialistName =
                          snapshot.data?.name ?? 'Неизвестный';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(specialistName),
                            Text('${entry.value.toStringAsFixed(0)} ₽'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildActions(SpecialistTeam team) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Действия',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _editTeamInfo(team),
                      icon: const Icon(Icons.edit),
                      label: const Text('Редактировать'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: team.status == TeamStatus.draft
                          ? () => _confirmTeam(team)
                          : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Подтвердить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (team.status == TeamStatus.draft) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectTeam(team),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Отклонить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  void _showAddSpecialistDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить специалиста'),
        content: const Text(
          'Функция добавления специалистов будет реализована в следующем обновлении.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _removeSpecialist(String specialistId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить специалиста'),
        content: const Text(
          'Вы уверены, что хотите удалить этого специалиста из команды?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _teamService.removeSpecialistFromTeam(
                  teamId: widget.teamId,
                  specialistId: specialistId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Специалист удален из команды'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showSpecialistDetails(
    Specialist specialist,
    String? role,
    double payment,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(specialist.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (role != null) Text('Роль: $role'),
            if (payment > 0) Text('Оплата: ${payment.toStringAsFixed(0)} ₽'),
            Text('Специализация: ${specialist.specialization ?? 'Не указана'}'),
            Text('Рейтинг: ${specialist.rating.toStringAsFixed(1)}'),
            Text('Опыт: ${specialist.yearsOfExperience} лет'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _editTeamInfo(SpecialistTeam team) {
    _teamNameController.text = team.teamName ?? '';
    _descriptionController.text = team.description ?? '';
    _notesController.text = team.notes ?? '';

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать команду'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _teamNameController,
                decoration: const InputDecoration(
                  labelText: 'Название команды',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Заметки',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _teamService.updateTeam(
                  teamId: widget.teamId,
                  teamName: _teamNameController.text.trim().isEmpty
                      ? null
                      : _teamNameController.text.trim(),
                  description: _descriptionController.text.trim().isEmpty
                      ? null
                      : _descriptionController.text.trim(),
                  notes: _notesController.text.trim().isEmpty
                      ? null
                      : _notesController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Команда обновлена')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _confirmTeam(SpecialistTeam team) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердить команду'),
        content: const Text(
          'Вы уверены, что хотите подтвердить эту команду? После подтверждения изменения будут ограничены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _teamService.confirmTeam(teamId: widget.teamId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Команда подтверждена')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  void _rejectTeam(SpecialistTeam team) {
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонить команду'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Укажите причину отклонения:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Причина',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Укажите причину отклонения')),
                );
                return;
              }

              Navigator.of(context).pop();
              try {
                await _teamService.rejectTeam(
                  teamId: widget.teamId,
                  reason: reasonController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Команда отклонена')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }
}
