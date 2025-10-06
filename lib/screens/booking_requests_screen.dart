import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../providers/auth_providers.dart';
import '../providers/firestore_providers.dart';
import '../services/discount_recommendation_service.dart';
import '../services/notification_service.dart';

class BookingRequestsScreen extends ConsumerStatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  ConsumerState<BookingRequestsScreen> createState() =>
      _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends ConsumerState<BookingRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DiscountRecommendationService _recommendationService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _recommendationService =
        DiscountRecommendationService(NotificationService());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Используем тестовые данные для демонстрации
    final testBookings = [
      Booking(
        id: 'request_1',
        customerId: 'customer_1',
        specialistId: 'specialist_1',
        eventDate: DateTime.now().add(const Duration(days: 10)),
        totalPrice: 35000,
        prepayment: 17500,
        status: BookingStatus.pending,
        message: 'Свадьба в стиле "Великий Гэтсби"',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Booking(
        id: 'request_2',
        customerId: 'customer_2',
        specialistId: 'specialist_1',
        eventDate: DateTime.now().add(const Duration(days: 21)),
        totalPrice: 28000,
        prepayment: 14000,
        status: BookingStatus.pending,
        message: 'Корпоратив IT-компании',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки на бронирование'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Новые', icon: Icon(Icons.new_releases)),
            Tab(text: 'Подтвержденные', icon: Icon(Icons.check_circle)),
            Tab(text: 'Отклоненные', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(currentUser.id, 'pending'),
          _buildBookingsList(currentUser.id, 'confirmed'),
          _buildBookingsList(currentUser.id, 'rejected'),
        ],
      ),
    );
  }

  Widget _buildBookingsList(String specialistId, String status) {
    final bookingsAsync = ref.watch(bookingsBySpecialistProvider(specialistId));

    return bookingsAsync.when(
      data: (bookings) {
        final filteredBookings = bookings
            .where((booking) => booking.status == status)
            .cast<Booking>()
            .toList();

        if (filteredBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(status),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(bookingsBySpecialistProvider(specialistId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredBookings.length,
            itemBuilder: (context, index) {
              final booking = filteredBookings[index];
              return _buildBookingCard(booking);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(bookingsBySpecialistProvider(specialistId));
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с датой и временем
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.title ?? 'Без названия',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(booking.eventDate),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: _getStatusColor(booking.status)),
                    ),
                    child: Text(
                      _getStatusText(booking.status),
                      style: TextStyle(
                        color: _getStatusColor(booking.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Информация о заказчике
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Заказчик: ${booking.customerName ?? 'Не указан'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              if (booking.customerPhone != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      booking.customerPhone!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],

              if (booking.customerEmail != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      booking.customerEmail!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Описание события
              if (booking.description != null) ...[
                Text(
                  'Описание:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
              ],

              // Стоимость
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Стоимость:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (booking.hasDiscount) ...[
                        Text(
                          '${booking.totalPrice.toStringAsFixed(0)} ₽',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey[600],
                                  ),
                        ),
                        Text(
                          '${booking.effectivePrice.toStringAsFixed(0)} ₽',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                        ),
                      ] else
                        Text(
                          '${booking.totalPrice.toStringAsFixed(0)} ₽',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                    ],
                  ),
                ],
              ),

              // Информация о скидке
              if (booking.hasDiscount) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_offer,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Скидка ${booking.discount!.toStringAsFixed(0)}% (${booking.discountAmount.toStringAsFixed(0)} ₽)',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if ((booking.prepayment ?? 0) > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Аванс:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    Text(
                      '${(booking.prepayment ?? 0).toStringAsFixed(0)} ₽',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Действия для новых заявок
              if (booking.status == 'pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectBooking(booking),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Отклонить'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _offerDiscount(booking),
                        icon: const Icon(Icons.local_offer, size: 16),
                        label: const Text('Скидка'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmBooking(booking),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Подтвердить'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRecommendations(booking),
                        icon: const Icon(Icons.lightbulb, size: 16),
                        label: const Text('Рекомендации'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    if (_recommendationService
                        .shouldOfferDiscount(booking)) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _applyRecommendedDiscount(booking),
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Авто-скидка'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple,
                            side: const BorderSide(color: Colors.purple),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Действия для подтвержденных заявок
              if (booking.status == 'confirmed') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewBookingDetails(booking),
                        icon: const Icon(Icons.info, size: 16),
                        label: const Text('Подробности'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _contactCustomer(booking),
                        icon: const Icon(Icons.message, size: 16),
                        label: const Text('Связаться'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  Future<void> _confirmBooking(Booking booking) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateBookingStatus(booking.id, 'confirmed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заявка подтверждена'),
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }

  Future<void> _rejectBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонить заявку'),
        content: const Text('Вы уверены, что хотите отклонить эту заявку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.updateBookingStatus(booking.id, 'rejected');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заявка отклонена'),
              backgroundColor: Colors.orange,
            ),
          );
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
      }
    }
  }

  void _viewBookingDetails(Booking booking) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(booking.title ?? 'Без названия'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Дата и время:',
                _formatDateTime(booking.eventDate),
              ),
              _buildDetailRow('Заказчик:', booking.customerName ?? 'Не указан'),
              if (booking.customerPhone != null)
                _buildDetailRow('Телефон:', booking.customerPhone!),
              if (booking.customerEmail != null)
                _buildDetailRow('Email:', booking.customerEmail!),
              if (booking.description != null)
                _buildDetailRow('Описание:', booking.description!),
              _buildDetailRow(
                'Стоимость:',
                '${booking.totalPrice.toStringAsFixed(0)} ₽',
              ),
              if ((booking.prepayment ?? 0) > 0)
                _buildDetailRow(
                  'Аванс:',
                  '${(booking.prepayment ?? 0).toStringAsFixed(0)} ₽',
                ),
              _buildDetailRow('Статус:', _getStatusText(booking.status)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _contactCustomer(Booking booking) {
    // TODO(developer): Реализовать переход в чат с заказчиком
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Переход в чат будет реализован позже')),
    );
  }

  Future<void> _offerDiscount(Booking booking) async {
    final discountController = TextEditingController();
    double? discountPercent;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Предложить скидку'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Текущая стоимость: ${booking.totalPrice.toStringAsFixed(0)} ₽',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Размер скидки (%)',
                  hintText: 'Введите процент скидки',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                onChanged: (value) {
                  final discount = double.tryParse(value);
                  if (discount != null && discount >= 0 && discount <= 100) {
                    setState(() {
                      discountPercent = discount;
                    });
                  } else {
                    setState(() {
                      discountPercent = null;
                    });
                  }
                },
              ),
              if (discountPercent != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Скидка:'),
                          Text(
                            '${discountPercent!.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Экономия:'),
                          Text(
                            '${(booking.totalPrice * discountPercent! / 100).toStringAsFixed(0)} ₽',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Итоговая цена:'),
                          Text(
                            '${(booking.totalPrice * (1 - discountPercent! / 100)).toStringAsFixed(0)} ₽',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: discountPercent != null
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: const Text('Применить скидку'),
            ),
          ],
        ),
      ),
    );

    if (result ?? false && discountPercent != null) {
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        final updatedBooking = booking.applyDiscount(discountPercent!);

        await firestoreService.updateBooking(
          booking.id,
          {
            'discount': discountPercent,
            'finalPrice': updatedBooking.finalPrice,
            'updatedAt': DateTime.now(),
          },
        );

        // Отправляем уведомление заказчику
        await _recommendationService.sendDiscountNotification(updatedBooking);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Скидка ${discountPercent!.toStringAsFixed(0)}% применена',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка применения скидки: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRecommendations(Booking booking) async {
    final suggestions =
        await _recommendationService.analyzeBookingAndSuggest(booking);

    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Рекомендации по заявке'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Анализ заявки:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text('• Стоимость: ${booking.totalPrice.toStringAsFixed(0)}₽'),
                Text('• Участники: ${booking.participantsCount} чел.'),
                Text('• Дата: ${_formatDateTime(booking.eventDate)}'),
                const SizedBox(height: 16),
                if (suggestions.isNotEmpty) ...[
                  Text(
                    'Рекомендации:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...suggestions.map(
                    (suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(suggestion)),
                        ],
                      ),
                    ),
                  ),
                ] else
                  const Text('Специальных рекомендаций нет.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
            if (suggestions.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _recommendationService.sendBudgetRecommendation(
                    booking,
                    suggestions,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Рекомендации отправлены заказчику'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                child: const Text('Отправить заказчику'),
              ),
          ],
        ),
      );
    }
  }

  Future<void> _applyRecommendedDiscount(Booking booking) async {
    final recommendedDiscount =
        _recommendationService.calculateRecommendedDiscount(booking);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Применить рекомендуемую скидку'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Рекомендуемый размер скидки: ${recommendedDiscount.toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Исходная цена:'),
                      Text('${booking.totalPrice.toStringAsFixed(0)} ₽'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Скидка:'),
                      Text(
                        '${(booking.totalPrice * recommendedDiscount / 100).toStringAsFixed(0)} ₽',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Итоговая цена:'),
                      Text(
                        '${(booking.totalPrice * (1 - recommendedDiscount / 100)).toStringAsFixed(0)} ₽',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Применить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        final updatedBooking = booking.applyDiscount(recommendedDiscount);

        await firestoreService.updateBooking(
          booking.id,
          {
            'discount': recommendedDiscount,
            'finalPrice': updatedBooking.finalPrice,
            'updatedAt': DateTime.now(),
          },
        );

        // Отправляем уведомление заказчику
        await _recommendationService.sendDiscountNotification(updatedBooking);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Автоматическая скидка ${recommendedDiscount.toStringAsFixed(0)}% применена',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка применения скидки: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(value),
            ),
          ],
        ),
      );

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} в ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.new_releases;
      case 'confirmed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Нет новых заявок';
      case 'confirmed':
        return 'Нет подтвержденных заявок';
      case 'rejected':
        return 'Нет отклоненных заявок';
      default:
        return 'Нет заявок';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Новая';
      case BookingStatus.confirmed:
        return 'Подтверждена';
      case BookingStatus.cancelled:
        return 'Отменена';
      case BookingStatus.completed:
        return 'Завершена';
      case BookingStatus.rejected:
        return 'Отклонена';
    }
  }
}
