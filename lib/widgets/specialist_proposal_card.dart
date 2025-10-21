import 'package:flutter/material.dart';

import '../models/specialist_profile.dart';
import '../models/specialist_proposal.dart';
import '../services/specialist_proposal_service.dart';

/// Карточка предложения специалистов
class SpecialistProposalCard extends StatefulWidget {
  const SpecialistProposalCard({
    super.key,
    required this.proposal,
    required this.onAccept,
    required this.onReject,
    this.showActions = true,
  });

  final SpecialistProposal proposal;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool showActions;

  @override
  State<SpecialistProposalCard> createState() => _SpecialistProposalCardState();
}

class _SpecialistProposalCardState extends State<SpecialistProposalCard> {
  final SpecialistProposalService _proposalService = SpecialistProposalService();
  // final SpecialistService _specialistService = SpecialistService(); // Unused field removed
  List<SpecialistProfile>? _specialists;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSpecialists();
  }

  Future<void> _loadSpecialists() async {
    try {
      final specialists = <SpecialistProfile>[];
      for (final _ in widget.proposal.specialistIds) {
        // final specialist = await _specialistService.getSpecialistProfile(specialistId);
        // Временная заглушка - создаем пустой профиль
        // TODO(developer): Implement getSpecialistProfile
        // const specialist = null;
        // if (specialist != null) {
        //   specialists.add(specialist);
        // }
      }
      if (mounted) {
        setState(() {
          _specialists = specialists;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки специалистов: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark; // Unused variable removed

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и статус
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.proposal.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 8),

            // Информация об организаторе
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: widget.proposal.organizerAvatar != null
                      ? NetworkImage(widget.proposal.organizerAvatar!)
                      : null,
                  child: widget.proposal.organizerAvatar == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.proposal.organizerName ?? 'Организатор',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        widget.proposal.timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Описание
            Text(widget.proposal.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),

            // Специалисты
            if (_specialists != null) ...[
              Text(
                'Предложенные специалисты (${_specialists!.length}):',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...(_specialists!.map(_buildSpecialistItem)),
            ] else if (_isLoading) ...[
              const Center(
                child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
              ),
            ],
            const SizedBox(height: 16),

            // Действия
            if (widget.showActions && widget.proposal.isActive) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Отклонить'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _specialists != null && _specialists!.isNotEmpty
                          ? _showSpecialistSelection
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Выбрать'),
                    ),
                  ),
                ],
              ),
            ] else if (widget.proposal.isAccepted) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Предложение принято',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (widget.proposal.isRejected) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Предложение отклонено',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final theme = Theme.of(context);

    if (widget.proposal.isAccepted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Принято',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else if (widget.proposal.isRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Отклонено',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Ожидает',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  Widget _buildSpecialistItem(SpecialistProfile specialist) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: specialist.avatarUrl != null
                ? NetworkImage(specialist.avatarUrl!)
                : null,
            child: specialist.avatarUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  specialist.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (specialist.specialization.isNotEmpty)
                  Text(
                    specialist.specialization,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                if (specialist.rating > 0)
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        specialist.rating.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSpecialistSelection() {
    if (_specialists == null || _specialists!.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Выберите специалиста',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _specialists!.length,
                  itemBuilder: (context, index) {
                    final specialist = _specialists![index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: specialist.avatarUrl != null
                            ? NetworkImage(specialist.avatarUrl!)
                            : null,
                        child: specialist.avatarUrl == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(specialist.displayName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (specialist.specialization.isNotEmpty) Text(specialist.specialization),
                          if (specialist.rating > 0)
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(specialist.rating.toStringAsFixed(1)),
                              ],
                            ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _handleAccept(specialist.id),
                        child: const Text('Выбрать'),
                      ),
                      onTap: () => _handleAccept(specialist.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAccept(String specialistId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _proposalService.acceptProposal(widget.proposal.id, specialistId);

      if (mounted) {
        Navigator.of(context).pop(); // Закрыть модальное окно
        widget.onAccept();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Предложение принято!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleReject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонить предложение'),
        content: const Text('Вы уверены, что хотите отклонить это предложение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        setState(() {
          _isLoading = true;
        });

        await _proposalService.rejectProposal(widget.proposal.id);

        if (mounted) {
          widget.onReject();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Предложение отклонено'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
