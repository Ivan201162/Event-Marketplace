import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../config/payment_config.dart';
import 'package:flutter/foundation.dart';
import '../../models/subscription.dart';
import 'package:flutter/foundation.dart';
import '../../services/payment_service.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/subscription/subscription_plan_card.dart';
import 'package:flutter/foundation.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({
    super.key,
    required this.userId,
  });
  final String userId;

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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('РњРѕР№ С‚Р°СЂРёС„'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.diamond,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Р’С‹Р±РµСЂРёС‚Рµ РїРѕРґРїРёСЃРєСѓ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'РџРѕР»СѓС‡РёС‚Рµ РґРѕСЃС‚СѓРї Рє СЂР°СЃС€РёСЂРµРЅРЅРѕРјСѓ С„СѓРЅРєС†РёРѕРЅР°Р»Сѓ',
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
                'Р”РѕСЃС‚СѓРїРЅС‹Рµ С‚Р°СЂРёС„С‹:',
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
                                ? 'РђРєС‚РёРІРёСЂРѕРІР°С‚СЊ Р±РµСЃРїР»Р°С‚РЅС‹Р№ С‚Р°СЂРёС„'
                                : 'РћРїР»Р°С‚РёС‚СЊ ${PaymentConfig.subscriptionPlans[_selectedPlan.toString().split('.').last]} в‚Ѕ/РјРµСЃ',
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
                      'РћС‚РјРµРЅРёС‚СЊ РїРѕРґРїРёСЃРєСѓ',
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
                'РџРѕРґРїРёСЃРєР° РїСЂРѕРґР»РµРІР°РµС‚СЃСЏ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё. '
                'Р’С‹ РјРѕР¶РµС‚Рµ РѕС‚РјРµРЅРёС‚СЊ РµС‘ РІ Р»СЋР±РѕРµ РІСЂРµРјСЏ РІ РЅР°СЃС‚СЂРѕР№РєР°С….',
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
                'РўРµРєСѓС‰РёР№ С‚Р°СЂРёС„: ${_getPlanName(subscription.plan)}',
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
            isExpired ? 'РџРѕРґРїРёСЃРєР° РёСЃС‚РµРєР»Р°' : 'РћСЃС‚Р°Р»РѕСЃСЊ РґРЅРµР№: $daysRemaining',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          if (!isExpired) ...[
            const SizedBox(height: 4),
            Text(
              'РЎР»РµРґСѓСЋС‰РµРµ СЃРїРёСЃР°РЅРёРµ: ${_formatDate(subscription.expiresAt)}',
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

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';

  Future<void> _loadCurrentSubscription() async {
    try {
      final subscription = await _paymentService.getUserSubscription(widget.userId);
      setState(() {
        _currentSubscription = subscription;
      });
    } on Exception catch (e) {
      debugPrint('Error loading subscription: $e');
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
    } on Exception {
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
        title: const Text('РћС‚РјРµРЅРёС‚СЊ РїРѕРґРїРёСЃРєСѓ'),
        content: const Text(
          'Р’С‹ СѓРІРµСЂРµРЅС‹, С‡С‚Рѕ С…РѕС‚РёС‚Рµ РѕС‚РјРµРЅРёС‚СЊ РїРѕРґРїРёСЃРєСѓ? '
          'Р”РѕСЃС‚СѓРї Рє РїСЂРµРјРёСѓРј-С„СѓРЅРєС†РёСЏРј Р±СѓРґРµС‚ РїСЂРµРєСЂР°С‰РµРЅ РІ РєРѕРЅС†Рµ С‚РµРєСѓС‰РµРіРѕ РїРµСЂРёРѕРґР°.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('РќРµС‚'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Р”Р°, РѕС‚РјРµРЅРёС‚СЊ'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      // Here you would implement subscription cancellation
      // For now, just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('РџРѕРґРїРёСЃРєР° РѕС‚РјРµРЅРµРЅР°'),
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
            Text('РЈСЃРїРµС€РЅРѕ!'),
          ],
        ),
        content: Text(
          'РџРѕРґРїРёСЃРєР° ${_getPlanName(_selectedPlan!)} СѓСЃРїРµС€РЅРѕ Р°РєС‚РёРІРёСЂРѕРІР°РЅР°!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('РћС‚Р»РёС‡РЅРѕ'),
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
            Text('РћС€РёР±РєР°'),
          ],
        ),
        content: const Text(
          'РџСЂРѕРёР·РѕС€Р»Р° РѕС€РёР±РєР° РїСЂРё РѕР±СЂР°Р±РѕС‚РєРµ РїРѕРґРїРёСЃРєРё. '
          'РџРѕРїСЂРѕР±СѓР№С‚Рµ РµС‰Рµ СЂР°Р· РёР»Рё РѕР±СЂР°С‚РёС‚РµСЃСЊ РІ РїРѕРґРґРµСЂР¶РєСѓ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('РџРѕРЅСЏС‚РЅРѕ'),
          ),
        ],
      ),
    );
  }
}

