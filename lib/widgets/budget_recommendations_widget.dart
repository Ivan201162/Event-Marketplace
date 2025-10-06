import 'package:flutter/material.dart';
import '../models/specialist.dart';
import '../services/budget_recommendation_service.dart';

/// Виджет для отображения рекомендаций по увеличению бюджета
class BudgetRecommendationsWidget extends StatefulWidget {
  const BudgetRecommendationsWidget({
    super.key,
    required this.currentBudget,
    required this.selectedSpecialistIds,
    required this.userId,
    this.onBudgetIncrease,
  });

  final double currentBudget;
  final List<String> selectedSpecialistIds;
  final String userId;
  final void Function(double additionalBudget, SpecialistCategory category)?
      onBudgetIncrease;

  @override
  State<BudgetRecommendationsWidget> createState() =>
      _BudgetRecommendationsWidgetState();
}

class _BudgetRecommendationsWidgetState
    extends State<BudgetRecommendationsWidget> {
  final BudgetRecommendationService _service = BudgetRecommendationService();
  List<BudgetRecommendation> _recommendations = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void didUpdateWidget(BudgetRecommendationsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentBudget != widget.currentBudget ||
        oldWidget.selectedSpecialistIds != widget.selectedSpecialistIds) {
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
      final recommendations = await _service.getBudgetRecommendations(
        currentBudget: widget.currentBudget,
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
      return const _BudgetLoadingWidget();
    }

    if (_error != null) {
      return _BudgetErrorWidget(
        error: _error!,
        onRetry: _loadRecommendations,
      );
    }

    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return _BudgetRecommendationsList(
      recommendations: _recommendations,
      onBudgetIncrease: widget.onBudgetIncrease,
      onRecommendationShown: _markAsShown,
    );
  }

  Future<void> _markAsShown(String recommendationId) async {
    try {
      await _service.markBudgetRecommendationAsShown(recommendationId);
    } on Exception catch (e) {
      print('Ошибка отметки рекомендации по бюджету как показанной: $e');
    }
  }
}

/// Виджет загрузки для рекомендаций по бюджету
class _BudgetLoadingWidget extends StatelessWidget {
  const _BudgetLoadingWidget();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Анализируем бюджет...'),
          ],
        ),
      );
}

/// Виджет ошибки для рекомендаций по бюджету
class _BudgetErrorWidget extends StatelessWidget {
  const _BudgetErrorWidget({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ошибка анализа бюджета',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
}

/// Список рекомендаций по бюджету
class _BudgetRecommendationsList extends StatelessWidget {
  const _BudgetRecommendationsList({
    required this.recommendations,
    this.onBudgetIncrease,
    this.onRecommendationShown,
  });

  final List<BudgetRecommendation> recommendations;
  final void Function(double additionalBudget, SpecialistCategory category)?
      onBudgetIncrease;
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
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Предложения по бюджету',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ...recommendations.map(
              (recommendation) => _BudgetRecommendationCard(
                recommendation: recommendation,
                onTap: () {
                  onRecommendationShown?.call(recommendation.id);
                  onBudgetIncrease?.call(
                    recommendation.additionalBudget,
                    recommendation.category,
                  );
                },
              ),
            ),
          ],
        ),
      );
}

/// Карточка рекомендации по бюджету
class _BudgetRecommendationCard extends StatelessWidget {
  const _BudgetRecommendationCard({
    required this.recommendation,
    required this.onTap,
  });

  final BudgetRecommendation recommendation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          elevation: 2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(recommendation.category),
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recommendation.reason,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Категория: ${recommendation.category.displayName}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _BudgetInfo(
                          label: 'Текущий бюджет',
                          amount: recommendation.currentBudget,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BudgetInfo(
                          label: 'Дополнительно',
                          amount: recommendation.additionalBudget,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BudgetInfo(
                          label: 'Итого',
                          amount: recommendation.totalBudget,
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

  IconData _getCategoryIcon(SpecialistCategory category) {
    switch (category) {
      case SpecialistCategory.photographer:
        return Icons.camera_alt;
      case SpecialistCategory.videographer:
        return Icons.videocam;
      case SpecialistCategory.decorator:
        return Icons.palette;
      case SpecialistCategory.lighting:
        return Icons.lightbulb;
      case SpecialistCategory.sound:
        return Icons.volume_up;
      case SpecialistCategory.makeup:
        return Icons.face;
      case SpecialistCategory.stylist:
        return Icons.style;
      case SpecialistCategory.florist:
        return Icons.local_florist;
      default:
        return Icons.person;
    }
  }
}

/// Виджет информации о бюджете
class _BudgetInfo extends StatelessWidget {
  const _BudgetInfo({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${amount.toStringAsFixed(0)} ₽',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}
