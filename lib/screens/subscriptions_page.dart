import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/core/safe_log.dart';
import 'package:event_marketplace_app/models/subscription.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран подписок
class SubscriptionsPage extends ConsumerStatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  ConsumerState<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionsPage>
    with SingleTickerProviderStateMixin {
  final SubscriptionService _subscriptionService = SubscriptionService();
  late TabController _tabController;

  SubscriptionPeriod _selectedPeriod = SubscriptionPeriod.monthly;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.subscriptionsEnabled) {
      return _buildDisabledView();
    }

    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подписки'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Планы'),
            Tab(text: 'Моя подписка'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlansTab(currentUser),
          _buildMySubscriptionTab(currentUser),
        ],
      ),
    );
  }

  Widget _buildDisabledView() => Scaffold(
        appBar: AppBar(title: const Text('Подписки')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.credit_card_off, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                'Подписки временно отключены',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Мы работаем над улучшением системы подписок. Пожалуйста, попробуйте позже.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );

  Widget _buildPlansTab(currentUser) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            _buildHeader(),
            const SizedBox(height: 24),

            // Переключатель периода
            _buildPeriodSelector(),
            const SizedBox(height: 24),

            // Планы подписки
            _buildPlansGrid(),
            const SizedBox(height: 24),

            // FAQ
            _buildFAQ(),
          ],
        ),
      );

  Widget _buildMySubscriptionTab(currentUser) => StreamBuilder<Subscription?>(
        stream: _subscriptionService.getUserSubscription(
            currentUser.id, 'default_specialist',),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка загрузки подписки: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Повторить'),),
                ],
              ),
            );
          }

          final subscription = snapshot.data;

          if (subscription == null) {
            return _buildNoSubscriptionView();
          }

          return _buildSubscriptionDetails(subscription);
        },
      );

  Widget _buildHeader() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выберите подходящий план',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Получите доступ к расширенным возможностям и улучшите свой опыт работы с платформой',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ],
      );

  Widget _buildPeriodSelector() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
                child:
                    _buildPeriodButton('Месячная', SubscriptionPeriod.monthly),),
            Expanded(
                child:
                    _buildPeriodButton('Годовая', SubscriptionPeriod.yearly),),
          ],
        ),
      );

  Widget _buildPeriodButton(String label, SubscriptionPeriod period) {
    final isSelected = _selectedPeriod == period;

    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (period == SubscriptionPeriod.yearly) ...[
              const SizedBox(height: 2),
              Text(
                'Экономия 17%',
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withValues(alpha: 0.8)
                      : Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlansGrid() {
    final plans = SubscriptionPlans.getPaidPlans();

    return Column(children: plans.map(_buildPlanCard).toList());
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isPopular = plan.isPopular;
    final price = plan.getPriceForPeriod(_selectedPeriod);
    final savings = plan.getSavingsForPeriod(_selectedPeriod);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: isPopular
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  plan.badge ?? 'Популярно',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок плана
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          plan.formattedPrice,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Text(
                          _getPeriodLabel(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                        if (savings > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Экономия ${savings.toStringAsFixed(2)} ${plan.currency}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Функции
                _buildPlanFeatures(plan),

                const SizedBox(height: 20),

                // Кнопка выбора
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _selectPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      foregroundColor: isPopular
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      plan.type == SubscriptionType.free
                          ? 'Текущий план'
                          : 'Выбрать план',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanFeatures(SubscriptionPlan plan) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Включено:',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...plan.features
              .map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(feature,
                              style: Theme.of(context).textTheme.bodyMedium,),),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      );

  Widget _buildFAQ() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Часто задаваемые вопросы',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            'Могу ли я изменить план в любое время?',
            'Да, вы можете изменить свой план подписки в любое время. Изменения вступят в силу в следующем биллинговом цикле.',
          ),
          _buildFAQItem(
            'Что происходит при отмене подписки?',
            'При отмене подписки вы сохраните доступ к премиум функциям до конца текущего периода оплаты.',
          ),
          _buildFAQItem(
            'Предоставляется ли возврат средств?',
            'Мы предлагаем 30-дневную гарантию возврата средств для всех платных планов.',
          ),
          _buildFAQItem(
            'Могу ли я использовать бесплатный план?',
            'Да, бесплатный план доступен всем пользователям и включает базовые функции платформы.',
          ),
        ],
      );

  Widget _buildFAQItem(String question, String answer) => ExpansionTile(
        title: Text(
          question,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ),
        ],
      );

  Widget _buildNoSubscriptionView() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.credit_card_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('У вас нет активной подписки',
                style: Theme.of(context).textTheme.headlineSmall,),
            const SizedBox(height: 8),
            const Text(
              'Выберите подходящий план, чтобы получить доступ к расширенным возможностям',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Выбрать план'),
            ),
          ],
        ),
      );

  Widget _buildSubscriptionDetails(Subscription subscription) {
    final plan = SubscriptionPlans.getPlanByType(subscription.planType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Текущий план
          _buildCurrentPlanCard(subscription, plan),
          const SizedBox(height: 24),

          // Детали подписки
          _buildSubscriptionDetailsCard(subscription),
          const SizedBox(height: 24),

          // Использование
          if (plan != null) _buildUsageCard(plan),
          const SizedBox(height: 24),

          // Действия
          _buildSubscriptionActions(subscription),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(
          Subscription subscription, SubscriptionPlan? plan,) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.planType,
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Подписка на ${subscription.planType}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          subscription.isActive ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subscription.isActive ? 'Активна' : 'Неактивна',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (subscription.createdAt.isBefore(
                DateTime.now().subtract(const Duration(days: 25)),
              )) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Подписка истекает через ${DateTime.now().difference(subscription.createdAt).inDays} дн.',
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildSubscriptionDetailsCard(Subscription subscription) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Детали подписки',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Период', 'Месячная'),
              _buildDetailRow('Цена', subscription.formattedPrice),
              _buildDetailRow(
                  'Дата начала', _formatDate(subscription.createdAt),),
              _buildDetailRow(
                'Дата окончания',
                _formatDate(
                    subscription.createdAt.add(const Duration(days: 30)),),
              ),
              _buildDetailRow('Автопродление', 'Включено'),
              _buildDetailRow('Способ оплаты', 'Банковская карта'),
            ],
          ),
        ),
      );

  Widget _buildUsageCard(SubscriptionPlan plan) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Использование',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildUsageItem(
                  'События в месяц', 0, plan.getLimit('events_per_month'),),
              _buildUsageItem('Уведомления в день', 0,
                  plan.getLimit('notifications_per_day'),),
              _buildUsageItem('Хранилище', 0, plan.getLimit('storage_mb')),
              _buildUsageItem(
                  'Участники команды', 0, plan.getLimit('team_members'),),
            ],
          ),
        ),
      );

  Widget _buildUsageItem(String label, int used, int limit) {
    final percentage = limit > 0 ? (used / limit) : 0.0;
    final isUnlimited = limit == -1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                isUnlimited ? 'Неограниченно' : '$used / $limit',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (!isUnlimited)
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 0.8
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionActions(Subscription subscription) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Действия',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (subscription.planType != 'free') ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _changePlan,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Изменить план'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleAutoRenew(subscription),
                    icon: const Icon(Icons.pause),
                    label: const Text('Отключить автопродление'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelSubscription(subscription),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Отменить подписку'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(0),
                    icon: const Icon(Icons.upgrade),
                    label: const Text('Обновить до платного плана'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case SubscriptionPeriod.monthly:
        return 'в месяц';
      case SubscriptionPeriod.quarterly:
        return 'в квартал';
      case SubscriptionPeriod.yearly:
        return 'в год';
      case SubscriptionPeriod.lifetime:
        return 'навсегда';
      default:
        return 'неизвестно';
    }
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';

  Future<void> _selectPlan(SubscriptionPlan plan) async {
    if (plan.type == SubscriptionType.free) return;

    setState(() => _isLoading = true);

    try {
      // В демо-версии показываем диалог вместо реальной оплаты
      final confirmed = await _showPaymentDialog(plan);

      if (confirmed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Подписка "${plan.name}" активирована!'),
            backgroundColor: Colors.green,
          ),
        );

        // Переключаемся на вкладку "Моя подписка"
        _tabController.animateTo(1);
      }
    } catch (e, stackTrace) {
      SafeLog.error('SubscriptionsPage: Error selecting plan', e, stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка активации подписки: $e'),
            backgroundColor: Colors.red,),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showPaymentDialog(SubscriptionPlan plan) async {
    final price = plan.getPriceForPeriod(_selectedPeriod);

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Активация ${plan.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Выбранный план: ${plan.name}'),
                Text('Период: ${_getPeriodLabel()}'),
                Text('Цена: ${price.toStringAsFixed(2)} ${plan.currency}'),
                const SizedBox(height: 16),
                const Text(
                  'В демо-версии оплата не производится. Подписка будет активирована автоматически.',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey,),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Активировать'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _changePlan() {
    _tabController.animateTo(0);
  }

  void _toggleAutoRenew(Subscription subscription) {
    // TODO(developer): Реализовать переключение автопродления
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(
        content: Text('Функция будет реализована в следующей версии'),),);
  }

  void _cancelSubscription(Subscription subscription) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отмена подписки'),
        content: const Text(
          'Вы уверены, что хотите отменить подписку? Вы сохраните доступ к премиум функциям до конца текущего периода.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO(developer): Реализовать отмену подписки
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Функция будет реализована в следующей версии'),),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Отменить'),
          ),
        ],
      ),
    );
  }
}

/// Расширение для отображения цены плана
extension SubscriptionPlanExtension on SubscriptionPlan {
  String get formattedPrice {
    if (monthlyPrice == 0) return 'Бесплатно';
    return '${monthlyPrice.toStringAsFixed(2)} $currency';
  }
}
