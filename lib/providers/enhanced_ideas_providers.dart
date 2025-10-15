import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enhanced_idea.dart';
// import '../test_data/mock_data.dart';

/// Состояние идей
class EnhancedIdeasState {

  const EnhancedIdeasState({
    this.ideas = const [],
    this.isLoading = false,
    this.error,
  });
  final List<EnhancedIdea> ideas;
  final bool isLoading;
  final String? error;

  EnhancedIdeasState copyWith({
    List<EnhancedIdea>? ideas,
    bool? isLoading,
    String? error,
  }) =>
      EnhancedIdeasState(
        ideas: ideas ?? this.ideas,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

/// Провайдер для управления состоянием идей
class EnhancedIdeasNotifier extends ChangeNotifier {
  EnhancedIdeasNotifier() {
    _loadIdeas();
  }
  
  EnhancedIdeasState _state = const EnhancedIdeasState();
  
  EnhancedIdeasState get state => _state;

  Future<void> _loadIdeas() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    try {
      // Имитируем задержку сети
      await Future.delayed(const Duration(seconds: 1));

      // Загружаем тестовые данные
      // final ideas = MockData.ideas;
      final ideas = <EnhancedIdea>[];
      _state = _state.copyWith(ideas: ideas, isLoading: false);
    } catch (e) {
      _state = _state.copyWith(isLoading: false, error: e.toString());
    }
    notifyListeners();
  }

  Future<void> refreshIdeas() async {
    await _loadIdeas();
  }

  void toggleLike(String ideaId) {
    final ideas = _state.ideas.map((idea) {
      if (idea.id == ideaId) {
        return idea.copyWith(
          likesCount: idea.isLiked ? idea.likesCount - 1 : idea.likesCount + 1,
          isLiked: !idea.isLiked,
        );
      }
      return idea;
    }).toList();
    _state = _state.copyWith(ideas: ideas);
    notifyListeners();
  }

  void toggleSave(String ideaId) {
    final ideas = _state.ideas.map((idea) {
      if (idea.id == ideaId) {
        return idea.copyWith(isSaved: !idea.isSaved);
      }
      return idea;
    }).toList();
    _state = _state.copyWith(ideas: ideas);
    notifyListeners();
  }

  void addIdea(EnhancedIdea idea) {
    final ideas = [idea, ..._state.ideas];
    _state = _state.copyWith(ideas: ideas);
    notifyListeners();
  }
}

final enhancedIdeasProvider = Provider<EnhancedIdeasNotifier>((ref) => EnhancedIdeasNotifier());
