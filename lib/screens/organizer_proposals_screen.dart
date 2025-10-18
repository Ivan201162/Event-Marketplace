import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/specialist.dart';
import 'package:flutter/foundation.dart';
import '../models/specialist_proposal.dart';
import 'package:flutter/foundation.dart';
import '../services/proposal_service.dart';
import 'package:flutter/foundation.dart';
import '../services/specialist_service.dart';
import 'package:flutter/foundation.dart';
import '../widgets/error_widget.dart';
import 'package:flutter/foundation.dart';
import '../widgets/loading_widget.dart';
import 'package:flutter/foundation.dart';

class OrganizerProposalsScreen extends StatefulWidget {
  const OrganizerProposalsScreen({super.key});

  @override
  State<OrganizerProposalsScreen> createState() => _OrganizerProposalsScreenState();
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
        body: Center(
          child: Text('РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ РЅРµ Р°РІС‚РѕСЂРёР·РѕРІР°РЅ'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('РњРѕРё РїСЂРµРґР»РѕР¶РµРЅРёСЏ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'РћР¶РёРґР°СЋС‚ РѕС‚РІРµС‚Р°', icon: Icon(Icons.pending)),
            Tab(text: 'РџСЂРёРЅСЏС‚С‹Рµ', icon: Icon(Icons.check_circle)),
            Tab(text: 'РћС‚РєР»РѕРЅРµРЅРЅС‹Рµ', icon: Icon(Icons.cancel)),
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

  Widget _buildProposalsList(String status) => StreamBuilder<List<SpecialistProposal>>(
        stream: ProposalService.getProposalsByStatus(
          _currentUserId!,
          status,
          isCustomer: false,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return CustomErrorWidget(
              error: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          final proposals = snapshot.data ?? [];

          if (proposals.isEmpty) {
            return _buildEmptyState(status);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: proposals.length,
            itemBuilder: (context, index) => _buildProposalCard(proposals[index]),
          );
        },
      );

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status) {
      case 'pending':
        message = 'РќРµС‚ РїСЂРµРґР»РѕР¶РµРЅРёР№, РѕР¶РёРґР°СЋС‰РёС… РѕС‚РІРµС‚Р°';
        icon = Icons.pending_actions;
        break;
      case 'accepted':
        message = 'РќРµС‚ РїСЂРёРЅСЏС‚С‹С… РїСЂРµРґР»РѕР¶РµРЅРёР№';
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        message = 'РќРµС‚ РѕС‚РєР»РѕРЅРµРЅРЅС‹С… РїСЂРµРґР»РѕР¶РµРЅРёР№';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'РќРµС‚ РїСЂРµРґР»РѕР¶РµРЅРёР№';
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
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
                    child: Icon(
                      _getStatusIcon(proposal.status),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'РџСЂРµРґР»РѕР¶РµРЅРёРµ РґР»СЏ Р·Р°РєР°Р·С‡РёРєР°',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'РЎРѕР±С‹С‚РёРµ: ${proposal.eventId}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'РЎРѕР·РґР°РЅРѕ: ${_formatDate(proposal.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (proposal.updatedAt != null)
                          Text(
                            'РћР±РЅРѕРІР»РµРЅРѕ: ${_formatDate(proposal.updatedAt!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(proposal.statusDisplayName),
                    backgroundColor: _getStatusColor(proposal.status).withValues(alpha: 0.2),
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
                  child: Text(
                    proposal.message!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'РЎРїРµС†РёР°Р»РёСЃС‚С‹ (${proposal.specialistIds.length}):',
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
                      label: const Text('РџРѕРґСЂРѕР±РЅРµРµ'),
                    ),
                  ),
                  if (proposal.isPending) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editProposal(proposal),
                        icon: const Icon(Icons.edit),
                        label: const Text('РР·РјРµРЅРёС‚СЊ'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildSpecialistsList(List<String> specialistIds) => FutureBuilder<List<Specialist>>(
        future: _getSpecialists(specialistIds),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Text(
              'РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: ${snapshot.error}',
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
                      backgroundImage:
                          specialist.photoUrl != null ? NetworkImage(specialist.photoUrl!) : null,
                      child: specialist.photoUrl == null
                          ? Text(
                              specialist.name.isNotEmpty ? specialist.name[0] : '?',
                            )
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
        debugPrint('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё СЃРїРµС†РёР°Р»РёСЃС‚Р° $id: $e');
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
        title: const Text('Р”РµС‚Р°Р»Рё РїСЂРµРґР»РѕР¶РµРЅРёСЏ'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', proposal.id),
              _buildDetailRow('Р—Р°РєР°Р·С‡РёРє', proposal.customerId),
              _buildDetailRow('РЎРѕР±С‹С‚РёРµ', proposal.eventId),
              _buildDetailRow('РЎС‚Р°С‚СѓСЃ', proposal.statusDisplayName),
              _buildDetailRow('РЎРѕР·РґР°РЅРѕ', _formatDate(proposal.createdAt)),
              if (proposal.updatedAt != null)
                _buildDetailRow('РћР±РЅРѕРІР»РµРЅРѕ', _formatDate(proposal.updatedAt!)),
              if (proposal.message != null) _buildDetailRow('РЎРѕРѕР±С‰РµРЅРёРµ', proposal.message!),
              const SizedBox(height: 8),
              Text(
                'РЎРїРµС†РёР°Р»РёСЃС‚С‹:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ...proposal.specialistIds.map((id) => Text('вЂў $id')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Р—Р°РєСЂС‹С‚СЊ'),
          ),
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
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(value),
            ),
          ],
        ),
      );

  void _editProposal(SpecialistProposal proposal) {
    // РќР°РІРёРіР°С†РёСЏ Рє СЌРєСЂР°РЅСѓ СЂРµРґР°РєС‚РёСЂРѕРІР°РЅРёСЏ РїСЂРµРґР»РѕР¶РµРЅРёСЏ
    Navigator.pushNamed(
      context,
      '/edit-proposal',
      arguments: proposal,
    );
  }
}

