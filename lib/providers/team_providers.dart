import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist_team.dart';
import '../services/team_service.dart';

/// Провайдер сервиса команд
final teamServiceProvider = Provider<TeamService>((ref) => TeamService());

/// Провайдер команды по ID
final teamProvider = StreamProvider.family<SpecialistTeam?, String>((ref, teamId) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.watchTeam(teamId);
});

/// Провайдер команд организатора
final organizerTeamsProvider = StreamProvider.family<List<SpecialistTeam>, String>((
  ref,
  organizerId,
) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.watchOrganizerTeams(organizerId);
});

/// Провайдер команд специалиста
final specialistTeamsProvider = StreamProvider.family<List<SpecialistTeam>, String>((
  ref,
  specialistId,
) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.watchSpecialistTeams(specialistId);
});

/// Провайдер команды по мероприятию
final teamByEventProvider = FutureProvider.family<SpecialistTeam?, String>((ref, eventId) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getTeamByEvent(eventId);
});

/// Провайдер статистики команды
final teamStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, teamId) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getTeamStats(teamId);
});

/// Провайдер для проверки возможности добавления специалиста в команду
final canAddSpecialistProvider = FutureProvider.family<bool, Map<String, String>>((ref, params) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.canAddSpecialistToTeam(
    teamId: params['teamId']!,
    specialistId: params['specialistId']!,
  );
});

/// Провайдер состояния создания команды (мигрирован с StateNotifierProvider)
final teamCreationProvider = NotifierProvider<TeamCreationNotifier, TeamCreationState>(
  () => TeamCreationNotifier(),
);

/// Состояние создания команды
class TeamCreationState {
  const TeamCreationState({this.isLoading = false, this.error, this.createdTeam});

  final bool isLoading;
  final String? error;
  final SpecialistTeam? createdTeam;

  TeamCreationState copyWith({bool? isLoading, String? error, SpecialistTeam? createdTeam}) =>
      TeamCreationState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        createdTeam: createdTeam ?? this.createdTeam,
      );
}

/// Нотификатор для создания команды (мигрирован с StateNotifier)
class TeamCreationNotifier extends Notifier<TeamCreationState> {
  @override
  TeamCreationState build() {
    return const TeamCreationState();
  }

  TeamService get _teamService => ref.read(teamServiceProvider);

  Future<void> createTeam({
    required String organizerId,
    required String eventId,
    String? eventTitle,
    DateTime? eventDate,
    String? eventLocation,
    String? teamName,
    String? description,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final team = await _teamService.createTeam(
        organizerId: organizerId,
        eventId: eventId,
        eventTitle: eventTitle,
        eventDate: eventDate,
        eventLocation: eventLocation,
        teamName: teamName,
        description: description,
        notes: notes,
      );

      state = state.copyWith(isLoading: false, createdTeam: team);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const TeamCreationState();
  }
}

/// Провайдер состояния управления командой (мигрирован с StateNotifierProvider)
final teamManagementProvider = NotifierProvider<TeamManagementNotifier, TeamManagementState>(
  () => TeamManagementNotifier(),
);

/// Состояние управления командой
class TeamManagementState {
  const TeamManagementState({this.isLoading = false, this.error, this.successMessage});

  final bool isLoading;
  final String? error;
  final String? successMessage;

  TeamManagementState copyWith({bool? isLoading, String? error, String? successMessage}) =>
      TeamManagementState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        successMessage: successMessage,
      );
}

/// Нотификатор для управления командой (мигрирован с StateNotifier)
class TeamManagementNotifier extends Notifier<TeamManagementState> {
  @override
  TeamManagementState build() {
    return const TeamManagementState();
  }

  TeamService get _teamService => ref.read(teamServiceProvider);

  Future<void> addSpecialistToTeam({
    required String teamId,
    required String specialistId,
    String? role,
    double? paymentAmount,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _teamService.addSpecialistToTeam(
        teamId: teamId,
        specialistId: specialistId,
        role: role,
        paymentAmount: paymentAmount,
      );

      state = state.copyWith(isLoading: false, successMessage: 'Специалист добавлен в команду');
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeSpecialistFromTeam({
    required String teamId,
    required String specialistId,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _teamService.removeSpecialistFromTeam(teamId: teamId, specialistId: specialistId);

      state = state.copyWith(isLoading: false, successMessage: 'Специалист удален из команды');
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> confirmTeam({required String teamId, String? notes}) async {
    state = state.copyWith(isLoading: true);

    try {
      await _teamService.confirmTeam(teamId: teamId, notes: notes);

      state = state.copyWith(isLoading: false, successMessage: 'Команда подтверждена');
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> rejectTeam({required String teamId, required String reason}) async {
    state = state.copyWith(isLoading: true);

    try {
      await _teamService.rejectTeam(teamId: teamId, reason: reason);

      state = state.copyWith(isLoading: false, successMessage: 'Команда отклонена');
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateTeam({
    required String teamId,
    String? teamName,
    String? description,
    String? notes,
    double? totalPrice,
    Map<String, String>? specialistRoles,
    Map<String, double>? paymentSplit,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _teamService.updateTeam(
        teamId: teamId,
        teamName: teamName,
        description: description,
        notes: notes,
        totalPrice: totalPrice,
        specialistRoles: specialistRoles,
        paymentSplit: paymentSplit,
      );

      state = state.copyWith(isLoading: false, successMessage: 'Команда обновлена');
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearMessages() {
    state = state.copyWith();
  }
}
