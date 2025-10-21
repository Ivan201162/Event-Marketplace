import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist_proposal.dart';
import '../services/specialist_proposal_service.dart';

/// Сервис предложений специалистов
final specialistProposalServiceProvider = Provider<SpecialistProposalService>(
  (ref) => SpecialistProposalService(),
);

/// Провайдер для создания предложения
final createProposalProvider = FutureProvider.family<SpecialistProposal, CreateSpecialistProposal>((
  ref,
  params,
) async {
  final service = ref.read(specialistProposalServiceProvider);
  return service.createProposal(params);
});

/// Провайдер для получения предложений клиента
final customerProposalsProvider = StreamProvider.family<List<SpecialistProposal>, String>((
  ref,
  customerId,
) {
  final service = ref.read(specialistProposalServiceProvider);
  return service.watchCustomerProposals(customerId);
});

/// Провайдер для получения предложений организатора
final organizerProposalsProvider = StreamProvider.family<List<SpecialistProposal>, String>((
  ref,
  organizerId,
) {
  final service = ref.read(specialistProposalServiceProvider);
  return service.watchOrganizerProposals(organizerId);
});

/// Провайдер для получения активных предложений клиента
final activeCustomerProposalsProvider = FutureProvider.family<List<SpecialistProposal>, String>((
  ref,
  customerId,
) async {
  final service = ref.read(specialistProposalServiceProvider);
  return service.getActiveCustomerProposals(customerId);
});

/// Провайдер для получения предложения по ID
final proposalProvider = FutureProvider.family<SpecialistProposal?, String>((
  ref,
  proposalId,
) async {
  final service = ref.read(specialistProposalServiceProvider);
  return service.getProposal(proposalId);
});

/// Провайдер для принятия предложения
final acceptProposalProvider = FutureProvider.family<void, AcceptProposalParams>((
  ref,
  params,
) async {
  final service = ref.read(specialistProposalServiceProvider);
  return service.acceptProposal(params.proposalId, params.specialistId);
});

/// Провайдер для отклонения предложения
final rejectProposalProvider = FutureProvider.family<void, String>((ref, proposalId) async {
  final service = ref.read(specialistProposalServiceProvider);
  return service.rejectProposal(proposalId);
});

/// Провайдер для удаления предложения
final deleteProposalProvider = FutureProvider.family<void, String>((ref, proposalId) async {
  final service = ref.read(specialistProposalServiceProvider);
  return service.deleteProposal(proposalId);
});

/// Провайдер для получения статистики организатора
final organizerStatsProvider = FutureProvider.family<Map<String, int>, String>((
  ref,
  organizerId,
) async {
  final service = ref.read(specialistProposalServiceProvider);
  return service.getOrganizerStats(organizerId);
});

/// Параметры для принятия предложения
class AcceptProposalParams {
  const AcceptProposalParams({required this.proposalId, required this.specialistId});

  final String proposalId;
  final String specialistId;
}
