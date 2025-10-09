import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist_tip.dart';
import '../services/specialist_tips_service.dart';

/// Виджет рекомендаций для специалистов
class SpecialistTipsWidget extends ConsumerStatefulWidget {

  const SpecialistTipsWidget({
    super.key,
    required this.userId,
    this.onTipTap,
  });
  final String userId;
  final VoidCallback? onTipTap;

  @override
  ConsumerState<SpecialistTipsWidget> createState() => _SpecialistTipsWidgetState();
}

class _SpecialistTipsWidgetState extends ConsumerState<SpecialistTipsWidget>
    with TickerProviderStateMixin {
  final SpecialistTipsService _tipsService = SpecialistTipsService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<SpecialistTip> _tips = [];
  ProfileStats? _profileStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadTips();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTips() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Генерируем новые рекомендации
      await _tipsService.generateTipsForSpecialist(widget.userId);
      
      // Загружаем рекомендации и статистику
      _tips = await _tipsService.getSpecialistTips(widget.userId);
      _profileStats = await _tipsService.getProfileStats(widget.userId);

      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Ошибка загрузки рекомендаций: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_tips.isEmpty) {
      return _buildEmptyWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с прогрессом
            _buildHeader(),
            
            const SizedBox(height: 12),
            
            // Список рекомендаций
            ..._tips.map(_buildTipCard),
          ],
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
              Icon(
                Icons.lightbulb_outline,
                color: Colors.amber.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Рекомендации по улучшению профиля',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Center(
            child: CircularProgressIndicator(),
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
              Icon(
                Icons.lightbulb_outline,
                color: Colors.amber.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Рекомендации по улучшению профиля',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Отличная работа!',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        'Ваш профиль полностью заполнен и оптимизирован',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  Widget _buildHeader() => Row(
      children: [
        Icon(
          Icons.lightbulb_outline,
          color: Colors.amber.shade600,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Рекомендации по улучшению профиля',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade800,
            ),
          ),
        ),
        if (_profileStats != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getProgressColor(_profileStats!.completionPercentage).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_profileStats!.completionPercentage}%',
              style: TextStyle(
                color: _getProgressColor(_profileStats!.completionPercentage),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );

  Widget _buildTipCard(SpecialistTip tip) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            widget.onTipTap?.call();
            // TODO: Переход к соответствующему экрану
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tip.priority.color.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с приоритетом
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: tip.priority.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        tip.priority.icon,
                        color: tip.priority.color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tip.priority.color,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tip.priority.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tip.priority.displayName,
                        style: TextStyle(
                          color: tip.priority.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Описание
                Text(
                  tip.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Кнопка действия
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          widget.onTipTap?.call();
                          // TODO: Переход к соответствующему экрану
                        },
                        icon: Icon(
                          Icons.edit,
                          size: 16,
                          color: tip.priority.color,
                        ),
                        label: Text(
                          tip.action,
                          style: TextStyle(
                            color: tip.priority.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: tip.priority.color),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _markAsCompleted(tip),
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade600,
                      ),
                      tooltip: 'Отметить как выполненное',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

  Color _getProgressColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.red;
    return Colors.grey;
  }

  Future<void> _markAsCompleted(SpecialistTip tip) async {
    try {
      final success = await _tipsService.markTipAsCompleted(tip.id);
      if (success) {
        setState(() {
          _tips.remove(tip);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Рекомендация "${tip.title}" отмечена как выполненная'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }
}

/// Виджет прогресса профиля
class ProfileProgressWidget extends StatelessWidget {

  const ProfileProgressWidget({
    super.key,
    required this.stats,
  });
  final ProfileStats stats;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Заполненность профиля',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
              const Spacer(),
              Text(
                '${stats.completionPercentage}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          LinearProgressIndicator(
            value: stats.completionPercentage / 100,
            backgroundColor: Colors.blue.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            minHeight: 8,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '${stats.completedFields} из ${stats.totalFields} полей заполнено',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue.shade700,
            ),
          ),
          
          if (stats.missingFields.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Не заполнено: ${stats.missingFields.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red.shade600,
              ),
            ),
          ],
        ],
      ),
    );
}
