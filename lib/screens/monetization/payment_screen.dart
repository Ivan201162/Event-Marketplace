import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription_plan.dart';
import '../../models/promotion_boost.dart';
import '../../models/advertisement.dart';
import '../../services/payment_service.dart';
import '../../services/subscription_service.dart';
import '../../services/promotion_service.dart';
import '../../services/advertisement_service.dart';
import '../../providers/auth_provider.dart';

enum PaymentType {
  subscription,
  promotion,
  advertisement,
}

class PaymentScreen extends StatefulWidget {
  final SubscriptionPlan? plan;
  final PromotionPackage? promotionPackage;
  final Advertisement? advertisement;
  final PaymentType type;

  const PaymentScreen({
    super.key,
    this.plan,
    this.promotionPackage,
    this.advertisement,
    required this.type,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final PromotionService _promotionService = PromotionService();
  final AdvertisementService _advertisementService = AdvertisementService();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.card;
  PaymentProvider _selectedProvider = PaymentProvider.stripe;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о заказе
            _buildOrderInfo(),
            const SizedBox(height: 24),

            // Способы оплаты
            _buildPaymentMethods(),
            const SizedBox(height: 24),

            // Провайдеры платежей
            _buildPaymentProviders(),
            const SizedBox(height: 32),

            // Кнопка оплаты
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Детали заказа',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (widget.type == PaymentType.subscription &&
                widget.plan != null) ...[
              _buildOrderItem(
                'Подписка ${widget.plan!.name}',
                '${widget.plan!.durationDays} дней',
                '${widget.plan!.price.toInt()} ₽',
                Icons.star,
                Colors.amber,
              ),
            ] else if (widget.type == PaymentType.promotion &&
                widget.promotionPackage != null) ...[
              _buildOrderItem(
                'Продвижение ${widget.promotionPackage!.name}',
                '${widget.promotionPackage!.durationDays} дней',
                '${widget.promotionPackage!.price.toInt()} ₽',
                Icons.trending_up,
                Colors.green,
              ),
            ] else if (widget.type == PaymentType.advertisement &&
                widget.advertisement != null) ...[
              _buildOrderItem(
                'Реклама ${widget.advertisement!.title ?? "Без названия"}',
                widget.advertisement!.placement.toString().split('.').last,
                '${widget.advertisement!.price.toInt()} ₽',
                Icons.campaign,
                Colors.purple,
              ),
            ],
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Итого:',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${_getTotalAmount().toInt()} ₽',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(
    String title,
    String subtitle,
    String price,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Способ оплаты',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildPaymentMethodOption(
          PaymentMethod.card,
          'Банковская карта',
          'Visa, MasterCard, МИР',
          Icons.credit_card,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodOption(
          PaymentMethod.applePay,
          'Apple Pay',
          'Быстрая оплата через Apple Pay',
          Icons.apple,
          Colors.black,
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodOption(
          PaymentMethod.googlePay,
          'Google Pay',
          'Быстрая оплата через Google Pay',
          Icons.android,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodOption(
          PaymentMethod.yooMoney,
          'ЮMoney',
          'Оплата через ЮMoney',
          Icons.account_balance_wallet,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedPaymentMethod == method;

    return Card(
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Radio<PaymentMethod>(
                value: method,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                activeColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentProviders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Платежная система',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildProviderOption(
          PaymentProvider.stripe,
          'Stripe',
          'Международная платежная система',
          Icons.payment,
          Colors.purple,
        ),
        const SizedBox(height: 12),
        _buildProviderOption(
          PaymentProvider.yookassa,
          'ЮKassa',
          'Российская платежная система',
          Icons.account_balance,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildProviderOption(
    PaymentProvider provider,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedProvider == provider;

    return Card(
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedProvider = provider;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Radio<PaymentProvider>(
                value: provider,
                groupValue: _selectedProvider,
                onChanged: (value) {
                  setState(() {
                    _selectedProvider = value!;
                  });
                },
                activeColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Обработка платежа...'),
                ],
              )
            : Text(
                'Оплатить ${_getTotalAmount().toInt()} ₽',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  double _getTotalAmount() {
    switch (widget.type) {
      case PaymentType.subscription:
        return widget.plan?.price ?? 0.0;
      case PaymentType.promotion:
        return widget.promotionPackage?.price ?? 0.0;
      case PaymentType.advertisement:
        return widget.advertisement?.price ?? 0.0;
    }
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?['id'];

      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      PaymentResult result;

      switch (widget.type) {
        case PaymentType.subscription:
          if (widget.plan == null) {
            throw Exception('План подписки не выбран');
          }
          result = await _subscriptionService.purchaseSubscription(
            userId: userId,
            planId: widget.plan!.id,
            paymentMethod: _selectedPaymentMethod,
            provider: _selectedProvider,
          );
          break;

        case PaymentType.promotion:
          if (widget.promotionPackage == null) {
            throw Exception('Пакет продвижения не выбран');
          }
          result = await _promotionService.purchasePromotion(
            userId: userId,
            packageId: widget.promotionPackage!.id,
            paymentMethod: _selectedPaymentMethod,
            provider: _selectedProvider,
          );
          break;

        case PaymentType.advertisement:
          if (widget.advertisement == null) {
            throw Exception('Рекламное объявление не выбрано');
          }
          result = await _advertisementService.purchaseAdvertisement(
            userId: userId,
            adId: widget.advertisement!.id,
            paymentMethod: _selectedPaymentMethod,
            provider: _selectedProvider,
          );
          break;
      }

      if (result.success) {
        // Активируем услугу
        bool activationResult = false;

        switch (widget.type) {
          case PaymentType.subscription:
            activationResult = await _subscriptionService.activateSubscription(
              userId: userId,
              planId: widget.plan!.id,
              transactionId: result.transactionId!,
            );
            break;

          case PaymentType.promotion:
            activationResult = await _promotionService.activatePromotion(
              userId: userId,
              packageId: widget.promotionPackage!.id,
              transactionId: result.transactionId!,
            );
            break;

          case PaymentType.advertisement:
            activationResult =
                await _advertisementService.activateAdvertisement(
              adId: widget.advertisement!.id,
              transactionId: result.transactionId!,
            );
            break;
        }

        if (activationResult) {
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          throw Exception('Ошибка активации услуги');
        }
      } else {
        throw Exception(result.errorMessage ?? 'Ошибка платежа');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
