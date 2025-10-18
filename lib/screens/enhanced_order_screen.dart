import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/enhanced_order.dart';
import 'package:flutter/foundation.dart';
import '../services/enhanced_orders_service.dart';
import 'package:flutter/foundation.dart';
import '../widgets/order_comments_widget.dart';
import 'package:flutter/foundation.dart';
import '../widgets/order_timeline_widget.dart';
import 'package:flutter/foundation.dart';

/// Р Р°СЃС€РёСЂРµРЅРЅС‹Р№ СЌРєСЂР°РЅ Р·Р°СЏРІРєРё
class EnhancedOrderScreen extends ConsumerStatefulWidget {
  const EnhancedOrderScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  ConsumerState<EnhancedOrderScreen> createState() => _EnhancedOrderScreenState();
}

class _EnhancedOrderScreenState extends ConsumerState<EnhancedOrderScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final EnhancedOrdersService _ordersService = EnhancedOrdersService();

  EnhancedOrder? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrder();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РїРѕР»СѓС‡РµРЅРёРµ Р·Р°СЏРІРєРё РїРѕ ID
      // РџРѕРєР° С‡С‚Рѕ СЃРѕР·РґР°С‘Рј Р·Р°РіР»СѓС€РєСѓ
      setState(() {
        _order = _createMockOrder();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  EnhancedOrder _createMockOrder() => EnhancedOrder(
        id: widget.orderId,
        customerId: 'customer_1',
        specialistId: 'specialist_1',
        title: 'РћСЂРіР°РЅРёР·Р°С†РёСЏ СЃРІР°РґСЊР±С‹',
        description:
            'РќСѓР¶РЅР° РїРѕРјРѕС‰СЊ РІ РѕСЂРіР°РЅРёР·Р°С†РёРё СЃРІР°РґРµР±РЅРѕРіРѕ С‚РѕСЂР¶РµСЃС‚РІР° РЅР° 50 С‡РµР»РѕРІРµРє. Р”Р°С‚Р°: 15 РёСЋРЅСЏ 2024 РіРѕРґР°.',
        status: OrderStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        budget: 150000,
        deadline: DateTime.now().add(const Duration(days: 30)),
        location: 'РњРѕСЃРєРІР°, СЂРµСЃС‚РѕСЂР°РЅ "Р—РѕР»РѕС‚РѕР№"',
        category: 'РЎРІР°РґСЊР±С‹',
        priority: OrderPriority.high,
        comments: [
          OrderComment(
            id: '1',
            authorId: 'customer_1',
            text: 'Р”РѕР±СЂРѕ РїРѕР¶Р°Р»РѕРІР°С‚СЊ! Р Р°Рґ СЂР°Р±РѕС‚Р°С‚СЊ СЃ РІР°РјРё РЅР°Рґ СЌС‚РёРј РїСЂРѕРµРєС‚РѕРј.',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          OrderComment(
            id: '2',
            authorId: 'specialist_1',
            text: 'РЎРїР°СЃРёР±Рѕ Р·Р° РґРѕРІРµСЂРёРµ! РќР°С‡РЅС‘Рј СЃ РѕР±СЃСѓР¶РґРµРЅРёСЏ РґРµС‚Р°Р»РµР№.',
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
        ],
        timeline: [
          OrderTimelineEvent(
            id: '1',
            type: OrderTimelineEventType.created,
            title: 'Р—Р°СЏРІРєР° СЃРѕР·РґР°РЅР°',
            description: 'Р—Р°СЏРІРєР° "РћСЂРіР°РЅРёР·Р°С†РёСЏ СЃРІР°РґСЊР±С‹" Р±С‹Р»Р° СЃРѕР·РґР°РЅР°',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            authorId: 'customer_1',
          ),
          OrderTimelineEvent(
            id: '2',
            type: OrderTimelineEventType.accepted,
            title: 'Р—Р°СЏРІРєР° РїСЂРёРЅСЏС‚Р°',
            description: 'РЎРїРµС†РёР°Р»РёСЃС‚ РїСЂРёРЅСЏР» Р·Р°СЏРІРєСѓ Рє РІС‹РїРѕР»РЅРµРЅРёСЋ',
            createdAt: DateTime.now().subtract(const Duration(days: 4)),
            authorId: 'specialist_1',
          ),
          OrderTimelineEvent(
            id: '3',
            type: OrderTimelineEventType.started,
            title: 'Р Р°Р±РѕС‚Р° РЅР°С‡Р°С‚Р°',
            description: 'РЎРїРµС†РёР°Р»РёСЃС‚ РЅР°С‡Р°Р» СЂР°Р±РѕС‚Сѓ РЅР°Рґ Р·Р°СЏРІРєРѕР№',
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
            authorId: 'specialist_1',
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('РћС€РёР±РєР°')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('РћС€РёР±РєР°: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrder,
                child: const Text('РџРѕРІС‚РѕСЂРёС‚СЊ'),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Р—Р°СЏРІРєР° РЅРµ РЅР°Р№РґРµРЅР°')),
        body: const Center(child: Text('Р—Р°СЏРІРєР° РЅРµ РЅР°Р№РґРµРЅР°')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_order!.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ'),
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('РџРѕРґРµР»РёС‚СЊСЃСЏ'),
                ),
              ),
              if (_order!.status == OrderStatus.pending)
                const PopupMenuItem(
                  value: 'cancel',
                  child: ListTile(
                    leading: Icon(Icons.cancel, color: Colors.red),
                    title: Text('РћС‚РјРµРЅРёС‚СЊ', style: TextStyle(color: Colors.red)),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Р”РµС‚Р°Р»Рё', icon: Icon(Icons.info)),
            Tab(text: 'РСЃС‚РѕСЂРёСЏ', icon: Icon(Icons.timeline)),
            Tab(text: 'РљРѕРјРјРµРЅС‚Р°СЂРёРё', icon: Icon(Icons.comment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildTimelineTab(),
          _buildCommentsTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // РћСЃРЅРѕРІРЅР°СЏ РёРЅС„РѕСЂРјР°С†РёСЏ
            _buildBasicInfo(),
            const SizedBox(height: 20),

            // Р‘СЋРґР¶РµС‚ Рё РґРµРґР»Р°Р№РЅ
            _buildBudgetAndDeadline(),
            const SizedBox(height: 20),

            // РЎС‚Р°С‚СѓСЃ Рё РїСЂРёРѕСЂРёС‚РµС‚
            _buildStatusAndPriority(),
            const SizedBox(height: 20),

            // Р’Р»РѕР¶РµРЅРёСЏ
            _buildAttachments(),
            const SizedBox(height: 20),

            // Р”РµР№СЃС‚РІРёСЏ
            _buildActions(),
          ],
        ),
      );

  Widget _buildTimelineTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: OrderTimelineWidget(timeline: _order!.timeline),
      );

  Widget _buildCommentsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: OrderCommentsWidget(
          comments: _order!.comments,
          currentUserId: 'current_user', // TODO: РџРѕР»СѓС‡РёС‚СЊ РёР· РїСЂРѕРІР°Р№РґРµСЂР°
          onAddComment: _addComment,
          onAddAttachment: _addAttachment,
        ),
      );

  Widget _buildBasicInfo() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'РћРїРёСЃР°РЅРёРµ Р·Р°СЏРІРєРё',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _order!.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _order!.location ?? 'РњРµСЃС‚РѕРїРѕР»РѕР¶РµРЅРёРµ РЅРµ СѓРєР°Р·Р°РЅРѕ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.category, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _order!.category ?? 'РљР°С‚РµРіРѕСЂРёСЏ РЅРµ СѓРєР°Р·Р°РЅР°',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildBudgetAndDeadline() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Р‘СЋРґР¶РµС‚ Рё СЃСЂРѕРєРё',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Р‘СЋРґР¶РµС‚',
                    _order!.budget != null ? '${_order!.budget!.toInt()}в‚Ѕ' : 'РќРµ СѓРєР°Р·Р°РЅ',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Р”РµРґР»Р°Р№РЅ',
                    _order!.deadline != null
                        ? '${_order!.deadline!.day}.${_order!.deadline!.month}.${_order!.deadline!.year}'
                        : 'РќРµ СѓРєР°Р·Р°РЅ',
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatusAndPriority() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'РЎС‚Р°С‚СѓСЃ Рё РїСЂРёРѕСЂРёС‚РµС‚',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'РЎС‚Р°С‚СѓСЃ',
                    _order!.status.displayName,
                    _order!.status.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    'РџСЂРёРѕСЂРёС‚РµС‚',
                    _order!.priority.displayName,
                    _order!.priority.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildAttachments() {
    if (_order!.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Р’Р»РѕР¶РµРЅРёСЏ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _order!.attachments.map(_buildAttachmentChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() => Column(
        children: [
          if (_order!.status == OrderStatus.pending) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _acceptOrder,
                icon: const Icon(Icons.check),
                label: const Text('РџСЂРёРЅСЏС‚СЊ Р·Р°СЏРІРєСѓ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_order!.status == OrderStatus.accepted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startOrder,
                icon: const Icon(Icons.play_arrow),
                label: const Text('РќР°С‡Р°С‚СЊ СЂР°Р±РѕС‚Сѓ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_order!.status == OrderStatus.inProgress) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _completeOrder,
                icon: const Icon(Icons.check_circle),
                label: const Text('Р—Р°РІРµСЂС€РёС‚СЊ Р·Р°СЏРІРєСѓ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _contactUser,
              icon: const Icon(Icons.message),
              label: const Text('РќР°РїРёСЃР°С‚СЊ СЃРѕРѕР±С‰РµРЅРёРµ'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );

  Widget _buildStatusCard(String title, String value, String color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(int.parse(color.replaceFirst('#', '0xFF'))).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(int.parse(color.replaceFirst('#', '0xFF'))).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );

  Widget _buildAttachmentChip(OrderAttachment attachment) => GestureDetector(
        onTap: () {
          // TODO: РћС‚РєСЂС‹С‚СЊ РІР»РѕР¶РµРЅРёРµ
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                attachment.type.icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                attachment.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editOrder();
        break;
      case 'share':
        _shareOrder();
        break;
      case 'cancel':
        _cancelOrder();
        break;
    }
  }

  void _editOrder() {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ СЂРµРґР°РєС‚РёСЂРѕРІР°РЅРёРµ Р·Р°СЏРІРєРё
    debugPrint('Р РµРґР°РєС‚РёСЂРѕРІР°РЅРёРµ Р·Р°СЏРІРєРё');
  }

  void _shareOrder() {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ С€Р°СЂРёРЅРі Р·Р°СЏРІРєРё
    debugPrint('РЁР°СЂРёРЅРі Р·Р°СЏРІРєРё');
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('РћС‚РјРµРЅРёС‚СЊ Р·Р°СЏРІРєСѓ'),
        content: const Text('Р’С‹ СѓРІРµСЂРµРЅС‹, С‡С‚Рѕ С…РѕС‚РёС‚Рµ РѕС‚РјРµРЅРёС‚СЊ СЌС‚Сѓ Р·Р°СЏРІРєСѓ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('РќРµС‚'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РѕС‚РјРµРЅСѓ Р·Р°СЏРІРєРё
            },
            child: const Text('Р”Р°, РѕС‚РјРµРЅРёС‚СЊ'),
          ),
        ],
      ),
    );
  }

  void _acceptOrder() {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РїСЂРёРЅСЏС‚РёРµ Р·Р°СЏРІРєРё
    debugPrint('РџСЂРёРЅСЏС‚РёРµ Р·Р°СЏРІРєРё');
  }

  void _startOrder() {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РЅР°С‡Р°Р»Рѕ СЂР°Р±РѕС‚С‹
    debugPrint('РќР°С‡Р°Р»Рѕ СЂР°Р±РѕС‚С‹');
  }

  void _completeOrder() {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ Р·Р°РІРµСЂС€РµРЅРёРµ Р·Р°СЏРІРєРё
    debugPrint('Р—Р°РІРµСЂС€РµРЅРёРµ Р·Р°СЏРІРєРё');
  }

  void _contactUser() {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РїРµСЂРµС…РѕРґ Рє С‡Р°С‚Сѓ
    debugPrint('РџРµСЂРµС…РѕРґ Рє С‡Р°С‚Сѓ');
  }

  void _addComment(String text, bool isInternal) {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РґРѕР±Р°РІР»РµРЅРёРµ РєРѕРјРјРµРЅС‚Р°СЂРёСЏ
    debugPrint('Р”РѕР±Р°РІР»РµРЅРёРµ РєРѕРјРјРµРЅС‚Р°СЂРёСЏ: $text (РІРЅСѓС‚СЂРµРЅРЅРёР№: $isInternal)');
  }

  void _addAttachment(OrderAttachment attachment) {
    // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РґРѕР±Р°РІР»РµРЅРёРµ РІР»РѕР¶РµРЅРёСЏ
    debugPrint('Р”РѕР±Р°РІР»РµРЅРёРµ РІР»РѕР¶РµРЅРёСЏ: ${attachment.name}');
  }
}

