import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/specialist.dart';
import '../models/specialist_proposal.dart';
import '../services/proposal_service.dart';
import '../services/specialist_service.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';

class OrganizerProposalsScreen extends StatefulWidget {
  const OrganizerProposalsScreen({super.key});

  @override
  State<OrganizerProposalsScreen> createState() =>
      _OrganizerProposalsScreenState();
}

class _OrganizerProposalsScreenState extends State<OrganizerProposalsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUserId = _auth.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
          body: Center(child: Text('Пользователь не авторизован')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои предложения'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ожидают ответа', icon: Icon(Icons.pending)),
            Tab(text: 'Принятые', icon: Icon(Icons.check_circle)),
            Tab(text: 'Отклоненные', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProposalsList('pending'),
          _buildProposalsList('accepted'),
          _buildProposalsList('rejected'),
        ],
      ),
    );
  }

  Widget _buildProposalsList(String status) =>
      StreamBuilder<List<SpecialistProposal>>(
        stream: ProposalService.getProposalsByStatus(_currentUserId!, status,
            isCustomer: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return CustomErrorWidget(
                error: snapshot.error.toString(),
                onRetry: () => setState(() {}));
          }

          final proposals = snapshot.data ?? [];

          if (proposals.isEmpty) {
            return _buildEmptyState(status);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: proposals.length,
            itemBuilder: (context, index) =>
                _buildProposalCard(proposals[index]),
          );
        },
      );

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status) {
      case 'pending':
        message = 'Нет предложений, ожидающих ответа';
        icon = Icons.pending_actions;
        break;
      case 'accepted':
        message = 'Нет принятых предложений';
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        message = 'Нет отклоненных предложений';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'Нет предложений';
        icon = Icons.inbox;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(SpecialistProposal proposal) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(proposal.status),
                    child: Icon(_getStatusIcon(proposal.status),
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Предложение для заказчика',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Событие: ${proposal.eventId}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Создано: ${_formatDate(proposal.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (proposal.updatedAt != null)
                          Text(
                            'Обновлено: ${_formatDate(proposal.updatedAt!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(proposal.statusDisplayName),
                    backgroundColor:
                        _getStatusColor(proposal.status).withValues(alpha: 0.2),
                  ),
                ],
              ),
              if (proposal.message != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(proposal.message!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Специалисты (${proposal.specialistIds.length}):',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildSpecialistsList(proposal.specialistIds),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewProposalDetails(proposal),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Подробнее'),
                    ),
                  ),
                  if (proposal.isPending) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editProposal(proposal),
                        icon: const Icon(Icons.edit),
                        label: const Text('Изменить'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildSpecialistsList(List<String> specialistIds) =>
      FutureBuilder<List<Specialist>>(
        future: _getSpecialists(specialistIds),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
                height: 60, child: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasError) {
            return Text(
              'Ошибка загрузки специалистов: ${snapshot.error}',
              style: TextStyle(color: Colors.red[600]),
            );
          }

          final specialists = snapshot.data ?? [];

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specialists
                .map(
                  (specialist) => Chip(
                    avatar: CircleAvatar(
                      backgroundImage: specialist.photoUrl != null
                          ? NetworkImage(specialist.photoUrl!)
                          : null,
                      child: specialist.photoUrl == null
                          ? Text(specialist.name.isNotEmpty
                              ? specialist.name[0]
                              : '?')
                          : null,
                    ),
                    label: Text(specialist.name),
                    backgroundColor: Colors.blue[50],
                  ),
                )
                .toList(),
          );
        },
      );

  Future<List<Specialist>> _getSpecialists(List<String> specialistIds) async {
    final specialists = <Specialist>[];
    for (final id in specialistIds) {
      try {
        final specialist = await SpecialistService.getSpecialist(id);
        if (specialist != null) {
          specialists.add(specialist);
        }
      } on Exception catch (e) {
        debugPrint('Ошибка загрузки специалиста $id: $e');
      }
    }
    return specialists;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check;
      case 'rejected':
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

  void _viewProposalDetails(SpecialistProposal proposal) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Детали предложения'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', proposal.id),
              _buildDetailRow('Заказчик', proposal.customerId),
              _buildDetailRow('Событие', proposal.eventId),
              _buildDetailRow('Статус', proposal.statusDisplayName),
              _buildDetailRow('Создано', _formatDate(proposal.createdAt)),
              if (proposal.updatedAt != null)
                _buildDetailRow('Обновлено', _formatDate(proposal.updatedAt!)),
              if (proposal.message != null)
                _buildDetailRow('Сообщение', proposal.message!),
              const SizedBox(height: 8),
              Text('Специалисты:',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              ...proposal.specialistIds.map((id) => Text('• $id')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  void _editProposal(SpecialistProposal proposal) {
    // Навигация к экрану редактирования предложения
    Navigator.pushNamed(context, '/edit-proposal', arguments: proposal);
  }
}
