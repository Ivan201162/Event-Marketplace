import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/payment_config.dart';
import '../../services/payment_service.dart';
import '../../models/subscription.dart';
import '../../widgets/subscription/subscription_plan_card.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  final String userId;

  const SubscriptionScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  Subscription? _currentSubscription;
  SubscriptionPlan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой тариф'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Subscription Status
            if (_currentSubscription != null) ...[
              _buildCurrentSubscriptionCard(),
              const SizedBox(height: 24),
            ],

            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.indigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.diamond,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Выберите подписку',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Получите доступ к расширенному функционалу',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Subscription Plans
            const Text(
              'Доступные тарифы:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Standard Plan
            SubscriptionPlanCard(
              plan: SubscriptionPlan.standard,
              price: PaymentConfig.subscriptionPlans['standard']!,
              isSelected: _selectedPlan == SubscriptionPlan.standard,
              isCurrentPlan: _currentSubscription?.plan == SubscriptionPlan.standard,
              onTap: () {
                setState(() {
                  _selectedPlan = SubscriptionPlan.standard;
                });
              },
            ),

            // Pro Plan
            SubscriptionPlanCard(
              plan: SubscriptionPlan.pro,
              price: PaymentConfig.subscriptionPlans['pro']!,
              isSelected: _selectedPlan == SubscriptionPlan.pro,
              isCurrentPlan: _currentSubscription?.plan == SubscriptionPlan.pro,
              onTap: () {
                setState(() {
                  _selectedPlan = SubscriptionPlan.pro;
                });
              },
            ),

            // Elite Plan
            SubscriptionPlanCard(
              plan: SubscriptionPlan.elite,
              price: PaymentConfig.subscriptionPlans['elite']!,
              isSelected: _selectedPlan == SubscriptionPlan.elite,
              isCurrentPlan: _currentSubscription?.plan == SubscriptionPlan.elite,
              onTap: () {
                setState(() {
                  _selectedPlan = SubscriptionPlan.elite;
                });
              },
            ),

            const SizedBox(height: 32),

            // Action Button
            if (_selectedPlan != null && _selectedPlan != _currentSubscription?.plan) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _selectedPlan == SubscriptionPlan.standard
                              ? 'Активировать бесплатный тариф'
                              : 'Оплатить ${PaymentConfig.subscriptionPlans[_selectedPlan.toString().split('.').last]} ₽/мес',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Cancel Subscription Button
            if (_currentSubscription != null && 
                _currentSubscription!.plan != SubscriptionPlan.standard) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _cancelSubscription,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Отменить подписку',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Terms
            Text(
              'Подписка продлевается автоматически. '
              'Вы можете отменить её в любое время в настройках.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    final subscription = _currentSubscription!;
    final isExpired = subscription.isExpired;
    final daysRemaining = subscription.daysRemaining;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.red : Colors.green,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpired ? Icons.warning : Icons.check_circle,
                color: isExpired ? Colors.red : Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Текущий тариф: ${_getPlanName(subscription.plan)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isExpired
                ? 'Подписка истекла'
                : 'Осталось дней: $daysRemaining',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          if (!isExpired) ...[
            const SizedBox(height: 4),
            Text(
              'Следующее списание: ${_formatDate(subscription.expiresAt)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getPlanName(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.standard:
        return 'Standard';
      case SubscriptionPlan.pro:
        return 'Pro';
      case SubscriptionPlan.elite:
        return 'Elite';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _loadCurrentSubscription() async {
    try {
      final subscription = await _paymentService.getUserSubscription(widget.userId);
      setState(() {
        _currentSubscription = subscription;
      });
    } catch (e) {
      print('Error loading subscription: $e');
    }
  }

  Future<void> _processSubscription() async {
    if (_selectedPlan == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = PaymentConfig.subscriptionPlans[_selectedPlan.toString().split('.').last]!;
      final success = await _paymentService.processSubscription(
        userId: widget.userId,
        plan: _selectedPlan!,
        amount: amount,
      );

      if (success) {
        _showSuccessDialog();
        await _loadCurrentSubscription();
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      _showErrorDialog();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить подписку'),
        content: const Text(
          'Вы уверены, что хотите отменить подписку? '
          'Доступ к премиум-функциям будет прекращен в конце текущего периода.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Here you would implement subscription cancellation
      // For now, just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Подписка отменена'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Успешно!'),
          ],
        ),
        content: Text(
          'Подписка ${_getPlanName(_selectedPlan!)} успешно активирована!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отлично'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Ошибка'),
          ],
        ),
        content: const Text(
          'Произошла ошибка при обработке подписки. '
          'Попробуйте еще раз или обратитесь в поддержку.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}


