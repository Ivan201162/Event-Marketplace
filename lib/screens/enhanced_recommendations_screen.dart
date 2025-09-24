import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/specialist.dart';
import '../models/specialist_recommendation.dart';
import '../services/enhanced_recommendation_service.dart';
import '../widgets/specialist_card.dart';
import '../widgets/budget_enhancement_card.dart';
import '../core/constants/app_routes.dart';

/// Экран улучшенных рекомендаций с связанными специалистами и предложениями по бюджету
class EnhancedRecommendationsScreen extends StatefulWidget {
  const EnhancedRecommendationsScreen({
    super.key,
    this.selectedSpecialistIds = const [],
    this.currentBudget,
  });

  final List<String> selectedSpecialistIds;
  final double? currentBudget;

  @override
  State<EnhancedRecommendationsScreen> createState() => _EnhancedRecommendationsScreenState();
}

class _EnhancedRecommendationsScreenState extends State<EnhancedRecommendationsScreen>
    with TickerProviderStateMixin {
  final EnhancedRecommendationService _recommendationService = EnhancedRecommendationService();
  
  late TabController _tabController;
  
  List<SpecialistRecommendation> _relatedRecommendations = [];
  List<BudgetEnhancementRecommendation> _budgetRecommendations = [];
  bool _isLoading = true;
  String _customerId = 'current_user_id'; // TODO: Get from auth

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    
    try {
      final futures = await Future.wait([
        _recommendationService.getRelatedSpecialistRecommendations(
          selectedSpecialistIds: widget.selectedSpecialistIds,
          customerId: _customerId,
          budget: widget.currentBudget,
        ),
        _recommendationService.getBudgetEnhancementRecommendations(
          customerId: _customerId,
          currentBudget: widget.currentBudget ?? 50000,
          selectedSpecialistIds: widget.selectedSpecialistIds,
        ),
      ]);

      setState(() {
        _relatedRecommendations = futures[0] as List<SpecialistRecommendation>;
        _budgetRecommendations = futures[1] as List<BudgetEnhancementRecommendation>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки рекомендаций: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рекомендации'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Связанные специалисты',
            ),
            Tab(
              icon: Icon(Icons.trending_up),
              text: 'Улучшения бюджета',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRelatedSpecialistsTab(),
                _buildBudgetEnhancementsTab(),
              ],
            ),
    );
  }

  Widget _buildRelatedSpecialistsTab() {
    if (_relatedRecommendations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Нет рекомендаций связанных специалистов',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Выберите специалистов для получения рекомендаций',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _relatedRecommendations.length,
        itemBuilder: (context, index) {
          final recommendation = _relatedRecommendations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Рекомендация',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(recommendation.score * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommendation.reason,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SpecialistCard(
                    specialist: recommendation.specialist,
                    onTap: () => _onSpecialistTap(recommendation.specialist),
                    showAddButton: true,
                    onAddPressed: () => _onAddSpecialist(recommendation.specialist),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBudgetEnhancementsTab() {
    if (_budgetRecommendations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Нет предложений по улучшению бюджета',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Выберите специалистов для получения предложений',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _budgetRecommendations.length,
        itemBuilder: (context, index) {
          final recommendation = _budgetRecommendations[index];
          return BudgetEnhancementCard(
            recommendation: recommendation,
            onTap: () => _onBudgetEnhancementTap(recommendation),
            onAddSpecialist: (specialist) => _onAddSpecialist(specialist),
          );
        },
      ),
    );
  }

  void _onSpecialistTap(Specialist specialist) {
    context.push('${AppRoutes.specialistDetails}/${specialist.id}');
  }

  void _onAddSpecialist(Specialist specialist) {
    // TODO: Add specialist to current booking
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${specialist.name} добавлен в заказ'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () {
            // TODO: Remove specialist from booking
          },
        ),
      ),
    );
  }

  void _onBudgetEnhancementTap(BudgetEnhancementRecommendation recommendation) {
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
            Row(
              children: [
                const Text('Дополнительная стоимость: '),
                Text(
                  '${recommendation.additionalCost.toInt()} ₽',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Общий бюджет: '),
                Text(
                  '${recommendation.totalBudget.toInt()} ₽',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Влияние: '),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: recommendation.impact == 'Высокий' 
                        ? Colors.red.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    recommendation.impact,
                    style: TextStyle(
                      color: recommendation.impact == 'Высокий' 
                          ? Colors.red[700]
                          : Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
              // TODO: Apply budget enhancement
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${recommendation.title} добавлено в заказ'),
                ),
              );
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}
