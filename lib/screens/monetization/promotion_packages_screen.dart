import 'package:flutter/material.dart';

import '../../models/promotion_boost.dart';
import '../../services/promotion_service.dart';
import 'payment_screen.dart';

class PromotionPackagesScreen extends StatefulWidget {
  const PromotionPackagesScreen({super.key});

  @override
  State<PromotionPackagesScreen> createState() => _PromotionPackagesScreenState();
}

class _PromotionPackagesScreenState extends State<PromotionPackagesScreen> {
  final PromotionService _promotionService = PromotionService();
  List<PromotionPackage> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final packages = await _promotionService.getAvailablePackages();
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки пакетов: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пакеты продвижения'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Text(
                    'Повысьте видимость',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Выберите подходящий пакет продвижения для увеличения охвата',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Пакеты продвижения
                  ..._packages.map((package) => _buildPackageCard(package)),
                ],
              ),
            ),
    );
  }

  Widget _buildPackageCard(PromotionPackage package) {
    final isPopular = package.priorityLevel == PromotionPriority.high;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isPopular ? 8 : 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPopular ? Border.all(color: Colors.green, width: 2) : null,
          ),
          child: Column(
            children: [
              // Заголовок пакета
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getTypeColor(package.type).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ПОПУЛЯРНЫЙ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (isPopular) const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _getTypeIcon(package.type),
                          color: _getTypeColor(package.type),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                package.name,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (package.description != null)
                                Text(
                                  package.description!,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${package.price.toInt()} ₽',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: _getTypeColor(package.type),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ ${package.durationDays} дн.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                        ),
                        const Spacer(),
                        if (package.hasDiscount) ...[
                          Text(
                            '${package.originalPrice!.toInt()} ₽',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${package.discountPercentage!.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Функции пакета
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Включено в пакет:',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (package.features != null)
                      ...package.features!.map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: _getTypeColor(package.type),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(feature, style: Theme.of(context).textTheme.bodyMedium),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Кнопка покупки
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _selectPackage(package),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getTypeColor(package.type),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Купить продвижение',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(PromotionType type) {
    switch (type) {
      case PromotionType.profileBoost:
        return Colors.green;
      case PromotionType.postBoost:
        return Colors.orange;
      case PromotionType.categoryBoost:
        return Colors.blue;
      case PromotionType.searchBoost:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(PromotionType type) {
    switch (type) {
      case PromotionType.profileBoost:
        return Icons.person;
      case PromotionType.postBoost:
        return Icons.trending_up;
      case PromotionType.categoryBoost:
        return Icons.category;
      case PromotionType.searchBoost:
        return Icons.search;
    }
  }

  Future<void> _selectPackage(PromotionPackage package) async {
    // Переходим к экрану оплаты
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(promotionPackage: package, type: PaymentType.promotion),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Продвижение успешно активировано!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
