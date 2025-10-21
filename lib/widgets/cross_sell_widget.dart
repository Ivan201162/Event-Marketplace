import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cross_sell_suggestion.dart';
import '../services/cross_sell_service.dart';
import 'responsive_layout.dart';

/// Виджет для отображения кросс-селл предложения
class CrossSellSuggestionWidget extends ConsumerWidget {
  const CrossSellSuggestionWidget({super.key, required this.suggestion, this.onSuggestionChanged});
  final CrossSellSuggestion suggestion;
  final VoidCallback? onSuggestionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с статусом
            Row(
              children: [
                Icon(_getSuggestionIcon(), color: suggestion.status.color, size: 24),
                const SizedBox(width: 8),
                Expanded(child: ResponsiveText('Рекомендуем дополнить заказ', isTitle: true)),
                _buildStatusChip(),
              ],
            ),

            const SizedBox(height: 12),

            // Информация о предложении
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: suggestion.status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: suggestion.status.color),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ResponsiveText('Дополнительных услуг:', isSubtitle: true),
                      ResponsiveText(
                        '${suggestion.itemCount}',
                        style:
                            TextStyle(color: suggestion.status.color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ResponsiveText('Общая стоимость:', isSubtitle: true),
                      ResponsiveText(
                        '${suggestion.totalCost.toStringAsFixed(0)} ₽',
                        style:
                            TextStyle(color: suggestion.status.color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Сообщение
            if (suggestion.message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.message, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: ResponsiveText(suggestion.message!, isSubtitle: true)),
                  ],
                ),
              ),
            ],

            // Список рекомендуемых специалистов
            const SizedBox(height: 12),
            ResponsiveText('Рекомендуемые специалисты:', isTitle: true),

            const SizedBox(height: 8),

            ...suggestion.suggestedItems.map(_buildSpecialistCard),

            // Кнопки действий
            if (suggestion.canRespond) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptSuggestion(context, ref),
                      icon: const Icon(Icons.check),
                      label: const Text('Принять все'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectSuggestion(context, ref),
                      icon: const Icon(Icons.close),
                      label: const Text('Отклонить'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
            ],

            // Информация о времени
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                ResponsiveText('Создано: ${_formatDate(suggestion.createdAt)}', isSubtitle: true),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatusChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: suggestion.status.color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: suggestion.status.color),
        ),
        child: Text(
          suggestion.status.displayName,
          style:
              TextStyle(color: suggestion.status.color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildSpecialistCard(CrossSellItem item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Аватар специалиста
            if (item.imageUrl != null) ...[
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(item.imageUrl!),
                onBackgroundImageError: (exception, stackTrace) {},
              ),
              const SizedBox(width: 12),
            ] else ...[
              const CircleAvatar(radius: 20, child: Icon(Icons.person)),
              const SizedBox(width: 12),
            ],

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    item.specialistName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  ResponsiveText(item.categoryName, isSubtitle: true),
                  if (item.description != null) ...[
                    const SizedBox(height: 4),
                    ResponsiveText(item.description!, isSubtitle: true),
                  ],
                ],
              ),
            ),

            if (item.estimatedPrice != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.estimatedPrice!.toStringAsFixed(0)} ₽',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  IconData _getSuggestionIcon() {
    switch (suggestion.status) {
      case CrossSellStatus.pending:
        return Icons.shopping_cart;
      case CrossSellStatus.viewed:
        return Icons.visibility;
      case CrossSellStatus.accepted:
        return Icons.check_circle;
      case CrossSellStatus.rejected:
        return Icons.cancel;
      case CrossSellStatus.expired:
        return Icons.access_time;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else {
      return '${difference.inMinutes}м назад';
    }
  }

  Future<void> _acceptSuggestion(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(crossSellServiceProvider);
      await service.acceptCrossSellSuggestion(
        suggestionId: suggestion.id,
        customerId: 'current_user_id', // TODO(developer): Получить из контекста
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Предложение принято! Созданы бронирования.'),
          backgroundColor: Colors.green,
        ),
      );

      onSuggestionChanged?.call();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    }
  }

  void _rejectSuggestion(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => _RejectSuggestionDialog(
        suggestion: suggestion,
        onRejected: () {
          onSuggestionChanged?.call();
        },
      ),
    );
  }
}

