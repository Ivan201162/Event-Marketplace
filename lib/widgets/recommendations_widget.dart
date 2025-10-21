import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_activity.dart';
import '../services/recommendation_service.dart';

/// Виджет рекомендаций для главной страницы
class RecommendationsWidget extends ConsumerStatefulWidget {
  const RecommendationsWidget({super.key, required this.userId, this.onSpecialistTap});
  final String userId;
  final VoidCallback? onSpecialistTap;

  @override
  ConsumerState<RecommendationsWidget> createState() => _RecommendationsWidgetState();
}

class _RecommendationsWidgetState extends ConsumerState<RecommendationsWidget>
    with TickerProviderStateMixin {
  final RecommendationService _recommendationService = RecommendationService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Recommendation> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _loadRecommendations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    try {
      final recommendations = await _recommendationService.getRecommendations(widget.userId);
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
      unawaited(_animationController.forward());
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Ошибка загрузки рекомендаций: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_recommendations.isEmpty) {
      return _buildEmptyWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amber.shade600, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Рекомендации для вас',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _loadRecommendations,
                    child: Text(
                      'Обновить',
                      style: TextStyle(color: Colors.amber.shade600, fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Список рекомендаций
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recommendations.length,
                  itemBuilder: (context, index) =>
                      _buildRecommendationCard(_recommendations[index], index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber.shade600, size: 24),
            const SizedBox(width: 8),
            Text(
              'Рекомендации для вас',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) => Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              child: Card(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(8), child: Text('Загрузка...')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildEmptyWidget() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber.shade600, size: 24),
            const SizedBox(width: 8),
            Text(
              'Рекомендации для вас',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore, size: 32, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'Изучите специалистов',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'чтобы получить персональные рекомендации',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildRecommendationCard(Recommendation recommendation, int index) => AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) {
      final delay = index * 0.1;
      final animationValue = (_animationController.value - delay).clamp(0.0, 1.0);

      return Transform.translate(
        offset: Offset(0, 20 * (1 - animationValue)),
        child: Opacity(
          opacity: animationValue,
          child: Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                  widget.onSpecialistTap?.call();
                  // TODO(developer): Переход к профилю специалиста
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Фото специалиста
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          gradient: LinearGradient(
                            colors: [Colors.amber.shade100, Colors.amber.shade200],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: recommendation.photoUrl != null
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  recommendation.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(),
                                ),
                              )
                            : _buildDefaultAvatar(),
                      ),
                    ),

                    // Информация о специалисте
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recommendation.specialistName,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              recommendation.city,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, size: 12, color: Colors.amber.shade600),
                                const SizedBox(width: 2),
                                Text(
                                  recommendation.rating.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${recommendation.price.toInt()}₽',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Индикатор уверенности
                    Container(
                      height: 3,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: recommendation.confidence / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade400, Colors.amber.shade600],
                            ),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _buildDefaultAvatar() => Container(
    decoration: BoxDecoration(
      color: Colors.amber.shade100,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    ),
    child: Center(child: Icon(Icons.person, size: 40, color: Colors.amber.shade600)),
  );
}

/// Виджет для отображения причины рекомендации
class RecommendationReasonWidget extends StatelessWidget {
  const RecommendationReasonWidget({super.key, required this.reason, required this.confidence});
  final String reason;
  final double confidence;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.amber.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.amber.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            reason,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.amber.shade800, fontSize: 11),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${confidence.toInt()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.amber.shade800,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
