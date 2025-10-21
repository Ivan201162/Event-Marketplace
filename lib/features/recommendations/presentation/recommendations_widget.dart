import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../specialists/data/models/specialist.dart';
import '../../specialists/presentation/specialist_card.dart';
import '../recommendation_service.dart';

/// Виджет рекомендаций специалистов
class RecommendationsWidget extends StatefulWidget {
  const RecommendationsWidget({
    super.key,
    this.city,
    this.category,
    this.budget,
    this.limit = 10,
  });
  final String? city;
  final String? category;
  final double? budget;
  final int limit;

  @override
  State<RecommendationsWidget> createState() => _RecommendationsWidgetState();
}

class _RecommendationsWidgetState extends State<RecommendationsWidget> {
  final RecommendationService _recommendationService = RecommendationService();
  List<Specialist> _recommendations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void didUpdateWidget(RecommendationsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city ||
        oldWidget.category != widget.category ||
        oldWidget.budget != widget.budget) {
      _loadRecommendations();
    }
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Добавить провайдер для аутентификации
      // final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // if (authProvider.user == null) {
      setState(() {
        _isLoading = false;
        _error = 'Пользователь не авторизован';
      });
      // return;
      // }

      final recommendations = await _recommendationService.getRecommendations(
        customerId: 'current_user', // TODO: Получить реальный ID пользователя
        city: widget.city,
        category: widget.category,
        budget: widget.budget,
        limit: widget.limit,
      );

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_recommendations.isEmpty) {
      return _buildEmptyState();
    }

    return _buildRecommendationsList();
  }

  /// Состояние загрузки
  Widget _buildLoadingState() => const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );

  /// Состояние ошибки
  Widget _buildErrorState() => SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.grey[400],
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки рекомендаций',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRecommendations,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );

  /// Пустое состояние
  Widget _buildEmptyState() => SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                color: Colors.grey[400],
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Рекомендации не найдены',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Попробуйте изменить фильтры поиска',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  /// Список рекомендаций
  Widget _buildRecommendationsList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.recommend,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Рекомендуем',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showAllRecommendations,
                  child: const Text('Все'),
                ),
              ],
            ),
          ),

          // Горизонтальный список
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final specialist = _recommendations[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 16),
                  child: SpecialistCard(
                    specialist: specialist,
                    showRecommendationBadge: true,
                    onTap: () => _navigateToSpecialist(specialist),
                  ),
                );
              },
            ),
          ),
        ],
      );

  /// Показать все рекомендации
  void _showAllRecommendations() {
    // Здесь можно открыть экран со всеми рекомендациями
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Заголовок
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.recommend,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Рекомендуемые специалисты',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Список
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recommendations.length,
                  itemBuilder: (context, index) {
                    final specialist = _recommendations[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: SpecialistCard(
                        specialist: specialist,
                        showRecommendationBadge: true,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToSpecialist(specialist);
                        },
                      ),
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

  /// Переход к профилю специалиста
  void _navigateToSpecialist(Specialist specialist) {
    // Здесь должна быть навигация к профилю специалиста
    // Navigator.push(context, MaterialPageRoute<void>(...));
  }
}

/// Виджет похожих специалистов
class SimilarSpecialistsWidget extends StatefulWidget {
  const SimilarSpecialistsWidget({
    super.key,
    required this.specialistId,
    this.limit = 5,
  });
  final String specialistId;
  final int limit;

  @override
  State<SimilarSpecialistsWidget> createState() => _SimilarSpecialistsWidgetState();
}

class _SimilarSpecialistsWidgetState extends State<SimilarSpecialistsWidget> {
  final RecommendationService _recommendationService = RecommendationService();
  List<Specialist> _similarSpecialists = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSimilarSpecialists();
  }

  Future<void> _loadSimilarSpecialists() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final similarSpecialists = await _recommendationService.getSimilarSpecialists(
        specialistId: widget.specialistId,
        limit: widget.limit,
      );

      if (mounted) {
        setState(() {
          _similarSpecialists = similarSpecialists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null || _similarSpecialists.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.people,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Похожие специалисты',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),

        // Горизонтальный список
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _similarSpecialists.length,
            itemBuilder: (context, index) {
              final specialist = _similarSpecialists[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                child: SpecialistCard(
                  specialist: specialist,
                  compact: true,
                  onTap: () => _navigateToSpecialist(specialist),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Состояние загрузки
  Widget _buildLoadingState() => const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );

  /// Переход к профилю специалиста
  void _navigateToSpecialist(Specialist specialist) {
    // Здесь должна быть навигация к профилю специалиста
    // Navigator.push(context, MaterialPageRoute<void>(...));
  }
}
