import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/proposal.dart';
import '../models/specialist.dart';
import '../services/proposal_service.dart';
import 'responsive_layout.dart';

/// Виджет для отображения предложения специалистов
class ProposalWidget extends ConsumerWidget {
  const ProposalWidget({
    super.key,
    required this.proposal,
    this.isOrganizer = false,
    this.onProposalChanged,
  });
  final Proposal proposal;
  final bool isOrganizer;
  final VoidCallback? onProposalChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с статусом
            Row(
              children: [
                Icon(
                  _getProposalIcon(),
                  color: proposal.color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Предложение специалистов',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                _buildStatusChip(),
              ],
            ),

            const SizedBox(height: 12),

            // Информация о предложении
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: proposal.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: proposal.color),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Специалистов:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${proposal.specialistCount}',
                        style: TextStyle(
                          color: proposal.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Общая стоимость:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${proposal.totalCost.toStringAsFixed(0)} ₽',
                        style: TextStyle(
                          color: proposal.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Сообщение организатора
            if (proposal.message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.message, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        proposal.message!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Список специалистов
            const SizedBox(height: 12),
            Text(
              'Предложенные специалисты:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 8),

            ...proposal.specialists
                .map((specialist) => _buildSpecialistCard(context, specialist)),

            // Кнопки действий
            if (proposal.canRespond && !isOrganizer) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptProposal(context, ref),
                      icon: const Icon(Icons.check),
                      label: const Text('Принять'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectProposal(context, ref),
                      icon: const Icon(Icons.close),
                      label: const Text('Отклонить'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Информация о времени
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Создано: ${_formatDate(proposal.createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatusChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: proposal.color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: proposal.color),
        ),
        child: Text(
          proposal.displayName,
          style: TextStyle(
            color: proposal.color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _buildSpecialistCard(
    BuildContext context,
    ProposalSpecialist specialist,
  ) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    specialist.specialistName ?? specialist.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    specialist.categoryName ?? 'Услуга',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (specialist.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      specialist.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            if (specialist.estimatedPrice != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${specialist.estimatedPrice!.toStringAsFixed(0)} ₽',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  IconData _getProposalIcon() {
    switch (proposal.status) {
      case ProposalStatus.pending:
        return Icons.pending_actions;
      case ProposalStatus.accepted:
        return Icons.check_circle;
      case ProposalStatus.rejected:
        return Icons.cancel;
      case ProposalStatus.expired:
        return Icons.access_time;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else {
      return '${difference.inMinutes}м назад';
    }
  }

  Future<void> _acceptProposal(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(proposalServiceProvider);
      await service.acceptProposal(
        proposalId: proposal.id,
        customerId: 'current_user_id', // TODO: Получить из контекста
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Предложение принято! Созданы бронирования.'),
          backgroundColor: Colors.green,
        ),
      );

      onProposalChanged?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rejectProposal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _RejectProposalDialog(
        proposal: proposal,
        onRejected: () {
          onProposalChanged?.call();
        },
      ),
    );
  }
}

/// Виджет для создания предложения (для организаторов)
class CreateProposalWidget extends ConsumerStatefulWidget {
  const CreateProposalWidget({
    super.key,
    required this.chatId,
    required this.organizerId,
    required this.customerId,
    this.onProposalCreated,
  });
  final String chatId;
  final String organizerId;
  final String customerId;
  final VoidCallback? onProposalCreated;

  @override
  ConsumerState<CreateProposalWidget> createState() =>
      _CreateProposalWidgetState();
}

class _CreateProposalWidgetState extends ConsumerState<CreateProposalWidget> {
  final _messageController = TextEditingController();
  final List<ProposalSpecialist> _selectedSpecialists = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Предложить специалистов',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Выберите специалистов для предложения клиенту.',
            ),

            const SizedBox(height: 16),

            // Кнопка выбора специалистов
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _selectSpecialists,
              icon: const Icon(Icons.people),
              label: Text(
                _selectedSpecialists.isEmpty
                    ? 'Выбрать специалистов'
                    : 'Выбрано: ${_selectedSpecialists.length}',
              ),
            ),

            // Список выбранных специалистов
            if (_selectedSpecialists.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Выбранные специалисты:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              ..._selectedSpecialists.map(
                (specialist) =>
                    _buildSelectedSpecialistCard(context, specialist),
              ),
            ],

            // Сообщение
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Сообщение клиенту (необязательно)',
                border: OutlineInputBorder(),
                hintText: 'Добавьте комментарий к предложению...',
              ),
              maxLines: 3,
            ),

            // Кнопка создания предложения
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canCreateProposal() ? _createProposal : null,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isLoading ? 'Создание...' : 'Создать предложение',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildSelectedSpecialistCard(
    BuildContext context,
    ProposalSpecialist specialist,
  ) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    specialist.specialistName ?? specialist.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    specialist.categoryName ?? 'Услуга',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeSpecialist(specialist),
              icon: const Icon(Icons.remove_circle, color: Colors.red),
            ),
          ],
        ),
      );

