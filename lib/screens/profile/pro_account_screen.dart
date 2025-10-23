import 'package:flutter/material.dart';
import '../../models/user_profile_enhanced.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/pro/analytics_widget.dart';
import '../../widgets/pro/promotion_widget.dart';
import '../../widgets/pro/monetization_widget.dart';

/// Экран PRO-аккаунта
class ProAccountScreen extends StatefulWidget {
  const ProAccountScreen({super.key});

  @override
  State<ProAccountScreen> createState() => _ProAccountScreenState();
}

class _ProAccountScreenState extends State<ProAccountScreen> {
  final _userProfileService = UserProfileService();

  UserProfileEnhanced? _currentProfile;
  bool _isLoading = false;
  bool _isProAccount = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Загрузить профиль пользователя
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _userProfileService.getCurrentUserProfile();
      if (profile != null) {
        setState(() {
          _currentProfile = profile;
          _isProAccount = profile.isProAccount;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки профиля: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Переключить PRO-аккаунт
  Future<void> _toggleProAccount() async {
    if (_currentProfile == null) return;

    setState(() => _isLoading = true);

    try {
      await _userProfileService.toggleProAccount(
        _currentProfile!.id,
        !_isProAccount,
      );
      
      setState(() => _isProAccount = !_isProAccount);
      
      _showSuccessSnackBar(
        _isProAccount 
            ? 'PRO-аккаунт активирован' 
            : 'PRO-аккаунт деактивирован',
      );
    } catch (e) {
      _showErrorSnackBar('Ошибка переключения PRO-аккаунта: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Настроить специализацию
  Future<void> _setupSpecialization() async {
    // TODO: Реализовать настройку специализации
    _showInfoSnackBar('Настройка специализации будет реализована');
  }

  /// Управление портфолио
  Future<void> _managePortfolio() async {
    // TODO: Реализовать управление портфолио
    _showInfoSnackBar('Управление портфолио будет реализовано');
  }

  /// Настроить цены
  Future<void> _setupPricing() async {
    // TODO: Реализовать настройку цен
    _showInfoSnackBar('Настройка цен будет реализована');
  }

  /// Просмотреть аналитику
  Future<void> _viewAnalytics() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AnalyticsWidget(),
      ),
    );
  }

  /// Управление продвижением
  Future<void> _managePromotion() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PromotionWidget(),
      ),
    );
  }

  /// Настроить монетизацию
  Future<void> _setupMonetization() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MonetizationWidget(),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'PRO-аккаунт'),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Статус PRO-аккаунта
            _buildProStatusSection(),
            const SizedBox(height: 16),

            if (_isProAccount) ...[
              // Специализация
              _buildSpecializationSection(),
              const SizedBox(height: 16),

              // Портфолио
              _buildPortfolioSection(),
              const SizedBox(height: 16),

              // Цены
              _buildPricingSection(),
              const SizedBox(height: 16),

              // Аналитика
              _buildAnalyticsSection(),
              const SizedBox(height: 16),

              // Продвижение
              _buildPromotionSection(),
              const SizedBox(height: 16),

              // Монетизация
              _buildMonetizationSection(),
            ] else ...[
              // Преимущества PRO
              _buildProBenefitsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProStatusSection() {
    return Card(
      color: _isProAccount ? Colors.amber[50] : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isProAccount ? Icons.star : Icons.star_border,
                  color: _isProAccount ? Colors.amber : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isProAccount ? 'PRO-аккаунт активен' : 'Обычный аккаунт',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isProAccount 
                            ? 'Вы используете все возможности PRO' 
                            : 'Активируйте PRO для расширенных функций',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleProAccount,
                icon: Icon(_isProAccount ? Icons.cancel : Icons.star),
                label: Text(_isProAccount ? 'Деактивировать PRO' : 'Активировать PRO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProAccount ? Colors.red : Colors.amber,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecializationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Специализация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Настроить специализацию'),
              subtitle: const Text('Укажите вашу область деятельности'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _setupSpecialization,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Портфолио',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Управление портфолио'),
              subtitle: const Text('Добавьте работы в портфолио'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _managePortfolio,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Цены и услуги',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Настроить цены'),
              subtitle: const Text('Установите стоимость ваших услуг'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _setupPricing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Аналитика',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Просмотр аналитики'),
              subtitle: const Text('Статистика профиля и активности'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _viewAnalytics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Продвижение',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Управление продвижением'),
              subtitle: const Text('Платное продвижение и VIP-статус'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _managePromotion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonetizationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Монетизация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Настроить монетизацию'),
              subtitle: const Text('Платные сторис, донаты, подписки'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _setupMonetization,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProBenefitsSection() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Преимущества PRO-аккаунта',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              '• Указание специализации и портфолио\n'
              '• Настройка цен и услуг\n'
              '• Детальная аналитика профиля\n'
              '• Платное продвижение профиля\n'
              '• VIP-статус с приоритетной выдачей\n'
              '• Монетизация контента\n'
              '• Платные сторис и подписки\n'
              '• Система донатов\n'
              '• Приоритетные отклики',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleProAccount,
                icon: const Icon(Icons.star),
                label: const Text('Активировать PRO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
