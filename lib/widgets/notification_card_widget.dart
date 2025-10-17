import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_notification.dart';

/// Виджет карточки уведомления
class NotificationCardWidget extends ConsumerStatefulWidget {
  const NotificationCardWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onArchive,
    this.onDelete,
  });

  final EnhancedNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  ConsumerState<NotificationCardWidget> createState() => _NotificationCardWidgetState();
}

class _NotificationCardWidgetState extends ConsumerState<NotificationCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: widget.notification.isRead ? 1 : 3,
            color: widget.notification.isRead
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.primaryContainer.withValues(0.1),
            child: InkWell(
              onTap: () {
                _animationController.forward().then((_) {
                  _animationController.reverse();
                });
                widget.onTap?.call();
              },
              onLongPress: _showOptionsMenu,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNotificationHeader(),
                    const SizedBox(height: 8),
                    _buildNotificationContent(),
                    if (_isExpanded) _buildNotificationDetails(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildNotificationHeader() => Row(
        children: [
          _buildNotificationIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.notification.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: widget.notification.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      widget.notification.type.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getTypeColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(widget.notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildNotificationActions(),
        ],
      );

  Widget _buildNotificationIcon() => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getTypeColor().withValues(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            widget.notification.type.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      );

  Widget _buildNotificationContent() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.notification.body,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            maxLines: _isExpanded ? null : 2,
            overflow: _isExpanded ? null : TextOverflow.ellipsis,
          ),
          if (widget.notification.senderName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.notification.senderAvatar != null)
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: CachedNetworkImageProvider(
                      widget.notification.senderAvatar!,
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 12,
                    child: Text(
                      widget.notification.senderName![0].toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  'от ${widget.notification.senderName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      );

  Widget _buildNotificationDetails() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          if (widget.notification.actionUrl != null)
            _buildDetailRow(
              'Действие',
              'Нажмите для перехода',
              Icons.open_in_new,
            ),
          if (widget.notification.category != null)
            _buildDetailRow(
              'Категория',
              widget.notification.category!,
              Icons.category,
            ),
          _buildDetailRow(
            'Приоритет',
            widget.notification.priority.displayName,
            Icons.priority_high,
          ),
          if (widget.notification.expiresAt != null)
            _buildDetailRow(
              'Истекает',
              _formatDate(widget.notification.expiresAt!),
              Icons.schedule,
            ),
          if (widget.notification.readAt != null)
            _buildDetailRow(
              'Прочитано',
              _formatDate(widget.notification.readAt!),
              Icons.check_circle,
            ),
        ],
      );

  Widget _buildDetailRow(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildNotificationActions() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.notification.isRead)
            IconButton(
              onPressed: widget.onMarkAsRead,
              icon: const Icon(Icons.mark_email_read),
              tooltip: 'Отметить как прочитанное',
              iconSize: 20,
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'expand',
                child: Row(
                  children: [
                    Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                    const SizedBox(width: 8),
                    Text(_isExpanded ? 'Свернуть' : 'Развернуть'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive),
                    SizedBox(width: 8),
                    Text('Архивировать'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Удалить', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert, size: 20),
          ),
        ],
      );

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text('Отметить как прочитанное'),
              onTap: () {
                Navigator.pop(context);
                widget.onMarkAsRead?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Архивировать'),
              onTap: () {
                Navigator.pop(context);
                widget.onArchive?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'expand':
        setState(() {
          _isExpanded = !_isExpanded;
        });
        break;
      case 'archive':
        widget.onArchive?.call();
        break;
      case 'delete':
        widget.onDelete?.call();
        break;
    }
  }

  Color _getTypeColor() {
    switch (widget.notification.type.color) {
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'grey':
        return Colors.grey;
      case 'yellow':
        return Colors.yellow;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'Только что';
    }
  }
}