/// Виджет для создания кросс-селл предложения
class CreateCrossSellWidget extends ConsumerStatefulWidget {
  const CreateCrossSellWidget({
    super.key,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    this.onSuggestionCreated,
  });
  final String bookingId;
  final String customerId;
  final String specialistId;
  final VoidCallback? onSuggestionCreated;

  @override
  ConsumerState<CreateCrossSellWidget> createState() => _CreateCrossSellWidgetState();
}

class _CreateCrossSellWidgetState extends ConsumerState<CreateCrossSellWidget> {
  final _messageController = TextEditingController();
  final List<CrossSellItem> _selectedItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendedSpecialists();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.blue),
                const SizedBox(width: 8),
                ResponsiveText('Рекомендовать дополнительные услуги', isTitle: true),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
                'Предложите клиенту дополнительных специалистов для полного комплекта услуг.'),

            const SizedBox(height: 16),

            // Кнопка загрузки рекомендаций
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadRecommendedSpecialists,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isLoading ? 'Загрузка...' : 'Загрузить рекомендации'),
            ),

            // Список рекомендуемых специалистов
            if (_selectedItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              ResponsiveText('Выбранные специалисты:', isTitle: true),
              const SizedBox(height: 8),
              ..._selectedItems.map(_buildSelectedSpecialistCard),
            ],

            // Сообщение
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Сообщение клиенту (необязательно)',
                border: OutlineInputBorder(),
                hintText: 'Добавьте комментарий к предложению...',
              ),
              maxLines: 3,
            ),

            // Кнопка создания предложения
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canCreateSuggestion() ? _createSuggestion : null,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isLoading ? 'Создание...' : 'Создать предложение'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildSelectedSpecialistCard(CrossSellItem item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    item.specialistName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  ResponsiveText(item.categoryName, isSubtitle: true),
                  if (item.estimatedPrice != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${item.estimatedPrice!.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeSpecialist(item),
              icon: const Icon(Icons.remove_circle, color: Colors.red),
            ),
          ],
        ),
      );

  bool _canCreateSuggestion() => _selectedItems.isNotEmpty && !_isLoading;

  Future<void> _loadRecommendedSpecialists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(crossSellServiceProvider);
      final recommendations = await service.getRecommendedSpecialists(
        bookingId: widget.bookingId,
        customerId: widget.customerId,
        specialistId: widget.specialistId,
      );

      setState(() {
        _selectedItems.clear();
        _selectedItems.addAll(recommendations);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки рекомендаций: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeSpecialist(CrossSellItem item) {
    setState(() {
      _selectedItems.remove(item);
    });
  }

  Future<void> _createSuggestion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(crossSellServiceProvider);
      await service.createCrossSellSuggestion(
        bookingId: widget.bookingId,
        customerId: widget.customerId,
        specialistId: widget.specialistId,
        suggestedItems: _selectedItems,
        message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Предложение создано и отправлено клиенту'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onSuggestionCreated?.call();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Диалог для отклонения предложения
class _RejectSuggestionDialog extends StatefulWidget {
  const _RejectSuggestionDialog({required this.suggestion, required this.onRejected});
  final CrossSellSuggestion suggestion;
  final VoidCallback onRejected;

  @override
  State<_RejectSuggestionDialog> createState() => _RejectSuggestionDialogState();
}

class _RejectSuggestionDialogState extends State<_RejectSuggestionDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Отклонить предложение'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Вы уверены, что хотите отклонить это предложение?'),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Причина отклонения (необязательно)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _rejectSuggestion,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Отклонить'),
          ),
        ],
      );

  Future<void> _rejectSuggestion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(crossSellServiceProvider);
      await service.rejectCrossSellSuggestion(
        suggestionId: widget.suggestion.id,
        customerId: 'current_user_id', // TODO(developer): Получить из контекста
        reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Предложение отклонено'), backgroundColor: Colors.orange),
      );

      widget.onRejected();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Провайдер для сервиса кросс-селл
final crossSellServiceProvider = Provider<CrossSellService>((ref) => CrossSellService());
