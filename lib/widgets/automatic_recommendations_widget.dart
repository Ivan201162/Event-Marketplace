import 'package:flutter/material.dart';
import '../models/specialist.dart';
import '../services/automatic_recommendation_service.dart';

/// Виджет для отображения автоматических рекомендаций
class AutomaticRecommendationsWidget extends StatefulWidget {
  const AutomaticRecommendationsWidget({
    super.key,
    required this.selectedSpecialistIds,
    required this.userId,
    this.onSpecialistSelected,
  });

  final List<String> selectedSpecialistIds;
  final String userId;
  final void Function(Specialist)? onSpecialistSelected;

  @override
  State<AutomaticRecommendationsWidget> createState() => _AutomaticRecommendationsWidgetState();
}

class _AutomaticRecommendationsWidgetState extends State<AutomaticRecommendationsWidget> {
  final AutomaticRecommendationService _service = AutomaticRecommendationService();
  List<SpecialistRecommendation> _recommendations = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void didUpdateWidget(AutomaticRecommendationsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSpecialistIds != widget.selectedSpecialistIds) {
      _loadRecommendations();
    }
  }

  Future<void> _loadRecommendations() async {
    if (widget.selectedSpecialistIds.isEmpty) {
      setState(() {
        _recommendations = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final recommendations = await _service.getRecommendationsForSelectedSpecialists(
        selectedSpecialistIds: widget.selectedSpecialistIds,
        userId: widget.userId,
      );

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedSpecialistIds.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const _LoadingWidget();
    }

    if (_error != null) {
      return _ErrorWidget(error: _error!, onRetry: _loadRecommendations);
    }

    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return _RecommendationsList(
      recommendations: _recommendations,
      onSpecialistSelected: widget.onSpecialistSelected,
      onRecommendationShown: _markAsShown,
    );
  }

  Future<void> _markAsShown(String recommendationId) async {
    try {
      await _service.markRecommendationAsShown(recommendationId);
    } on Exception catch (e) {
      print('Ошибка отметки рекомендации как показанной: $e');
    }
  }
}

/// Виджет загрузки
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Загружаем рекомендации...'),
          ],
        ),
      );
}

/// Виджет ошибки
class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ошибка загрузки рекомендаций',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      );
}

/// Список рекомендаций
class _RecommendationsList extends StatelessWidget {
  const _RecommendationsList({
    required this.recommendations,
    this.onSpecialistSelected,
    this.onRecommendationShown,
  });

  final List<SpecialistRecommendation> recommendations;
  final void Function(Specialist)? onSpecialistSelected;
  final void Function(String)? onRecommendationShown;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Рекомендуем добавить...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final recommendation = recommendations[index];
                  return _RecommendationCard(
                    recommendation: recommendation,
                    onTap: () {
                      onRecommendationShown?.call(recommendation.id);
                      onSpecialistSelected?.call(recommendation.specialist);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
}

/// Карточка рекомендации
class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation, required this.onTap});

  final SpecialistRecommendation recommendation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: recommendation.specialist.avatarUrl != null
                            ? NetworkImage(recommendation.specialist.avatarUrl!)
                            : null,
                        child: recommendation.specialist.avatarUrl == null
                            ? Text(
                                recommendation.specialist.name.isNotEmpty
                                    ? recommendation.specialist.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendation.specialist.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommendation.reason,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber[600]),
                      const SizedBox(width: 4),
                      Text(
                        recommendation.specialist.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${recommendation.specialist.price.toStringAsFixed(0)} ₽',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
