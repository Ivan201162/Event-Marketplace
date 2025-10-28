import 'package:event_marketplace_app/services/news_feed_service.dart';
import 'package:flutter/material.dart';

/// Виджет для управления подписками на специалистов
class SpecialistSubscriptionWidget extends StatefulWidget {
  const SpecialistSubscriptionWidget(
      {required this.userId, super.key, this.onSubscriptionChanged,});

  final String userId;
  final VoidCallback? onSubscriptionChanged;

  @override
  State<SpecialistSubscriptionWidget> createState() =>
      _SpecialistSubscriptionWidgetState();
}

class _SpecialistSubscriptionWidgetState
    extends State<SpecialistSubscriptionWidget> {
  final NewsFeedService _newsService = NewsFeedService();

  List<String> _subscriptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (_isLoading) _buildLoading(),
              if (_error != null) _buildError(),
              if (!_isLoading && _error == null) _buildContent(),
            ],
          ),
        ),
      );

  Widget _buildHeader() => Row(
        children: [
          const Icon(Icons.subscriptions, color: Colors.blue),
          const SizedBox(width: 8),
          const Text(
            'Подписки на специалистов',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_subscriptions.isNotEmpty)
            Text(
              '${_subscriptions.length} подписок',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
        ],
      );

  Widget _buildLoading() => const Center(
        child: Padding(
            padding: EdgeInsets.all(32), child: CircularProgressIndicator(),),
      );

  Widget _buildError() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child:
                  Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            ),
            TextButton(
                onPressed: _loadSubscriptions, child: const Text('Повторить'),),
          ],
        ),
      );

  Widget _buildContent() {
    if (_subscriptions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildSubscriptionsList(),
        const SizedBox(height: 16),
        _buildAddSubscriptionButton(),
      ],
    );
  }

  Widget _buildEmptyState() => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.subscriptions_outlined,
                size: 64, color: Colors.grey.shade400,),
            const SizedBox(height: 16),
            Text(
              'Нет подписок',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,),
            ),
            const SizedBox(height: 8),
            Text(
              'Подпишитесь на специалистов, чтобы видеть их новости в ленте',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildAddSubscriptionButton(),
          ],
        ),
      );

  Widget _buildSubscriptionsList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ваши подписки:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
          const SizedBox(height: 8),
          ...(_subscriptions.map(_buildSubscriptionItem)),
        ],
      );

  Widget _buildSubscriptionItem(String specialistId) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              specialistId.isNotEmpty ? specialistId[0].toUpperCase() : '?',
              style: TextStyle(
                  color: Colors.blue.shade700, fontWeight: FontWeight.bold,),
            ),
          ),
          title: Text('Специалист $specialistId',
              style: const TextStyle(fontWeight: FontWeight.bold),),
          subtitle: const Text('Подписан'),
          trailing: IconButton(
            onPressed: () => _unsubscribeFromSpecialist(specialistId),
            icon: const Icon(Icons.unsubscribe, color: Colors.red),
            tooltip: 'Отписаться',
          ),
        ),
      );

  Widget _buildAddSubscriptionButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showAddSubscriptionDialog,
          icon: const Icon(Icons.add),
          label: const Text('Подписаться на специалиста'),
        ),
      );

  // ========== МЕТОДЫ ==========

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subscriptions =
          await _newsService.getUserSubscriptions(widget.userId);
      setState(() {
        _subscriptions = subscriptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки подписок: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _unsubscribeFromSpecialist(String specialistId) async {
    try {
      await _newsService.unsubscribeFromSpecialist(widget.userId, specialistId);

      setState(() {
        _subscriptions.remove(specialistId);
      });

      if (widget.onSubscriptionChanged != null) {
        widget.onSubscriptionChanged!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отписка от специалиста выполнена'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text('Ошибка отписки: $e'), backgroundColor: Colors.red,),);
      }
    }
  }

  void _showAddSubscriptionDialog() {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подписаться на специалиста'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Введите ID специалиста для подписки:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'ID специалиста',
                border: OutlineInputBorder(),
                hintText: 'Например: specialist_123',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),),
          ElevatedButton(
            onPressed: () {
              final specialistId = controller.text.trim();
              if (specialistId.isNotEmpty) {
                _subscribeToSpecialist(specialistId);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Подписаться'),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribeToSpecialist(String specialistId) async {
    try {
      await _newsService.subscribeToSpecialist(widget.userId, specialistId);

      setState(() {
        if (!_subscriptions.contains(specialistId)) {
          _subscriptions.add(specialistId);
        }
      });

      if (widget.onSubscriptionChanged != null) {
        widget.onSubscriptionChanged!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Подписка на специалиста выполнена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text('Ошибка подписки: $e'), backgroundColor: Colors.red,),);
      }
    }
  }
}
