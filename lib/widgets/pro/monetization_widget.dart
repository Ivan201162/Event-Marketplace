import 'package:flutter/material.dart';

/// Виджет монетизации для PRO-аккаунта
class MonetizationWidget extends StatefulWidget {
  const MonetizationWidget({super.key});

  @override
  State<MonetizationWidget> createState() => _MonetizationWidgetState();
}

class _MonetizationWidgetState extends State<MonetizationWidget> {
  bool _paidStoriesEnabled = false;
  bool _donationsEnabled = false;
  bool _subscriptionsEnabled = false;
  bool _directStreamsEnabled = false;

  double _storyPrice = 50.0;
  double _streamPrice = 200.0;
  double _subscriptionPrice = 500.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Монетизация'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Настройки монетизации
          _buildMonetizationSettingsCard(),
          const SizedBox(height: 16),

          // Платные сторис
          _buildPaidStoriesCard(),
          const SizedBox(height: 16),

          // Донаты
          _buildDonationsCard(),
          const SizedBox(height: 16),

          // Подписки
          _buildSubscriptionsCard(),
          const SizedBox(height: 16),

          // Прямые эфиры
          _buildDirectStreamsCard(),
          const SizedBox(height: 16),

          // История выплат
          _buildPaymentHistoryCard(),
          const SizedBox(height: 16),

          // Привязка карт
          _buildPaymentMethodsCard(),
        ],
      ),
    );
  }

  Widget _buildMonetizationSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Настройки монетизации',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Включить монетизацию'),
              subtitle: const Text('Разрешить получение платежей'),
              value: _paidStoriesEnabled ||
                  _donationsEnabled ||
                  _subscriptionsEnabled,
              onChanged: (value) {
                setState(() {
                  _paidStoriesEnabled = value;
                  _donationsEnabled = value;
                  _subscriptionsEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaidStoriesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Платные сторис',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Включить платные сторис'),
              subtitle:
                  const Text('Пользователи платят за просмотр ваших историй'),
              value: _paidStoriesEnabled,
              onChanged: (value) {
                setState(() => _paidStoriesEnabled = value);
              },
            ),
            if (_paidStoriesEnabled) ...[
              const SizedBox(height: 16),
              const Text('Цена за просмотр (руб.):'),
              Slider(
                value: _storyPrice,
                min: 10,
                max: 500,
                divisions: 49,
                label: '${_storyPrice.round()} руб.',
                onChanged: (value) {
                  setState(() => _storyPrice = value);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDonationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Донаты',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Включить донаты'),
              subtitle: const Text('Пользователи могут отправить вам донат'),
              value: _donationsEnabled,
              onChanged: (value) {
                setState(() => _donationsEnabled = value);
              },
            ),
            if (_donationsEnabled) ...[
              const SizedBox(height: 16),
              const Text('Рекомендуемые суммы:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [50, 100, 200, 500, 1000]
                    .map(
                      (amount) => Chip(
                        label: Text('$amount ₽'),
                        onDeleted: () {},
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Подписки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Включить подписки'),
              subtitle: const Text(
                  'Пользователи могут подписаться на эксклюзивный контент'),
              value: _subscriptionsEnabled,
              onChanged: (value) {
                setState(() => _subscriptionsEnabled = value);
              },
            ),
            if (_subscriptionsEnabled) ...[
              const SizedBox(height: 16),
              const Text('Цена подписки (руб./месяц):'),
              Slider(
                value: _subscriptionPrice,
                min: 100,
                max: 5000,
                divisions: 49,
                label: '${_subscriptionPrice.round()} руб.',
                onChanged: (value) {
                  setState(() => _subscriptionPrice = value);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDirectStreamsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Прямые эфиры',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Включить платные эфиры'),
              subtitle:
                  const Text('Пользователи платят за просмотр ваших эфиров'),
              value: _directStreamsEnabled,
              onChanged: (value) {
                setState(() => _directStreamsEnabled = value);
              },
            ),
            if (_directStreamsEnabled) ...[
              const SizedBox(height: 16),
              const Text('Цена за эфир (руб.):'),
              Slider(
                value: _streamPrice,
                min: 50,
                max: 2000,
                divisions: 39,
                label: '${_streamPrice.round()} руб.',
                onChanged: (value) {
                  setState(() => _streamPrice = value);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История выплат',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Статистика
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Заработано',
                    '12,450 ₽',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Комиссия',
                    '1,245 ₽',
                    Icons.percent,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'К выплате',
                    '11,205 ₽',
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Выплачено',
                    '8,500 ₽',
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showInfoSnackBar('История выплат будет реализована');
                },
                icon: const Icon(Icons.history),
                label: const Text('Просмотреть историю'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Способы оплаты',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.blue),
              title: const Text('Банковская карта'),
              subtitle: const Text('**** 1234'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showInfoSnackBar('Управление картами будет реализовано');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.account_balance_wallet, color: Colors.green),
              title: const Text('Электронный кошелек'),
              subtitle: const Text('Не привязан'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showInfoSnackBar('Привязка кошелька будет реализована');
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showInfoSnackBar(
                      'Добавление способа оплаты будет реализовано');
                },
                icon: const Icon(Icons.add),
                label: const Text('Добавить способ оплаты'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
