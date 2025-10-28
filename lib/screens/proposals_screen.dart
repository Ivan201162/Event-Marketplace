import 'package:event_marketplace_app/models/specialist_proposal.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/services/specialist_proposal_service.dart';
import 'package:event_marketplace_app/widgets/specialist_proposal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран просмотра предложений специалистов
class ProposalsScreen extends ConsumerStatefulWidget {
  const ProposalsScreen({super.key});

  @override
  ConsumerState<ProposalsScreen> createState() => _ProposalsScreenState();
}

class _ProposalsScreenState extends ConsumerState<ProposalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SpecialistProposalService _proposalService =
      SpecialistProposalService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Предложения специалистов'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Активные'),
            Tab(text: 'Принятые'),
            Tab(text: 'Отклоненные'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveProposals(currentUser.value?.uid ?? ''),
          _buildAcceptedProposals(currentUser.value?.uid ?? ''),
          _buildRejectedProposals(currentUser.value?.uid ?? ''),
        ],
      ),
    );
  }

  Widget _buildActiveProposals(String userId) =>
      StreamBuilder<List<SpecialistProposal>>(
        stream: _proposalService.watchCustomerProposals(userId),
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
                      child: const Text('Повторить'),),
                ],
              ),
            );
          }

          final proposals = snapshot.data ?? [];
          final activeProposals = proposals.where((p) => p.isActive).toList();

          if (activeProposals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Нет активных предложений',
                      style: TextStyle(fontSize: 18, color: Colors.grey),),
                  SizedBox(height: 8),
                  Text(
                    'Организаторы могут отправлять вам предложения специалистов',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              itemCount: activeProposals.length,
              itemBuilder: (context, index) {
                final proposal = activeProposals[index];
                return SpecialistProposalCard(
                  proposal: proposal,
                  onAccept: () {
                    setState(() {});
                  },
                  onReject: () {
                    setState(() {});
                  },
                );
              },
            ),
          );
        },
      );

  Widget _buildAcceptedProposals(String userId) =>
      StreamBuilder<List<SpecialistProposal>>(
        stream: _proposalService.watchCustomerProposals(userId),
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
                      child: const Text('Повторить'),),
                ],
              ),
            );
          }

          final proposals = snapshot.data ?? [];
          final acceptedProposals =
              proposals.where((p) => p.isAccepted).toList();

          if (acceptedProposals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.grey,),
                  SizedBox(height: 16),
                  Text('Нет принятых предложений',
                      style: TextStyle(fontSize: 18, color: Colors.grey),),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              itemCount: acceptedProposals.length,
              itemBuilder: (context, index) {
                final proposal = acceptedProposals[index];
                return SpecialistProposalCard(
                  proposal: proposal,
                  onAccept: () {},
                  onReject: () {},
                  showActions: false,
                );
              },
            ),
          );
        },
      );

  Widget _buildRejectedProposals(String userId) =>
      StreamBuilder<List<SpecialistProposal>>(
        stream: _proposalService.watchCustomerProposals(userId),
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
                      child: const Text('Повторить'),),
                ],
              ),
            );
          }

          final proposals = snapshot.data ?? [];
          final rejectedProposals =
              proposals.where((p) => p.isRejected).toList();

          if (rejectedProposals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет отклоненных предложений',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              itemCount: rejectedProposals.length,
              itemBuilder: (context, index) {
                final proposal = rejectedProposals[index];
                return SpecialistProposalCard(
                  proposal: proposal,
                  onAccept: () {},
                  onReject: () {},
                  showActions: false,
                );
              },
            ),
          );
        },
      );
}
