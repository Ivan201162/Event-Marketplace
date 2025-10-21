import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import 'auth_providers.dart';

/// Провайдер сервиса уведомлений
final notificationServiceProvider = Provider((ref) => NotificationService());

/// Провайдер для получения уведомлений текущего пользователя
final userNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    return Stream.value([]);
  }

  final notificationService = ref.read(notificationServiceProvider);
  return notificationService.getUserNotifications(currentUser.id);
});

/// Провайдер для получения непрочитанных уведомлений
final unreadNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    return Stream.value([]);
  }

  final notificationService = ref.read(notificationServiceProvider);
  return notificationService.getUnreadNotifications(currentUser.id);
});

/// Провайдер для получения количества непрочитанных уведомлений
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    return Stream.value(0);
  }

  final notificationService = ref.read(notificationServiceProvider);
  return notificationService.getUnreadCount(currentUser.id);
});

/// Провайдер для отправки уведомлений
final sendNotificationProvider = FutureProvider.family<void, SendNotificationParams>((
  ref,
  params,
) async {
  final notificationService = ref.read(notificationServiceProvider);
  await notificationService.sendNotification(
    params.userId,
    params.title,
    params.message,
    data: params.data,
  );
});

/// Параметры для отправки уведомления
class SendNotificationParams {
  const SendNotificationParams({
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
  });

  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
}

/// Провайдер для отметки уведомления как прочитанного
final markNotificationAsReadProvider = FutureProvider.family<void, String>((
  ref,
  notificationId,
) async {
  final notificationService = ref.read(notificationServiceProvider);
  await notificationService.markAsRead(notificationId);
});

/// Провайдер для отметки всех уведомлений как прочитанных
final markAllNotificationsAsReadProvider = FutureProvider.family<void, String>((ref, userId) async {
  final notificationService = ref.read(notificationServiceProvider);
  await notificationService.markAllAsRead(userId);
});

/// Провайдер для удаления уведомления
final deleteNotificationProvider = FutureProvider.family<void, String>((ref, notificationId) async {
  final notificationService = ref.read(notificationServiceProvider);
  await notificationService.deleteNotification(notificationId);
});

/// Провайдер для отправки уведомления о новой заявке
final sendNewBookingNotificationProvider =
    FutureProvider.family<void, NewBookingNotificationParams>((ref, params) async {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.sendNewBookingNotification(
        params.specialistId,
        params.customerName,
      );
    });

/// Параметры для уведомления о новой заявке
class NewBookingNotificationParams {
  const NewBookingNotificationParams({
    required this.specialistId,
    required this.customerName,
    required this.eventTitle,
    required this.bookingId,
  });

  final String specialistId;
  final String customerName;
  final String eventTitle;
  final String bookingId;
}

/// Провайдер для отправки уведомления о принятии заявки
final sendBookingAcceptedNotificationProvider =
    FutureProvider.family<void, BookingAcceptedNotificationParams>((ref, params) async {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.sendBookingAcceptedNotification(
        customerId: params.customerId,
        specialistName: params.specialistName,
        eventTitle: params.eventTitle,
        bookingId: params.bookingId,
      );
    });

/// Параметры для уведомления о принятии заявки
class BookingAcceptedNotificationParams {
  const BookingAcceptedNotificationParams({
    required this.customerId,
    required this.specialistName,
    required this.eventTitle,
    required this.bookingId,
  });

  final String customerId;
  final String specialistName;
  final String eventTitle;
  final String bookingId;
}

/// Провайдер для отправки уведомления об отклонении заявки
final sendBookingRejectedNotificationProvider =
    FutureProvider.family<void, BookingRejectedNotificationParams>((ref, params) async {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.sendBookingRejectedNotification(
        params.customerId,
        params.specialistName,
      );
    });

/// Параметры для уведомления об отклонении заявки
class BookingRejectedNotificationParams {
  const BookingRejectedNotificationParams({
    required this.customerId,
    required this.specialistName,
    required this.eventTitle,
    required this.bookingId,
    this.reason,
  });

  final String customerId;
  final String specialistName;
  final String eventTitle;
  final String bookingId;
  final String? reason;
}

/// Провайдер для отправки уведомления о новом отзыве
final sendNewReviewNotificationProvider = FutureProvider.family<void, NewReviewNotificationParams>((
  ref,
  params,
) async {
  final notificationService = ref.read(notificationServiceProvider);
  await notificationService.sendNewReviewNotification(
    specialistId: params.specialistId,
    customerName: params.customerName,
    rating: params.rating,
    reviewId: params.reviewId,
  );
});

/// Параметры для уведомления о новом отзыве
class NewReviewNotificationParams {
  const NewReviewNotificationParams({
    required this.specialistId,
    required this.customerName,
    required this.rating,
    required this.reviewId,
  });

  final String specialistId;
  final String customerName;
  final int rating;
  final String reviewId;
}

/// Провайдер для отправки уведомления о получении платежа
final sendPaymentReceivedNotificationProvider =
    FutureProvider.family<void, PaymentReceivedNotificationParams>((ref, params) async {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.sendPaymentReceivedNotification(
        specialistId: params.specialistId,
        amount: params.amount,
        eventTitle: params.eventTitle,
        paymentId: params.paymentId,
      );
    });

/// Параметры для уведомления о получении платежа
class PaymentReceivedNotificationParams {
  const PaymentReceivedNotificationParams({
    required this.specialistId,
    required this.amount,
    required this.eventTitle,
    required this.paymentId,
  });

  final String specialistId;
  final double amount;
  final String eventTitle;
  final String paymentId;
}
