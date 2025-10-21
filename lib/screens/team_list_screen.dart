import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist_team.dart';
import '../providers/team_providers.dart';
import 'team_screen.dart';

/// Экран списка команд специалистов
class TeamListScreen extends ConsumerWidget {
  const TeamListScreen({super.key, required this.organizerId, this.title = 'Мои команды'});

  final String organizerId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(organizerTeamsProvider(organizerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(organizerTeamsProvider(organizerId)),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('У вас пока нет команд', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text(
                    'Создайте команду специалистов для вашего мероприятия',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return _buildTeamCard(context, team);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(organizerTeamsProvider(organizerId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, SpecialistTeam team) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: InkWell(
      onTap: () => _navigateToTeam(context, team),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и статус
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    team.teamName ?? 'Команда специалистов',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(team.status),
              ],
            ),

            const SizedBox(height: 12),

            // Информация о команде
            _buildTeamInfo(team),

            const SizedBox(height: 12),

            // Действия
            _buildTeamActions(context, team),
          ],
        ),
      ),
    ),
  );

  Widget _buildStatusChip(TeamStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case TeamStatus.draft:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.edit;
        break;
      case TeamStatus.confirmed:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case TeamStatus.rejected:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
        break;
      case TeamStatus.active:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.play_circle;
        break;
      case TeamStatus.completed:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.done_all;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamInfo(SpecialistTeam team) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Количество специалистов
      Row(
        children: [
          const Icon(Icons.people, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('Специалистов: ${team.specialistCount}'),
        ],
      ),

      const SizedBox(height: 4),

      // Мероприятие
      if (team.eventTitle != null) ...[
        Row(
          children: [
            const Icon(Icons.event, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(team.eventTitle!, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],

      // Дата мероприятия
      if (team.eventDate != null) ...[
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text('${team.eventDate!.day}.${team.eventDate!.month}.${team.eventDate!.year}'),
          ],
        ),
        const SizedBox(height: 4),
      ],

      // Место проведения
      if (team.eventLocation != null) ...[
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(team.eventLocation!)),
          ],
        ),
        const SizedBox(height: 4),
      ],

      // Стоимость
      if (team.totalPrice != null) ...[
        Row(
          children: [
            const Icon(Icons.attach_money, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Стоимость: ${team.totalPrice!.toStringAsFixed(0)} ₽',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    ],
  );

  Widget _buildTeamActions(BuildContext context, SpecialistTeam team) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _navigateToTeam(context, team),
          icon: const Icon(Icons.visibility),
          label: const Text('Просмотреть'),
        ),
      ),
      const SizedBox(width: 8),
      if (team.status == TeamStatus.draft) ...[
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _navigateToTeam(context, team, isEditable: true),
            icon: const Icon(Icons.edit),
            label: const Text('Редактировать'),
          ),
        ),
      ] else ...[
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _navigateToTeam(context, team),
            icon: const Icon(Icons.info),
            label: const Text('Подробнее'),
          ),
        ),
      ],
    ],
  );

  void _navigateToTeam(BuildContext context, SpecialistTeam team, {bool isEditable = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TeamScreen(teamId: team.id, isEditable: isEditable),
      ),
    );
  }
}

/// Экран команд специалиста
class SpecialistTeamListScreen extends ConsumerWidget {
  const SpecialistTeamListScreen({super.key, required this.specialistId});

  final String specialistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(specialistTeamsProvider(specialistId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои команды'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(specialistTeamsProvider(specialistId)),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Вы не участвуете в командах',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Организаторы могут пригласить вас в команду',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return _buildTeamCard(context, team);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(specialistTeamsProvider(specialistId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, SpecialistTeam team) {
    final role = team.getSpecialistRole(specialistId);
    final payment = team.getSpecialistPayment(specialistId);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToTeam(context, team),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и статус
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      team.teamName ?? 'Команда специалистов',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildStatusChip(team.status),
                ],
              ),

              const SizedBox(height: 12),

              // Роль и оплата
              if (role != null || payment > 0) ...[
                Row(
                  children: [
                    if (role != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (payment > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${payment.toStringAsFixed(0)} ₽',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Информация о команде
              _buildTeamInfo(team),

              const SizedBox(height: 12),

              // Действие
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToTeam(context, team),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Просмотреть команду'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TeamStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case TeamStatus.draft:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.edit;
        break;
      case TeamStatus.confirmed:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case TeamStatus.rejected:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
        break;
      case TeamStatus.active:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.play_circle;
        break;
      case TeamStatus.completed:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.done_all;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamInfo(SpecialistTeam team) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Количество специалистов
      Row(
        children: [
          const Icon(Icons.people, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('Специалистов: ${team.specialistCount}'),
        ],
      ),

      const SizedBox(height: 4),

      // Мероприятие
      if (team.eventTitle != null) ...[
        Row(
          children: [
            const Icon(Icons.event, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(team.eventTitle!, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],

      // Дата мероприятия
      if (team.eventDate != null) ...[
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text('${team.eventDate!.day}.${team.eventDate!.month}.${team.eventDate!.year}'),
          ],
        ),
      ],
    ],
  );

  void _navigateToTeam(BuildContext context, SpecialistTeam team) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => TeamScreen(teamId: team.id, isEditable: false)),
    );
  }
}
