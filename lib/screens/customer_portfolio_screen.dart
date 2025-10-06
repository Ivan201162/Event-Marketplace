import 'package:flutter/material.dart';

import '../models/customer_portfolio.dart';
import '../models/order_history.dart';
import '../services/auth_service.dart';
import '../services/customer_portfolio_service.dart';

/// Экран портфолио заказчика
class CustomerPortfolioScreen extends StatefulWidget {
  const CustomerPortfolioScreen({super.key});

  @override
  State<CustomerPortfolioScreen> createState() =>
      _CustomerPortfolioScreenState();
}

class _CustomerPortfolioScreenState extends State<CustomerPortfolioScreen>
    with TickerProviderStateMixin {
  final CustomerPortfolioService _portfolioService = CustomerPortfolioService();
  final AuthService _authService = AuthService();

  CustomerPortfolio? _portfolio;
  List<OrderHistory> _orderHistory = [];
  Map<String, dynamic> _stats = {};
  List<String> _recommendations = [];
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPortfolio();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPortfolio() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      final portfolio =
          await _portfolioService.getCustomerPortfolio(currentUser.uid);
      if (portfolio == null) {
        throw Exception('Портфолио не найдено');
      }

      final orderHistory =
          await _portfolioService.getOrderHistory(currentUser.uid);
      final stats = await _portfolioService.getPortfolioStats(currentUser.uid);
      final recommendations =
          await _portfolioService.getRecommendations(currentUser.uid);

      setState(() {
        _portfolio = portfolio;
        _orderHistory = orderHistory;
        _stats = stats;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Мой профиль'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Профиль'),
              Tab(icon: Icon(Icons.history), text: 'История'),
              Tab(icon: Icon(Icons.favorite), text: 'Избранное'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Годовщины'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfileTab(),
                      _buildOrderHistoryTab(),
                      _buildFavoritesTab(),
                      _buildAnniversariesTab(),
                    ],
                  ),
      );

  Widget _buildErrorWidget() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPortfolio,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );

  Widget _buildProfileTab() {
    if (_portfolio == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildRecommendations(),
          const SizedBox(height: 24),
          _buildNotesSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: _portfolio!.avatarUrl != null
                    ? NetworkImage(_portfolio!.avatarUrl!)
                    : null,
                child: _portfolio!.avatarUrl == null
                    ? Text(
                        _portfolio!.name.isNotEmpty
                            ? _portfolio!.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _portfolio!.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _portfolio!.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    if (_portfolio!.phoneNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _portfolio!.phoneNumber!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                    if (_portfolio!.yearsMarried != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'В браке ${_portfolio!.yearsMarried} лет',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.purple,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildStatsCards() => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard(
            'Заказов',
            '${_stats['totalOrders'] ?? 0}',
            Icons.shopping_bag,
            Colors.blue,
          ),
          _buildStatCard(
            'Потрачено',
            '${(_stats['totalSpent'] ?? 0).toStringAsFixed(0)} ₽',
            Icons.monetization_on,
            Colors.green,
          ),
          _buildStatCard(
            'Избранных',
            '${_stats['favoriteSpecialistsCount'] ?? 0}',
            Icons.favorite,
            Colors.red,
          ),
          _buildStatCard(
            'Годовщин',
            '${_stats['anniversariesCount'] ?? 0}',
            Icons.calendar_today,
            Colors.orange,
          ),
        ],
      );

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildRecommendations() {
    if (_recommendations.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Рекомендации',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._recommendations.map(
              (recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.note, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    'Заметки',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _editNotes,
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _portfolio?.notes ?? 'Заметок пока нет',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: _portfolio?.notes == null
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: _portfolio?.notes == null ? Colors.grey : null,
                    ),
              ),
            ],
          ),
        ),
      );

  Widget _buildOrderHistoryTab() {
    if (_orderHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'История заказов пуста',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Ваши заказы будут отображаться здесь',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orderHistory.length,
      itemBuilder: (context, index) {
        final order = _orderHistory[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(OrderHistory order) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.serviceName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.specialistName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    order.formattedDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.monetization_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.formattedPrice,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                  ),
                ],
              ),
              if (order.hadDiscount) ...[
                const SizedBox(height: 4),
                Text(
                  'Скидка: ${order.discountAmount.toStringAsFixed(0)} ₽',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  order.notes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildFavoritesTab() {
    final favorites = _portfolio?.favoriteSpecialists ?? [];

    if (favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Избранных специалистов нет',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Добавляйте специалистов в избранное',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final specialistId = favorites[index];
        return _buildFavoriteCard(specialistId);
      },
    );
  }

  Widget _buildFavoriteCard(String specialistId) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.purple,
            child: Icon(Icons.person, color: Colors.white),
          ),
          title: Text('Специалист $specialistId'),
          subtitle: const Text('Нажмите для просмотра профиля'),
          trailing: IconButton(
            onPressed: () => _removeFromFavorites(specialistId),
            icon: const Icon(Icons.favorite, color: Colors.red),
          ),
          onTap: () {
            // TODO(developer): Переход к профилю специалиста
          },
        ),
      );

  Widget _buildAnniversariesTab() {
    final anniversaries = _portfolio?.anniversaries ?? [];
    final upcomingAnniversaries = _portfolio?.upcomingAnniversaries ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upcomingAnniversaries.isNotEmpty) ...[
            Text(
              'Ближайшие годовщины',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...upcomingAnniversaries
                .map((anniversary) => _buildAnniversaryCard(anniversary, true)),
            const SizedBox(height: 24),
          ],
          Text(
            'Все годовщины',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (anniversaries.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Годовщин не добавлено',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...anniversaries.map(
              (anniversary) => _buildAnniversaryCard(anniversary, false),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addAnniversary,
            icon: const Icon(Icons.add),
            label: const Text('Добавить годовщину'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnniversaryCard(DateTime anniversary, bool isUpcoming) {
    final now = DateTime.now();
    final thisYear = DateTime(now.year, anniversary.month, anniversary.day);
    final daysUntil = thisYear.difference(now).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isUpcoming ? Colors.orange[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUpcoming ? Colors.orange : Colors.purple,
          child: const Icon(
            Icons.cake,
            color: Colors.white,
          ),
        ),
        title: Text(
          '${anniversary.day.toString().padLeft(2, '0')}.${anniversary.month.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontWeight: isUpcoming ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: isUpcoming
            ? Text('Через $daysUntil дней')
            : Text('${anniversary.year}'),
        trailing: IconButton(
          onPressed: () => _removeAnniversary(anniversary),
          icon: const Icon(Icons.delete, color: Colors.red),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _editNotes() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final controller = TextEditingController(text: _portfolio?.notes ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать заметки'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Введите ваши заметки...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _portfolioService.updateNotes(currentUser.uid, result);
        await _loadPortfolio();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Заметки сохранены')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }

  Future<void> _removeFromFavorites(String specialistId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      await _portfolioService.removeFromFavorites(
        currentUser.uid,
        specialistId,
      );
      await _loadPortfolio();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Удалено из избранного')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _addAnniversary() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      try {
        await _portfolioService.addAnniversary(currentUser.uid, date);
        await _loadPortfolio();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Годовщина добавлена')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }

  Future<void> _removeAnniversary(DateTime anniversary) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить годовщину'),
        content: const Text('Вы уверены, что хотите удалить эту годовщину?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await _portfolioService.removeAnniversary(currentUser.uid, anniversary);
        await _loadPortfolio();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Годовщина удалена')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }
}
