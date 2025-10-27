import 'package:flutter/material.dart';

/// Виджет продвижения для PRO-аккаунта
class PromotionWidget extends StatefulWidget {
  const PromotionWidget({super.key});

  @override
  State<PromotionWidget> createState() => _PromotionWidgetState();
}

class _PromotionWidgetState extends State<PromotionWidget> {
  bool _isVipActive = false;
  bool _isPromotionActive = false;
  int _promotionDays = 7;
  double _promotionBudget = 1000.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Продвижение'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // VIP-статус
          _buildVipStatusCard(),
          const SizedBox(height: 16),

          // Платное продвижение
          _buildPaidPromotionCard(),
          const SizedBox(height: 16),

          // Настройка визитки
          _buildBusinessCardCard(),
          const SizedBox(height: 16),

          // Статистика продвижения
          _buildPromotionStatsCard(),
        ],
      ),
    );
  }

  Widget _buildVipStatusCard() {
    return Card(
      color: _isVipActive ? Colors.amber[50] : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: _isVipActive ? Colors.amber : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VIP-статус',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _isVipActive ? Colors.amber[800] : Colors.grey,
                        ),
                      ),
                      Text(
                        _isVipActive ? 'Активен до 31.12.2024' : 'Неактивен',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Преимущества VIP-статуса:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isVipActive ? Colors.amber[800] : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Приоритетная выдача в поиске\n'
              '• Золотая рамка профиля\n'
              '• Увеличенная видимость\n'
              '• Приоритетная поддержка',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isVipActive = !_isVipActive);
                },
                icon: Icon(_isVipActive ? Icons.cancel : Icons.star),
                label: Text(
                    _isVipActive ? 'Деактивировать VIP' : 'Активировать VIP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isVipActive ? Colors.red : Colors.amber,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaidPromotionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Платное продвижение',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Включить продвижение'),
              subtitle: const Text('Платно продвигать профиль'),
              value: _isPromotionActive,
              onChanged: (value) {
                setState(() => _isPromotionActive = value);
              },
            ),
            if (_isPromotionActive) ...[
              const SizedBox(height: 16),

              // Длительность продвижения
              const Text('Длительность (дни):'),
              Slider(
                value: _promotionDays.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                label: '$_promotionDays дней',
                onChanged: (value) {
                  setState(() => _promotionDays = value.round());
                },
              ),

              const SizedBox(height: 16),

              // Бюджет
              const Text('Бюджет (руб.):'),
              Slider(
                value: _promotionBudget,
                min: 100,
                max: 10000,
                divisions: 99,
                label: '${_promotionBudget.round()} руб.',
                onChanged: (value) {
                  setState(() => _promotionBudget = value);
                },
              ),

              const SizedBox(height: 16),

              // Кнопка запуска
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showPromotionDialog();
                  },
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Запустить продвижение'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCardCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Настройка визитки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Редактировать визитку'),
              subtitle: const Text('Настройте внешний вид вашей визитки'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showInfoSnackBar('Редактирование визитки будет реализовано');
              },
            ),
            ListTile(
              leading: const Icon(Icons.preview),
              title: const Text('Предпросмотр визитки'),
              subtitle: const Text('Посмотрите, как выглядит ваша визитка'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showInfoSnackBar('Предпросмотр визитки будет реализован');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика продвижения',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Показы',
                    '12,345',
                    Icons.visibility,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Клики',
                    '234',
                    Icons.touch_app,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'CTR',
                    '1.9%',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Потрачено',
                    '1,500 ₽',
                    Icons.attach_money,
                    Colors.red,
                  ),
                ),
              ],
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
              fontSize: 18,
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

  void _showPromotionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Запуск продвижения'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Длительность: $_promotionDays дней'),
            Text('Бюджет: ${_promotionBudget.round()} руб.'),
            const SizedBox(height: 16),
            const Text(
              'Вы уверены, что хотите запустить продвижение? '
              'Средства будут списаны с вашего баланса.',
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
              _showSuccessSnackBar('Продвижение запущено');
            },
            child: const Text('Запустить'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
