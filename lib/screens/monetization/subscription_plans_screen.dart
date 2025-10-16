import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription_plan.dart';
import '../../services/subscription_service.dart';
import '../../services/payment_service.dart';
import '../../providers/auth_provider.dart';
import 'payment_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  UserSubscription? _activeSubscription;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _subscriptionService.getAvailablePlans();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?['id'];
      
      UserSubscription? activeSubscription;
      if (userId != null) {
        activeSubscription = await _subscriptionService.getActiveSubscription(userId);
      }

      setState(() {
        _plans = plans;
        _activeSubscription = activeSubscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки планов: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Планы подписки'),
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
                  // Текущая подписка
                  if (_activeSubscription != null) ...[
                    _buildCurrentSubscriptionCard(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Заголовок
                  Text(
                    'Выберите план подписки',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Расширьте возможности вашего профиля с премиум-функциями',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Планы подписки
                  ..._plans.map((plan) => _buildPlanCard(plan)),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.amber, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Активная подписка',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Осталось дней: ${_activeSubscription!.daysRemaining}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _activeSubscription!.progressPercentage,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Автопродление: ${_activeSubscription!.autoRenew ? "Включено" : "Выключено"}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Управление подпиской
                  },
                  child: const Text(
                    'Управлять',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isCurrentPlan = _activeSubscription?.planId == plan.id;
    final isPopular = plan.tier == SubscriptionTier.premium;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isPopular ? 8 : 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPopular
                ? Border.all(color: Colors.amber, width: 2)
                : null,
          ),
          child: Column(
            children: [
              // Заголовок плана
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getPlanColor(plan.tier).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
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
                          _getPlanIcon(plan.tier),
                          color: _getPlanColor(plan.tier),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (plan.description != null)
                                Text(
                                  plan.description!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
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
                          '${plan.price.toInt()} ₽',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: _getPlanColor(plan.tier),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ ${plan.durationDays} дн.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        if (plan.hasDiscount) ...[
                          Text(
                            '${plan.originalPrice!.toInt()} ₽',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${plan.discountPercentage!.toInt()}%',
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
              
              // Функции плана
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Включено в план:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...plan.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: _getPlanColor(plan.tier),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 20),
                    
                    // Кнопка действия
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isCurrentPlan
                            ? null
                            : () => _selectPlan(plan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getPlanColor(plan.tier),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isCurrentPlan
                              ? 'Текущий план'
                              : plan.tier == SubscriptionTier.free
                                  ? 'Бесплатно'
                                  : 'Выбрать план',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

  Color _getPlanColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Colors.grey;
      case SubscriptionTier.premium:
        return Colors.amber;
      case SubscriptionTier.pro:
        return Colors.deepPurple;
    }
  }

  IconData _getPlanIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.person;
      case SubscriptionTier.premium:
        return Icons.star;
      case SubscriptionTier.pro:
        return Icons.diamond;
    }
  }

  Future<void> _selectPlan(SubscriptionPlan plan) async {
    if (plan.tier == SubscriptionTier.free) {
      // Для бесплатного плана просто показываем сообщение
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Вы уже используете бесплатный план'),
        ),
      );
      return;
    }

    // Переходим к экрану оплаты
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          plan: plan,
          type: PaymentType.subscription,
        ),
      ),
    );

    if (result == true && mounted) {
      // Обновляем данные после успешной оплаты
      await _loadPlans();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Подписка успешно активирована!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
