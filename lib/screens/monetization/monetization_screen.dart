import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Monetization screen with subscription plans
class MonetizationScreen extends StatelessWidget {
  const MonetizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Монетизация'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current plan section
            _buildCurrentPlanSection(context),
            const SizedBox(height: 24),

            // Available plans section
            _buildAvailablePlansSection(context),
            const SizedBox(height: 24),

            // Features comparison
            _buildFeaturesComparison(context),
            const SizedBox(height: 24),

            // FAQ section
            _buildFAQSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Текущий план', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.blue, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Базовый план',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Активен до 15.07.2024',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/subscription/manage');
                    },
                    child: const Text('Управлять'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailablePlansSection(BuildContext context) {
    final plans = [
      {
        'name': 'Базовый',
        'price': '990',
        'period': 'месяц',
        'features': ['До 5 заявок в месяц', 'Базовые фильтры поиска', 'Поддержка 24/7'],
        'color': Colors.blue,
        'popular': false,
      },
      {
        'name': 'Продвинутый',
        'price': '1990',
        'period': 'месяц',
        'features': [
          'До 20 заявок в месяц',
          'Расширенные фильтры',
          'Приоритетная поддержка',
          'Аналитика профиля',
        ],
        'color': Colors.purple,
        'popular': true,
      },
      {
        'name': 'Профессиональный',
        'price': '3990',
        'period': 'месяц',
        'features': [
          'Безлимитные заявки',
          'Все фильтры и функции',
          'Персональный менеджер',
          'Продвижение профиля',
          'API доступ',
        ],
        'color': Colors.orange,
        'popular': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Доступные планы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...plans.map((plan) => _buildPlanCard(context, plan)),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, Map<String, dynamic> plan) {
    final isPopular = plan['popular'] as bool;
    final planColor = plan['color'] as Color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPopular
              ? [
                  planColor.withOpacity(0.1),
                  planColor.withOpacity(0.05),
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? planColor : Colors.grey.withOpacity(0.3),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular 
                ? planColor.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: isPopular ? 15 : 8,
            offset: Offset(0, isPopular ? 8 : 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок и популярный бейдж
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                plan['name'] as String,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isPopular ? planColor : Colors.grey[800],
                                ),
                              ),
                              if (isPopular) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [planColor, planColor.withOpacity(0.8)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: planColor.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'ПОПУЛЯРНЫЙ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${plan['price']} ₽',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: isPopular ? planColor : Colors.grey[800],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '/ ${plan['period']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Список функций
                ...(plan['features'] as List<String>).map(
                  (feature) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: planColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: planColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Кнопка выбора
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [planColor, planColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: planColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showPurchaseDialog(context, plan),
                      borderRadius: BorderRadius.circular(16),
                      child: const Center(
                        child: Text(
                          'Выбрать план',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  Widget _buildFeaturesComparison(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Сравнение функций',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              children: const [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Функция', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Базовый', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Продвинутый', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Профессиональный',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: Text('Заявки в месяц')),
                    Padding(padding: EdgeInsets.all(8), child: Text('5')),
                    Padding(padding: EdgeInsets.all(8), child: Text('20')),
                    Padding(padding: EdgeInsets.all(8), child: Text('Безлимит')),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: Text('Поддержка')),
                    Padding(padding: EdgeInsets.all(8), child: Text('Базовая')),
                    Padding(padding: EdgeInsets.all(8), child: Text('Приоритетная')),
                    Padding(padding: EdgeInsets.all(8), child: Text('Персональный менеджер')),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: Text('Аналитика')),
                    Padding(padding: EdgeInsets.all(8), child: Text('❌')),
                    Padding(padding: EdgeInsets.all(8), child: Text('✅')),
                    Padding(padding: EdgeInsets.all(8), child: Text('✅')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Часто задаваемые вопросы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._buildFAQItems(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFAQItems(BuildContext context) {
    final faqs = [
      {
        'question': 'Можно ли отменить подписку?',
        'answer': 'Да, вы можете отменить подписку в любое время в настройках аккаунта.',
      },
      {
        'question': 'Что происходит после отмены?',
        'answer':
            'После отмены подписки вы сохраняете доступ к функциям до конца оплаченного периода.',
      },
      {
        'question': 'Есть ли пробный период?',
        'answer': 'Да, мы предлагаем 7-дневный бесплатный пробный период для всех планов.',
      },
    ];

    return faqs
        .map(
          (faq) => ExpansionTile(
            title: Text(faq['question'] as String),
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Text(faq['answer'] as String)),
            ],
          ),
        )
        .toList();
  }

  void _showPurchaseDialog(BuildContext context, Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Подписка на ${plan['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Цена: ${plan['price']} ₽ / ${plan['period']}'),
            const SizedBox(height: 16),
            const Text('Включено:'),
            const SizedBox(height: 8),
            ...(plan['features'] as List<String>).map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPayment(context, plan);
            },
            child: const Text('Подписаться'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('О монетизации'),
        content: const Text(
          'Монетизация позволяет получить доступ к расширенным функциям приложения, включая больше заявок, приоритетную поддержку и аналитику.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно')),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context, Map<String, dynamic> plan) {
    // Переход к экрану оплаты
    context.push('/payment/subscription', extra: {'plan': plan, 'type': 'subscription'});
  }
}