  bool _canCreateProposal() => _selectedSpecialists.isNotEmpty && !_isLoading;

  void _selectSpecialists() {
    showDialog(
      context: context,
      builder: (context) => _SelectSpecialistsDialog(
        onSpecialistsSelected: (specialists) {
          setState(() {
            _selectedSpecialists.clear();
            _selectedSpecialists.addAll(specialists);
          });
        },
      ),
    );
  }

  void _removeSpecialist(ProposalSpecialist specialist) {
    setState(() {
      _selectedSpecialists.remove(specialist);
    });
  }

  Future<void> _createProposal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(proposalServiceProvider);
      await service.createProposal(
        chatId: widget.chatId,
        organizerId: widget.organizerId,
        customerId: widget.customerId,
        specialists: _selectedSpecialists,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Предложение создано и отправлено клиенту'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onProposalCreated?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Диалог для отклонения предложения
class _RejectProposalDialog extends ConsumerStatefulWidget {
  const _RejectProposalDialog({
    required this.proposal,
    required this.onRejected,
  });
  final Proposal proposal;
  final VoidCallback onRejected;

  @override
  ConsumerState<_RejectProposalDialog> createState() =>
      _RejectProposalDialogState();
}

class _RejectProposalDialogState extends ConsumerState<_RejectProposalDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Отклонить предложение'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Вы уверены, что хотите отклонить это предложение?'),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Причина отклонения (необязательно)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _rejectProposal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Отклонить'),
          ),
        ],
      );

  Future<void> _rejectProposal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(proposalServiceProvider);
      await service.rejectProposal(
        proposalId: widget.proposal.id,
        customerId: 'current_user_id', // TODO: Получить из контекста
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Предложение отклонено'),
          backgroundColor: Colors.orange,
        ),
      );

      widget.onRejected();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Диалог для выбора специалистов
class _SelectSpecialistsDialog extends ConsumerStatefulWidget {
  const _SelectSpecialistsDialog({
    required this.onSpecialistsSelected,
  });
  final Function(List<ProposalSpecialist>) onSpecialistsSelected;

  @override
  ConsumerState<_SelectSpecialistsDialog> createState() =>
      _SelectSpecialistsDialogState();
}

class _SelectSpecialistsDialogState
    extends ConsumerState<_SelectSpecialistsDialog> {
  final List<ProposalSpecialist> _selectedSpecialists = [];
  final List<String> _selectedCategories = [
    'photographer',
    'videographer',
    'host',
  ]; // TODO: Получить из контекста

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Выбрать специалистов'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Consumer(
            builder: (context, ref, child) => ref
                .watch(specialistsForProposalProvider(_selectedCategories))
                .when(
                  data: (specialists) => ListView.builder(
                    itemCount: specialists.length,
                    itemBuilder: (context, index) {
                      final specialist = specialists[index];
                      final isSelected = _selectedSpecialists
                          .any((s) => s.specialistId == specialist.id);

                      return ListTile(
                        title: Text(specialist.name),
                        subtitle: Text(specialist.categories.join(', ')),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : const Icon(Icons.radio_button_unchecked),
                        onTap: () => _toggleSpecialist(specialist),
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Ошибка: $error'),
                ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _selectedSpecialists.isEmpty
                ? null
                : () {
                    widget.onSpecialistsSelected(_selectedSpecialists);
                    Navigator.pop(context);
                  },
            child: Text('Выбрать (${_selectedSpecialists.length})'),
          ),
        ],
      );

  void _toggleSpecialist(Specialist specialist) {
    setState(() {
      final existingIndex = _selectedSpecialists
          .indexWhere((s) => s.specialistId == specialist.id);

      if (existingIndex != -1) {
        _selectedSpecialists.removeAt(existingIndex);
      } else {
        _selectedSpecialists.add(
          ProposalSpecialist(
            id: specialist.id,
            name: specialist.name,
            price: specialist.min,
            specialistId: specialist.id,
            specialistName: specialist.name,
            categoryId: specialist.categories.first.name,
            categoryName: specialist.categories.first.name,
            estimatedPrice: specialist.min,
          ),
        );
      }
    });
  }
}

/// Провайдер для сервиса предложений
final proposalServiceProvider =
    Provider<ProposalService>((ref) => ProposalService());

/// Провайдер для специалистов для предложения
final specialistsForProposalProvider =
    FutureProvider.family<List<Specialist>, List<String>>(
        (ref, categoryIds) async {
  final service = ref.read(proposalServiceProvider);
  return service.getSpecialistsForProposal(categoryIds: categoryIds);
});
