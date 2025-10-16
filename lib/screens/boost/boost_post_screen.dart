import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/payment_service.dart';
import '../../widgets/boost/boost_plan_card.dart';

class BoostPostScreen extends ConsumerStatefulWidget {
  const BoostPostScreen({
    super.key,
    required this.postId,
    required this.postTitle,
    this.postImage,
  });
  final String postId;
  final String postTitle;
  final String? postImage;

  @override
  ConsumerState<BoostPostScreen> createState() => _BoostPostScreenState();
}

class _BoostPostScreenState extends ConsumerState<BoostPostScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  int? _selectedDays;
  double? _selectedPrice;

  // Boost plans: days -> price
  final Map<int, double> _boostPlans = {
    1: 199.0,
    3: 499.0,
    7: 999.0,
    14: 1799.0,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Продвинуть пост'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: widget.postImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.postImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.image,
                              color: Colors.white,
                              size: 30,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Продвижение поста',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.postTitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Benefits
              const Text(
                'Что даёт продвижение:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildBenefitItem(
                Icons.visibility,
                'Больше просмотров',
                'Пост будет показываться чаще в ленте',
              ),
              _buildBenefitItem(
                Icons.touch_app,
                'Больше взаимодействий',
                'Увеличение лайков, комментариев и репостов',
              ),
              _buildBenefitItem(
                Icons.people,
                'Новая аудитория',
                'Достижение пользователей, которые не подписаны',
              ),
              _buildBenefitItem(
                Icons.analytics,
                'Подробная статистика',
                'Аналитика показов, кликов и конверсий',
              ),

              const SizedBox(height: 32),

              // Boost Plans
              const Text(
                'Выберите период продвижения:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Boost Plan Cards
              ..._boostPlans.entries.map((entry) {
                final days = entry.key;
                final price = entry.value;
                final isSelected = _selectedDays == days;

                return BoostPlanCard(
                  days: days,
                  price: price,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedDays = days;
                      _selectedPrice = price;
                    });
                  },
                );
              }),

              const SizedBox(height: 32),

              // Purchase Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedDays != null && !_isLoading
                      ? _processBoost
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Продвинуть за ${_selectedPrice?.toInt() ?? 0} ₽',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Продвигаемый пост будет отображаться в ленте каждые 5-7 обычных постов '
                        'с пометкой "Реклама". Статистика показов доступна в профиле.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Terms
              Text(
                'Продвижение начинается сразу после оплаты. '
                'Оплата производится через защищенный сервис Stripe.',
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

  Widget _buildBenefitItem(IconData icon, String title, String description) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Future<void> _processBoost() async {
    if (_selectedDays == null || _selectedPrice == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // For demo purposes, we'll use a dummy user ID
      const userId = 'demo_user_123';

      final success = await _paymentService.processPostBoost(
        userId: userId,
        postId: widget.postId,
        amount: _selectedPrice!,
        days: _selectedDays!,
      );

      if (success) {
        _showSuccessDialog();
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.trending_up, color: Colors.orange),
            SizedBox(width: 8),
            Text('Успешно!'),
          ],
        ),
        content: Text(
          'Ваш пост успешно продвинут на $_selectedDays дней! '
          'Продвижение начнется в течение нескольких минут.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
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
          'Произошла ошибка при обработке продвижения. '
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


