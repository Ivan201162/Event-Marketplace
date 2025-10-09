import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pro_subscription.dart';
import '../providers/pro_subscription_providers.dart';
import '../widgets/pro_subscription_widgets.dart';

/// Экран управления PRO подписками
class ProSubscriptionScreen extends ConsumerStatefulWidget {
  const ProSubscriptionScreen({
    super.key,
    required this.userId,
  });
  final String userId;

  @override
  ConsumerState<ProSubscriptionScreen> createState() =>
      _ProSubscriptionScreenState();
}

class _ProSubscriptionScreenState extends ConsumerState<ProSubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Загрузить подписку пользователя
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(subscriptionStateProvider.notifier)
          .loadUserSubscription(widget.userId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('PRO Подписка'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Текущая', icon: Icon(Icons.star)),
              Tab(text: 'Планы', icon: Icon(Icons.credit_card)),
              Tab(text: 'История', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Текущая подписка
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CurrentSubscriptionWidget(userId: widget.userId),
                  const SizedBox(height: 24),
                  const SubscriptionStatsWidget(),
                ],
              ),
            ),

            // Планы подписки
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SubscriptionPlansWidget(
                userId: widget.userId,
                onPlanSelected: _handlePlanSelected,
              ),
            ),

            // История платежей
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildPaymentHistoryTab(),
            ),
          ],
        ),
      );

  Widget _buildPaymentHistoryTab() {
    final subscriptionAsync =
        ref.watch(userSubscriptionProvider(widget.userId));

    return subscriptionAsync.when(
      data: (subscription) {
        if (subscription == null) {
          return const Center(
            child: Text(
              'У вас нет активной подписки',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return PaymentHistoryWidget(subscriptionId: subscription.id);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Ошибка: $error'),
    );
  }

  void _handlePlanSelected(SubscriptionPlan plan) {
    _showPlanDetailsDialog(plan);
  }

  void _showPlanDetailsDialog(SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('План ${plan.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Стоимость: ${plan.monthlyPrice}₽/месяц',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Включенные функции:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showPaymentDialog(plan);
            },
            child: const Text('Оформить'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оформление подписки'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'План: ${plan.displayName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Стоимость: ${plan.monthlyPrice}₽/месяц',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Выберите способ оплаты:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Банковская карта'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).pop();
                _processPayment(plan, 'card');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Электронный кошелек'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).pop();
                _processPayment(plan, 'wallet');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _processPayment(SubscriptionPlan plan, String paymentMethod) {
    // Показать индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Обработка платежа...'),
          ],
        ),
      ),
    );

    // Имитация обработки платежа
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Закрыть диалог загрузки

      // Создать подписку
      ref.read(subscriptionStateProvider.notifier).createSubscription(
            userId: widget.userId,
            plan: plan,
            paymentMethodId: 'mock_payment_method_$paymentMethod',
            isTrial: plan ==
                SubscriptionPlan.basic, // Базовый план с пробным периодом
          );

      // Показать результат
      _showPaymentResult(true);
    });
  }

  void _showPaymentResult(bool success) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(success ? 'Успешно!' : 'Ошибка'),
        content: Text(
          success
              ? 'Подписка успешно оформлена!'
              : 'Произошла ошибка при оформлении подписки.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (success) {
                // Переключиться на вкладку "Текущая"
                _tabController.animateTo(0);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
