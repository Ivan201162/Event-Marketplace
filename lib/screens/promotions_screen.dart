import 'package:event_marketplace_app/models/promotion.dart';
import 'package:event_marketplace_app/services/promotion_service.dart';
import 'package:event_marketplace_app/widgets/responsive_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран акций и предложений
class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen>
    with TickerProviderStateMixin {
  final PromotionService _promotionService = PromotionService();
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedCategory = 'all';
  String _selectedCity = '';
  List<Promotion> _allPromotions = [];
  List<Promotion> _filteredPromotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),);
    _loadPromotions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final promotions = await _promotionService.getActivePromotions();
      setState(() {
        _allPromotions = promotions;
        _filteredPromotions = promotions;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки акций: $e')));
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPromotions = _allPromotions.where((promotion) {
        final categoryMatch = _selectedCategory == 'all' ||
            promotion.category == _selectedCategory;
        final cityMatch =
            _selectedCity.isEmpty || promotion.city == _selectedCity;
        return categoryMatch && cityMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('🔥 Акции'),
          elevation: 0,
          backgroundColor: Colors.orange.shade50,
          foregroundColor: Colors.orange.shade800,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.orange.shade600,
            labelColor: Colors.orange.shade800,
            unselectedLabelColor: Colors.grey.shade600,
            tabs: const [
              Tab(text: 'Скидки', icon: Icon(Icons.local_offer)),
              Tab(text: 'Сезонные', icon: Icon(Icons.wb_sunny)),
              Tab(text: 'Подарки', icon: Icon(Icons.card_giftcard)),
            ],
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDiscountsTab(),
                    _buildSeasonalTab(),
                    _buildGiftsTab(),
                  ],
                ),
              ),
      );

  Widget _buildDiscountsTab() {
    final discounts = _filteredPromotions
        .where((p) => p.category != 'seasonal' && p.category != 'gift')
        .toList();

    return _buildPromotionsList(discounts, 'Скидки от специалистов');
  }

  Widget _buildSeasonalTab() {
    final seasonal =
        _filteredPromotions.where((p) => p.category == 'seasonal').toList();

    return _buildPromotionsList(seasonal, 'Сезонные предложения');
  }

  Widget _buildGiftsTab() {
    final gifts = _filteredPromotions
        .where((p) => p.category == 'gift' || p.category == 'promoCode')
        .toList();

    return _buildPromotionsList(gifts, 'Промокоды и подарки');
  }

  Widget _buildPromotionsList(List<Promotion> promotions, String title) {
    if (promotions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined,
                size: 64, color: Colors.grey.shade400,),
            const SizedBox(height: 16),
            Text(
              'Нет доступных акций',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Скоро появятся новые предложения!',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Заголовок с количеством
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.orange.shade50,
          child: Text(
            '$title (${promotions.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
          ),
        ),

        // Список акций
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promotions.length,
            itemBuilder: (context, index) =>
                _buildPromotionCard(promotions[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionCard(Promotion promotion) => ResponsiveCard(
        mobileMargin: const EdgeInsets.only(bottom: 16),
        tabletMargin: const EdgeInsets.only(bottom: 20),
        desktopMargin: const EdgeInsets.only(bottom: 24),
        child: InkWell(
          onTap: () => _showPromotionDetails(promotion),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade50,
                  Colors.orange.shade100.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок и скидка
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        promotion.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6,),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '-${promotion.discount}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Описание
                Text(
                  promotion.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Информация о специалисте и времени
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        promotion.specialistName ?? 'Специалист',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ),
                    Icon(Icons.access_time,
                        size: 16, color: Colors.grey.shade600,),
                    const SizedBox(width: 4),
                    Text(
                      promotion.formattedTimeRemaining,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),

                if (promotion.city != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey.shade600,),
                      const SizedBox(width: 4),
                      Text(
                        promotion.city!,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  void _showPromotionDetails(Promotion promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(promotion.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (promotion.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  promotion.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 64),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(promotion.description),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text('Специалист: ${promotion.specialistName ?? 'Не указан'}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.local_offer, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text('Скидка: ${promotion.discount}%'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text('До: ${promotion.formattedTimeRemaining}'),
              ],
            ),
            if (promotion.city != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: Colors.grey.shade600,),
                  const SizedBox(width: 8),
                  Text('Город: ${promotion.city}'),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Переход к специалисту
            },
            child: const Text('К специалисту'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Категория
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Категория',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Все категории')),
                DropdownMenuItem(
                    value: 'photographer', child: Text('Фотографы'),),
                DropdownMenuItem(
                    value: 'videographer', child: Text('Видеографы'),),
                DropdownMenuItem(value: 'dj', child: Text('DJ')),
                DropdownMenuItem(value: 'host', child: Text('Ведущие')),
                DropdownMenuItem(value: 'decorator', child: Text('Декораторы')),
                DropdownMenuItem(value: 'caterer', child: Text('Кейтеринг')),
                DropdownMenuItem(value: 'musician', child: Text('Музыканты')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? 'all';
                });
              },
            ),
            const SizedBox(height: 16),

            // Город
            TextField(
              decoration: const InputDecoration(
                labelText: 'Город',
                border: OutlineInputBorder(),
                hintText: 'Введите город',
              ),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = 'all';
                _selectedCity = '';
              });
              _applyFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Сбросить'),
          ),
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),),
          ElevatedButton(
            onPressed: () {
              _applyFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }
}
