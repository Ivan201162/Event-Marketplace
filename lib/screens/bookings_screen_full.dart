import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_navigator.dart';
import '../providers/bookings_provider.dart';
import '../services/booking_service.dart';
import '../services/firebase_auth_service.dart';
import 'booking_details_screen.dart';
import 'chat_screen.dart';

/// Полноценный экран заявок и бронирований
class BookingsScreenFull extends ConsumerStatefulWidget {
  const BookingsScreenFull({super.key});

  @override
  ConsumerState<BookingsScreenFull> createState() => _BookingsScreenFullState();
}

class _BookingsScreenFullState extends ConsumerState<BookingsScreenFull>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Заявки'),
          leading: AppNavigator.buildBackButton(context),
        ),
        body: const Center(
          child: Text('Необходимо войти в систему'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки'),
        leading: AppNavigator.buildBackButton(context),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.send),
              text: 'Мои заявки',
            ),
            Tab(
              icon: Icon(Icons.inbox),
              text: 'Заявки мне',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyBookingsTab(customerId: currentUser.uid),
          _IncomingBookingsTab(specialistId: currentUser.uid),
        ],
      ),
    );
  }
}

/// Вкладка "Мои заявки" (для заказчиков)
class _MyBookingsTab extends ConsumerWidget {
  const _MyBookingsTab({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);
    
    return bookingsAsync.when(
      data: (bookings) {
        // Фильтруем заявки для текущего пользователя
        final userBookings = bookings.where((booking) => 
          booking['customerId'] == customerId || 
          booking['customerEmail']?.contains('@') == true,
        ).toList();
        
        if (userBookings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('У вас пока нет заявок'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: userBookings.length,
          itemBuilder: (context, index) {
            final booking = userBookings[index];
            return _BookingCard(
              booking: booking,
              onTap: () => _navigateToBookingDetails(context, booking),
              onChatTap: () => _navigateToChat(context, booking),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Ошибка: $error'),
      ),
    );
  }

  void _navigateToBookingDetails(BuildContext context, Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => BookingDetailsScreen(booking: booking),
      ),
    );
  }

  void _navigateToChat(BuildContext context, Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          chatId: '${booking['customerId'] ?? ''}_${booking['specialistId'] ?? ''}',
          otherParticipantId: booking['specialistId'] ?? '',
          otherParticipantName: booking['specialistName'] ?? 'Специалист',
        ),
      ),
    );
  }
}

/// Вкладка "Заявки мне" (для специалистов)
class _IncomingBookingsTab extends ConsumerWidget {
  const _IncomingBookingsTab({required this.specialistId});
  final String specialistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);
    
    return bookingsAsync.when(
      data: (bookings) {
        // Фильтруем заявки для текущего специалиста
        final specialistBookings = bookings.where((booking) => 
          booking['specialistId'] == specialistId,
        ).toList();
        
        if (specialistBookings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 100, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'У вас пока нет входящих заявок',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(
                  'Заявки от заказчиков появятся здесь',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: specialistBookings.length,
          itemBuilder: (context, index) {
            final booking = specialistBookings[index];
            return _BookingCard(
              booking: booking,
              onTap: () => _navigateToBookingDetails(context, booking),
              onChatTap: () => _navigateToChat(context, booking),
              showActions: true,
              onConfirm: () => _confirmBooking(context, booking),
              onReject: () => _rejectBooking(context, booking),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Ошибка: $error'),
      ),
    );
  }

  void _navigateToBookingDetails(BuildContext context, Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => BookingDetailsScreen(booking: booking),
      ),
    );
  }

  void _navigateToChat(BuildContext context, Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ChatScreen(
          chatId: '${booking['customerId'] ?? ''}_${booking['specialistId'] ?? ''}',
          otherParticipantId: booking['customerId'] ?? '',
          otherParticipantName: booking['customerName'] ?? 'Заказчик',
        ),
      ),
    );
  }

  Future<void> _confirmBooking(BuildContext context, Map<String, dynamic> booking) async {
    try {
      await BookingService().updateBookingStatus(
        booking['id'] ?? '',
        'Подтверждено',
      );

      // Отправляем уведомление заказчику
      // await NotificationService().sendNotification(
      //   booking.customerId,
      //   'Заявка подтверждена',
      //   'Ваша заявка на ${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year} подтверждена специалистом',
      // );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заявка подтверждена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectBooking(BuildContext context, Map<String, dynamic> booking) async {
    try {
      await BookingService().updateBookingStatus(
        booking['id'] ?? '',
        'Отклонено',
      );

      // Отправляем уведомление заказчику
      // await NotificationService().sendNotification(
      //   booking.customerId,
      //   'Заявка отклонена',
      //   'К сожалению, ваша заявка на ${booking.eventDate.day}.${booking.eventDate.month}.${booking.eventDate.year} отклонена',
      // );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заявка отклонена'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
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

/// Карточка заявки
class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onTap,
    required this.onChatTap,
    this.showActions = false,
    this.onConfirm,
    this.onReject,
  });
  final Map<String, dynamic> booking;
  final VoidCallback onTap;
  final VoidCallback onChatTap;
  final bool showActions;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking['eventType'] ?? 'Заявка на мероприятие',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking['eventDate'] ?? 'Дата не указана',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(status: booking['status'] ?? 'Неизвестно'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(booking['totalPrice'] ?? 0.0).toStringAsFixed(0)} ₽',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.payment, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Аванс: ${(booking['prepayment'] ?? 0.0).toStringAsFixed(0)} ₽',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                if ((booking['message'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    booking['message'] ?? '',
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onChatTap,
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('Чат'),
                      ),
                    ),
                    if (showActions &&
                        booking['status'] == 'В обработке') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onConfirm,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Подтвердить'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Отклонить'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

/// Чип статуса заявки
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case 'В обработке':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        text = 'В обработке';
        break;
      case 'Подтверждено':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = 'Подтверждено';
        break;
      case 'Отклонено':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        text = 'Отклонено';
        break;
      case 'Завершено':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        text = 'Завершено';
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        text = status;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
