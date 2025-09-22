import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../models/recommendation.dart';
import '../models/specialist_recommendation.dart';
import '../services/recommendation_engine.dart';

/// Экран рекомендаций
class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final RecommendationEngine _recommendationEngine = RecommendationEngine();
  final TextEditingController _searchController = TextEditingController();
  List<Recommendation> _recommendations = [];
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentUserId = 'demo_user_id'; // TODO: Получить реальный ID пользователя
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Рекомендации'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Все', icon: Icon(Icons.recommend)),
              Tab(text: 'Специалисты', icon: Icon(Icons.person)),
              Tab(text: 'События', icon: Icon(Icons.event)),
              Tab(text: 'Идеи', icon: Icon(Icons.lightbulb)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshRecommendations,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildAllRecommendations(),
                  _buildRecommendationsByType(RecommendationType.similarSpecialists),
                  _buildRecommendationsByType(RecommendationType.trending),
                  _buildRecommendationsByType(RecommendationType.popularInCategory),
                ],
              ),
      );

  Widget _buildAllRecommendations() {
    if (_recommendations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recommendations.length,
        itemBuilder: (context, index) {
          final recommendation = _recommendations[index];
          return _buildRecommendationCard(recommendation);
        },
      ),
    );
  }

  Widget _buildRecommendationsByType(RecommendationType type) {
    final filteredRecommendations =
        _recommendations.where((rec) => rec.type == type).toList();

    if (filteredRecommendations.isEmpty) {
      return _buildEmptyState(type: type);
    }

    return RefreshIndicator(
      onRefresh: _refreshRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRecommendations.length,
        itemBuilder: (context, index) {
          final recommendation = filteredRecommendations[index];
          return _buildRecommendationCard(recommendation);
        },
      ),
    );
  }

  Widget _buildRecommendationCard(Recommendation recommendation) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: () => _handleRecommendationTap(recommendation),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Изображение
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: recommendation.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            recommendation.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultIcon(recommendation.type),
                          ),
                        )
                      : _buildDefaultIcon(recommendation.type),
                ),
                const SizedBox(width: 16),
                // Контент
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildTypeChip(recommendation.type),
                          const Spacer(),
                          _buildScoreIndicator(recommendation.score),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendation.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (recommendation.metadata.isNotEmpty)
                        _buildMetadata(recommendation.metadata),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildDefaultIcon(RecommendationType type) {
    IconData iconData = Icons.help;
    Color color = Colors.grey;

    switch (type) {
      case RecommendationType.similarSpecialists:
        iconData = Icons.person;
        color = Colors.blue;
        break;
      case RecommendationType.trending:
        iconData = Icons.trending_up;
        color = Colors.green;
        break;
      case RecommendationType.popularInCategory:
        iconData = Icons.lightbulb;
        color = Colors.orange;
        break;
      case RecommendationType.nearby:
        iconData = Icons.location_on;
        color = Colors.purple;
        break;
      case RecommendationType.recentlyViewed:
        iconData = Icons.visibility;
        color = Colors.indigo;
        break;
      case RecommendationType.basedOnHistory:
        iconData = Icons.history;
        color = Colors.teal;
        break;
      case RecommendationType.priceRange:
        iconData = Icons.attach_money;
        color = Colors.green;
        break;
      case RecommendationType.availability:
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
    }

    return Icon(iconData, size: 40, color: color);
  }

  Widget _buildTypeChip(RecommendationType type) {
    String label = 'Неизвестно';
    Color color = Colors.grey;

    switch (type) {
      case RecommendationType.similarSpecialists:
        label = 'Специалист';
        color = Colors.blue;
        break;
      case RecommendationType.trending:
        label = 'Тренды';
        color = Colors.green;
        break;
      case RecommendationType.popularInCategory:
        label = 'Популярное';
        color = Colors.orange;
        break;
      case RecommendationType.nearby:
        label = 'Рядом';
        color = Colors.purple;
        break;
      case RecommendationType.basedOnHistory:
        label = 'На основе истории';
        color = Colors.teal;
        break;
      case RecommendationType.priceRange:
        label = 'В вашем ценовом диапазоне';
        color = Colors.green;
        break;
      case RecommendationType.availability:
        label = 'Доступные сейчас';
        color = Colors.green;
        break;
      case RecommendationType.recentlyViewed:
        label = 'Недавно просмотренные';
        color = Colors.indigo;
        break;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildScoreIndicator(double score) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getScoreColor(score).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getScoreColor(score)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: _getScoreColor(score),
            ),
            const SizedBox(width: 4),
            Text(
              '${(score * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(score),
              ),
            ),
          ],
        ),
      );

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildMetadata(Map<String, dynamic> metadata) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: metadata.entries
            .map(
              (entry) => Chip(
                label: Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: Colors.grey[100],
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
            .toList(),
      );

  Widget _buildEmptyState({RecommendationType? type}) {
    String message = 'Нет рекомендаций';
    IconData icon = Icons.recommend_outlined;

    if (type != null) {
      switch (type) {
        case RecommendationType.similarSpecialists:
          message = 'Нет рекомендаций специалистов';
          icon = Icons.person_off;
          break;
        case RecommendationType.trending:
          message = 'Нет трендовых рекомендаций';
          icon = Icons.trending_flat;
          break;
        case RecommendationType.popularInCategory:
          message = 'Нет популярных рекомендаций';
          icon = Icons.lightbulb_outline;
          break;
        case RecommendationType.nearby:
          message = 'Нет рекомендаций рядом';
          icon = Icons.location_off;
          break;
      case RecommendationType.basedOnHistory:
        message = 'Нет рекомендаций на основе истории';
        icon = Icons.history_edu;
        break;
      case RecommendationType.priceRange:
        message = 'Нет рекомендаций в вашем ценовом диапазоне';
        icon = Icons.attach_money;
        break;
      case RecommendationType.availability:
        message = 'Нет доступных сейчас специалистов';
        icon = Icons.check_circle_outline;
        break;
        case RecommendationType.recentlyViewed:
          message = 'Нет недавно просмотренных';
          icon = Icons.visibility_off;
          break;
      }
    } else {
      message = 'Нет рекомендаций';
      icon = Icons.recommend_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshRecommendations,
            child: const Text('Обновить'),
          ),
        ],
      ),
    );
  }

  void _handleRecommendationTap(Recommendation recommendation) {
    switch (recommendation.type) {
      case RecommendationType.similarSpecialists:
        _showSpecialistDetails(recommendation);
        break;
      case RecommendationType.trending:
        _showEventDetails(recommendation);
        break;
      case RecommendationType.popularInCategory:
        _showIdeaDetails(recommendation);
        break;
      case RecommendationType.nearby:
        _showCategoryDetails(recommendation);
        break;
      case RecommendationType.recentlyViewed:
        _showRecentlyViewedDetails(recommendation);
        break;
      case RecommendationType.basedOnHistory:
        _showHistoryBasedDetails(recommendation);
        break;
      case RecommendationType.priceRange:
        _showPriceRangeDetails(recommendation);
        break;
      case RecommendationType.availability:
        _showAvailabilityDetails(recommendation);
        break;
    }
  }

  void _showSpecialistDetails(Recommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recommendation.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recommendation.description),
            const SizedBox(height: 16),
            if (recommendation.metadata['rating'] != null)
              Text('Рейтинг: ${recommendation.metadata['rating']}'),
            if (recommendation.metadata['orderCount'] != null)
              Text('Заказов: ${recommendation.metadata['orderCount']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Перейти к профилю специалиста
            },
            child: const Text('Посмотреть профиль'),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(Recommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recommendation.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recommendation.description),
            const SizedBox(height: 16),
            if (recommendation.metadata['date'] != null)
              Text('Дата: ${recommendation.metadata['date']}'),
            if (recommendation.metadata['price'] != null)
              Text('Цена: ${recommendation.metadata['price']} ₽'),
            if (recommendation.metadata['location'] != null)
              Text('Место: ${recommendation.metadata['location']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Перейти к событию
            },
            child: const Text('Посмотреть событие'),
          ),
        ],
      ),
    );
  }

  void _showIdeaDetails(Recommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recommendation.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recommendation.description),
            const SizedBox(height: 16),
            if (recommendation.metadata['authorName'] != null)
              Text('Автор: ${recommendation.metadata['authorName']}'),
            if (recommendation.metadata['likesCount'] != null)
              Text('Лайков: ${recommendation.metadata['likesCount']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Перейти к идее
            },
            child: const Text('Посмотреть идею'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDetails(Recommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recommendation.title),
        content: Text(recommendation.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Перейти к категории
            },
            child: const Text('Посмотреть категорию'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRecommendations() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final params = {
        'userId': _currentUserId!,
        'limit': 50,
      };
      final recommendations =
          await _recommendationEngine.getRecommendations(userId: _currentUserId!);

      setState(() {
        _recommendations = recommendations.map((rec) => rec.recommendation).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки рекомендаций: $e')),
        );
      }
    }
  }

  void _showRecentlyViewedDetails(Recommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recommendation.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recommendation.description),
            const SizedBox(height: 8),
            if (recommendation.metadata['viewedAt'] != null)
              Text('Просмотрено: ${recommendation.metadata['viewedAt']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showHistoryBasedDetails(Recommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recommendation.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recommendation.description),
            const SizedBox(height: 8),
            if (recommendation.metadata['historyType'] != null)
              Text('Тип истории: ${recommendation.metadata['historyType']}'),
            if (recommendation.metadata['confidence'] != null)
              Text('Уверенность: ${recommendation.metadata['confidence']}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showPriceRangeDetails(Recommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recommendation.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recommendation.description),
            const SizedBox(height: 8),
            if (recommendation.metadata['minPrice'] != null)
              Text('Мин. цена: ${recommendation.metadata['minPrice']} ₽'),
            if (recommendation.metadata['maxPrice'] != null)
              Text('Макс. цена: ${recommendation.metadata['maxPrice']} ₽'),
            if (recommendation.metadata['averagePrice'] != null)
              Text('Средняя цена: ${recommendation.metadata['averagePrice']} ₽'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showAvailabilityDetails(Recommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recommendation.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recommendation.description),
            const SizedBox(height: 8),
            if (recommendation.metadata['availableUntil'] != null)
              Text('Доступен до: ${recommendation.metadata['availableUntil']}'),
            if (recommendation.metadata['responseTime'] != null)
              Text('Время ответа: ${recommendation.metadata['responseTime']}'),
            if (recommendation.metadata['isOnline'] != null)
              Text('Статус: ${recommendation.metadata['isOnline'] ? 'Онлайн' : 'Офлайн'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshRecommendations() async {
    await _loadRecommendations();
  }
}
