import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/models/payment.dart';
import 'package:event_marketplace_app/models/chat.dart';
import 'package:event_marketplace_app/models/notification.dart';
import 'package:event_marketplace_app/models/review.dart';
import 'package:event_marketplace_app/models/analytics.dart';
import 'package:event_marketplace_app/models/user.dart';
import 'package:event_marketplace_app/models/specialist_schedule.dart';
import 'package:event_marketplace_app/services/specialist_service.dart';
import 'package:event_marketplace_app/services/firestore_service.dart';
import 'package:event_marketplace_app/services/payment_service.dart';
import 'package:event_marketplace_app/services/chat_service.dart';
import 'package:event_marketplace_app/services/notification_service.dart';
import 'package:event_marketplace_app/services/review_service.dart';
import 'package:event_marketplace_app/services/analytics_service.dart';
import 'package:event_marketplace_app/services/calendar_service.dart';
import 'package:event_marketplace_app/services/auth_service.dart';
import 'test_data.dart';

// Mock Specialist Service
class MockSpecialistService implements SpecialistService {
  final List<Specialist> _specialists = TestData.testSpecialists;
  final List<Specialist> _searchResults = [];

  @override
  Future<Specialist?> getSpecialist(String id) async {
    await Future.delayed(Duration(milliseconds: 100));
    try {
      return _specialists.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Specialist>> searchSpecialists({
    String? query,
    SpecialistCategory? category,
    String? city,
    double? minRating,
    double? maxPrice,
    DateTime? availableDate,
  }) async {
    await Future.delayed(Duration(milliseconds: 200));

    _searchResults.clear();
    _searchResults.addAll(_specialists);

    // Apply filters
    if (query != null && query.isNotEmpty) {
      _searchResults.retainWhere((s) =>
          s.name.toLowerCase().contains(query.toLowerCase()) ||
          s.description.toLowerCase().contains(query.toLowerCase()));
    }

    if (category != null) {
      _searchResults.retainWhere((s) => s.category == category);
    }

    if (city != null && city.isNotEmpty) {
      _searchResults.retainWhere((s) => s.serviceAreas.contains(city));
    }

    if (minRating != null) {
      _searchResults.retainWhere((s) => s.rating >= minRating);
    }

    if (maxPrice != null) {
      _searchResults.retainWhere((s) => s.hourlyRate <= maxPrice);
    }

    return _searchResults;
  }

  @override
  Future<bool> isSpecialistAvailableOnDate(
      String specialistId, DateTime date) async {
    await Future.delayed(Duration(milliseconds: 50));
    return true; // Mock always available
  }

  @override
  Future<bool> isSpecialistAvailableOnDateTime(
      String specialistId, DateTime dateTime) async {
    await Future.delayed(Duration(milliseconds: 50));
    return true; // Mock always available
  }

  @override
  Future<List<DateTime>> getAvailableTimeSlots(
      String specialistId, DateTime date,
      {Duration slotDuration = const Duration(hours: 1)}) async {
    await Future.delayed(Duration(milliseconds: 100));
    return [
      DateTime(date.year, date.month, date.day, 9, 0),
      DateTime(date.year, date.month, date.day, 10, 0),
      DateTime(date.year, date.month, date.day, 11, 0),
      DateTime(date.year, date.month, date.day, 14, 0),
      DateTime(date.year, date.month, date.day, 15, 0),
    ];
  }

  @override
  Future<void> createSpecialist(Specialist specialist) async {
    await Future.delayed(Duration(milliseconds: 100));
    _specialists.add(specialist);
  }

  @override
  Future<void> updateSpecialist(Specialist specialist) async {
    await Future.delayed(Duration(milliseconds: 100));
    final index = _specialists.indexWhere((s) => s.id == specialist.id);
    if (index != -1) {
      _specialists[index] = specialist;
    }
  }

  @override
  Future<void> deleteSpecialist(String id) async {
    await Future.delayed(Duration(milliseconds: 100));
    _specialists.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> updateSpecialistRating(
      String specialistId, double rating, int reviewCount) async {
    await Future.delayed(Duration(milliseconds: 100));
    final index = _specialists.indexWhere((s) => s.id == specialistId);
    if (index != -1) {
      _specialists[index] = _specialists[index].copyWith(
        rating: rating,
        reviewCount: reviewCount,
        updatedAt: DateTime.now(),
      );
    }
  }
}

// Mock Firestore Service
class MockFirestoreService implements FirestoreService {
  final List<Booking> _bookings = TestData.testBookings;
  final List<Payment> _payments = TestData.testPayments;

  @override
  Future<List<Booking>> getBookingsByCustomer(String customerId) async {
    await Future.delayed(Duration(milliseconds: 100));
    return _bookings.where((b) => b.customerId == customerId).toList();
  }

  @override
  Future<List<Booking>> getBookingsBySpecialist(String specialistId) async {
    await Future.delayed(Duration(milliseconds: 100));
    return _bookings.where((b) => b.specialistId == specialistId).toList();
  }

  @override
  Future<void> addOrUpdateBookingWithCalendar(Booking booking) async {
    await Future.delayed(Duration(milliseconds: 100));
    final index = _bookings.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      _bookings[index] = booking;
    } else {
      _bookings.add(booking);
    }
  }

  @override
  Future<void> updateBookingStatusWithCalendar(
      String bookingId, String status) async {
    await Future.delayed(Duration(milliseconds: 100));
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(
        status: BookingStatus.values.firstWhere((s) => s.name == status),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<bool> isSpecialistAvailable(
      String specialistId, DateTime dateTime) async {
    await Future.delayed(Duration(milliseconds: 50));
    return true; // Mock always available
  }

  @override
  Future<List<DateTime>> getAvailableTimeSlots(
      String specialistId, DateTime date,
      {Duration slotDuration = const Duration(hours: 1)}) async {
    await Future.delayed(Duration(milliseconds: 100));
    return [
      DateTime(date.year, date.month, date.day, 9, 0),
      DateTime(date.year, date.month, date.day, 10, 0),
      DateTime(date.year, date.month, date.day, 11, 0),
    ];
  }

  @override
  Future<List<ScheduleEvent>> getSpecialistEventsForDate(
      String specialistId, DateTime date) async {
    await Future.delayed(Duration(milliseconds: 100));
    return TestData.testScheduleEvents
        .where((e) =>
            e.specialistId == specialistId &&
            e.startTime.year == date.year &&
            e.startTime.month == date.month &&
            e.startTime.day == date.day)
        .toList();
  }

  @override
  Future<void> updatePaymentStatus(String paymentId, String status) async {
    await Future.delayed(Duration(milliseconds: 100));
    final index = _payments.indexWhere((p) => p.id == paymentId);
    if (index != -1) {
      _payments[index] = _payments[index].copyWith(
        status: PaymentStatus.values.firstWhere((s) => s.name == status),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> addTestBookings() async {
    await Future.delayed(Duration(milliseconds: 100));
    // Test bookings already added in constructor
  }
}

// Mock Payment Service
class MockPaymentService implements PaymentService {
  final List<Payment> _payments = TestData.testPayments;

  @override
  Future<Payment> createPayment(Payment payment) async {
    await Future.delayed(Duration(milliseconds: 100));
    _payments.add(payment);
    return payment;
  }

  @override
  Future<void> updatePaymentStatus(
      String paymentId, PaymentStatus status) async {
    await Future.delayed(Duration(milliseconds: 100));
    final index = _payments.indexWhere((p) => p.id == paymentId);
    if (index != -1) {
      _payments[index] = _payments[index].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<Payment>> getPaymentsByBooking(String bookingId) async {
    await Future.delayed(Duration(milliseconds: 100));
    return _payments.where((p) => p.bookingId == bookingId).toList();
  }

  @override
  Future<List<Payment>> getPaymentsByCustomer(String customerId) async {
    await Future.delayed(Duration(milliseconds: 100));
    return _payments.where((p) => p.customerId == customerId).toList();
  }

  @override
  Future<List<Payment>> getPaymentsBySpecialist(String specialistId) async {
    await Future.delayed(Duration(milliseconds: 100));
    return _payments.where((p) => p.specialistId == specialistId).toList();
  }

  @override
  Future<Map<String, dynamic>> getPaymentStatistics(String userId) async {
    await Future.delayed(Duration(milliseconds: 100));
    return {
      'totalAmount': 50000.0,
      'completedPayments': 15,
      'pendingPayments': 3,
      'failedPayments': 1,
    };
  }

  @override
  Future<bool> processPayment(
      String paymentId, Map<String, dynamic> paymentData) async {
    await Future.delayed(Duration(milliseconds: 200));
    // Mock payment processing - 90% success rate
    return DateTime.now().millisecondsSinceEpoch % 10 != 0;
  }

  @override
  Future<List<Payment>> createInitialPaymentsForBooking(Booking booking) async {
    await Future.delayed(Duration(milliseconds: 100));
    final advancePayment = Payment(
      id: 'advance_${booking.id}',
      bookingId: booking.id,
      customerId: booking.customerId,
      specialistId: booking.specialistId,
      amount: booking.totalPrice * 0.3,
      type: PaymentType.advance,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      dueDate: DateTime.now().add(Duration(days: 7)),
      paymentMethod: 'card',
      transactionId: null,
      isPrepayment: true,
      isFinalPayment: false,
    );

    final finalPayment = Payment(
      id: 'final_${booking.id}',
      bookingId: booking.id,
      customerId: booking.customerId,
      specialistId: booking.specialistId,
      amount: booking.totalPrice * 0.7,
      type: PaymentType.finalPayment,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      dueDate: DateTime.now().add(Duration(days: 1)),
      paymentMethod: 'card',
      transactionId: null,
      isPrepayment: false,
      isFinalPayment: true,
    );

    _payments.addAll([advancePayment, finalPayment]);
    return [advancePayment, finalPayment];
  }

  @override
  Future<Map<String, double>> calculatePaymentAmounts(
      double totalAmount, OrganizationType organizationType) async {
    await Future.delayed(Duration(milliseconds: 50));
    return {
      'advance': totalAmount * 0.3,
      'final': totalAmount * 0.7,
    };
  }
}

// Mock Chat Service
class MockChatService implements ChatService {
  final List<Chat> _chats = TestData.testChats;
  final List<ChatMessage> _messages = TestData.testChatMessages;

  @override
  Future<Chat> createChat(List<String> participants) async {
    await Future.delayed(Duration(milliseconds: 100));
    final chat = Chat(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      participants: participants,
      lastMessage: '',
      lastMessageTimestamp: DateTime.now(),
      unreadCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _chats.add(chat);
    return chat;
  }

  @override
  Stream<Chat> getChatStream(String chatId) async* {
    await Future.delayed(Duration(milliseconds: 100));
    final chat = _chats.firstWhere((c) => c.id == chatId);
    yield chat;
  }

  @override
  Stream<List<Chat>> getChatsForUserStream(String userId) async* {
    await Future.delayed(Duration(milliseconds: 100));
    final userChats =
        _chats.where((c) => c.participants.contains(userId)).toList();
    yield userChats;
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    await Future.delayed(Duration(milliseconds: 100));
    _messages.add(message);

    // Update chat
    final chatIndex = _chats.indexWhere((c) => c.id == message.chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(
        lastMessage: message.content,
        lastMessageTimestamp: message.timestamp,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Stream<List<ChatMessage>> getMessagesForChatStream(String chatId) async* {
    await Future.delayed(Duration(milliseconds: 100));
    final chatMessages = _messages.where((m) => m.chatId == chatId).toList();
    yield chatMessages;
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    await Future.delayed(Duration(milliseconds: 50));
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markChatAsRead(String chatId) async {
    await Future.delayed(Duration(milliseconds: 50));
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      _chats[index] = _chats[index].copyWith(unreadCount: 0);
    }
  }
}

// Mock Notification Service
class MockNotificationService implements NotificationService {
  final List<AppNotification> _notifications = TestData.testNotifications;

  @override
  Future<void> createNotification(AppNotification notification) async {
    await Future.delayed(Duration(milliseconds: 100));
    _notifications.add(notification);
  }

  @override
  Stream<List<AppNotification>> getNotificationsForUserStream(
      String userId) async* {
    await Future.delayed(Duration(milliseconds: 100));
    final userNotifications =
        _notifications.where((n) => n.userId == userId).toList();
    yield userNotifications;
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    await Future.delayed(Duration(milliseconds: 50));
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Stream<NotificationStatistics> getNotificationStatisticsStream(
      String userId) async* {
    await Future.delayed(Duration(milliseconds: 100));
    final userNotifications =
        _notifications.where((n) => n.userId == userId).toList();
    final unreadCount = userNotifications.where((n) => !n.isRead).length;

    yield NotificationStatistics(
      userId: userId,
      unreadCount: unreadCount,
      totalCount: userNotifications.length,
      lastCheckedAt: DateTime.now(),
    );
  }

  @override
  Future<void> createBookingNotification({
    required String userId,
    required NotificationType type,
    required String bookingId,
    required String specialistName,
    required String customerName,
    required DateTime eventDate,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));
    final notification = AppNotification(
      id: 'notification_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: type,
      title: _getBookingNotificationTitle(type),
      body: _getBookingNotificationBody(
          type, specialistName, customerName, eventDate),
      timestamp: DateTime.now(),
      isRead: false,
      priority: NotificationPriority.high,
      bookingId: bookingId,
      paymentId: null,
      chatId: null,
    );
    _notifications.add(notification);
  }

  @override
  Future<void> createPaymentNotification({
    required String userId,
    required NotificationType type,
    required String paymentId,
    required double amount,
    required String currency,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));
    final notification = AppNotification(
      id: 'notification_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: type,
      title: _getPaymentNotificationTitle(type),
      body: _getPaymentNotificationBody(type, amount, currency),
      timestamp: DateTime.now(),
      isRead: false,
      priority: NotificationPriority.high,
      bookingId: null,
      paymentId: paymentId,
      chatId: null,
    );
    _notifications.add(notification);
  }

  @override
  Future<void> createChatMessageNotification({
    required String userId,
    required String chatId,
    required String senderName,
    required String messagePreview,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));
    final notification = AppNotification(
      id: 'notification_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: NotificationType.chat_message,
      title: 'Новое сообщение от $senderName',
      body: messagePreview,
      timestamp: DateTime.now(),
      isRead: false,
      priority: NotificationPriority.medium,
      bookingId: null,
      paymentId: null,
      chatId: chatId,
    );
    _notifications.add(notification);
  }

  @override
  Future<void> createSystemNotification({
    required String userId,
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.low,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));
    final notification = AppNotification(
      id: 'notification_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: NotificationType.system_alert,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      priority: priority,
      bookingId: null,
      paymentId: null,
      chatId: null,
    );
    _notifications.add(notification);
  }

  String _getBookingNotificationTitle(NotificationType type) {
    switch (type) {
      case NotificationType.booking_confirmed:
        return 'Заявка подтверждена!';
      case NotificationType.booking_rejected:
        return 'Заявка отклонена';
      case NotificationType.booking_cancelled:
        return 'Заявка отменена';
      default:
        return 'Уведомление о заявке';
    }
  }

  String _getBookingNotificationBody(NotificationType type,
      String specialistName, String customerName, DateTime eventDate) {
    final dateStr = '${eventDate.day}.${eventDate.month}.${eventDate.year}';
    switch (type) {
      case NotificationType.booking_confirmed:
        return 'Ваша заявка на $dateStr подтверждена';
      case NotificationType.booking_rejected:
        return 'К сожалению, ваша заявка на $dateStr отклонена';
      case NotificationType.booking_cancelled:
        return 'Заявка на $dateStr была отменена';
      default:
        return 'Обновление по заявке на $dateStr';
    }
  }

  String _getPaymentNotificationTitle(NotificationType type) {
    switch (type) {
      case NotificationType.payment_completed:
        return 'Платеж завершен!';
      case NotificationType.payment_failed:
        return 'Платеж не удался';
      default:
        return 'Уведомление о платеже';
    }
  }

  String _getPaymentNotificationBody(
      NotificationType type, double amount, String currency) {
    switch (type) {
      case NotificationType.payment_completed:
        return 'Ваш платеж на ${amount.toStringAsFixed(0)} $currency успешно обработан';
      case NotificationType.payment_failed:
        return 'Ваш платеж на ${amount.toStringAsFixed(0)} $currency не был обработан';
      default:
        return 'Обновление по платежу на ${amount.toStringAsFixed(0)} $currency';
    }
  }
}

// Mock Review Service
class MockReviewService implements ReviewService {
  final List<Review> _reviews = TestData.testReviews;

  @override
  Future<void> submitReview(Review review) async {
    await Future.delayed(Duration(milliseconds: 100));
    _reviews.add(review);
  }

  @override
  Stream<List<Review>> getReviewsForSpecialistStream(
      String specialistId) async* {
    await Future.delayed(Duration(milliseconds: 100));
    final specialistReviews =
        _reviews.where((r) => r.specialistId == specialistId).toList();
    yield specialistReviews;
  }

  @override
  Stream<List<Review>> getReviewsByCustomerStream(String customerId) async* {
    await Future.delayed(Duration(milliseconds: 100));
    final customerReviews =
        _reviews.where((r) => r.customerId == customerId).toList();
    yield customerReviews;
  }

  @override
  Stream<ReviewStatistics> getReviewStatisticsForSpecialistStream(
      String specialistId) async* {
    await Future.delayed(Duration(milliseconds: 100));
    final specialistReviews =
        _reviews.where((r) => r.specialistId == specialistId).toList();

    if (specialistReviews.isEmpty) {
      yield ReviewStatistics(
        specialistId: specialistId,
        averageRating: 0.0,
        totalReviews: 0,
        ratingCounts: {},
        detailedRatingAverages: DetailedRating(
          quality: 0.0,
          communication: 0.0,
          punctuality: 0.0,
          value: 0.0,
        ),
      );
      return;
    }

    final averageRating =
        specialistReviews.map((r) => r.rating).reduce((a, b) => a + b) /
            specialistReviews.length;

    final ratingCounts = <int, int>{};
    for (final review in specialistReviews) {
      final rating = review.rating.round();
      ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
    }

    final qualityAvg = specialistReviews
            .map((r) => r.detailedRating.quality)
            .reduce((a, b) => a + b) /
        specialistReviews.length;
    final communicationAvg = specialistReviews
            .map((r) => r.detailedRating.communication)
            .reduce((a, b) => a + b) /
        specialistReviews.length;
    final punctualityAvg = specialistReviews
            .map((r) => r.detailedRating.punctuality)
            .reduce((a, b) => a + b) /
        specialistReviews.length;
    final valueAvg = specialistReviews
            .map((r) => r.detailedRating.value)
            .reduce((a, b) => a + b) /
        specialistReviews.length;

    yield ReviewStatistics(
      specialistId: specialistId,
      averageRating: averageRating,
      totalReviews: specialistReviews.length,
      ratingCounts: ratingCounts,
      detailedRatingAverages: DetailedRating(
        quality: qualityAvg,
        communication: communicationAvg,
        punctuality: punctualityAvg,
        value: valueAvg,
      ),
    );
  }

  @override
  Stream<List<Specialist>> getTopRatedSpecialistsStream(
      {int limit = 10}) async* {
    await Future.delayed(Duration(milliseconds: 100));
    // Mock implementation - return specialists sorted by rating
    final specialists = TestData.testSpecialists;
    specialists.sort((a, b) => b.rating.compareTo(a.rating));
    yield specialists.take(limit).toList();
  }
}

// Mock Analytics Service
class MockAnalyticsService implements AnalyticsService {
  final List<Metric> _metrics = TestData.testMetrics;

  @override
  Future<void> logMetric(Metric metric) async {
    await Future.delayed(Duration(milliseconds: 50));
    _metrics.add(metric);
  }

  @override
  Future<List<Metric>> getMetrics({
    String? name,
    MetricType? type,
    AnalyticsPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));
    var filteredMetrics = _metrics;

    if (name != null) {
      filteredMetrics = filteredMetrics.where((m) => m.name == name).toList();
    }

    if (type != null) {
      filteredMetrics = filteredMetrics.where((m) => m.type == type).toList();
    }

    if (period != null) {
      filteredMetrics =
          filteredMetrics.where((m) => m.period == period).toList();
    }

    if (startDate != null) {
      filteredMetrics =
          filteredMetrics.where((m) => m.timestamp.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      filteredMetrics =
          filteredMetrics.where((m) => m.timestamp.isBefore(endDate)).toList();
    }

    return filteredMetrics;
  }

  @override
  Future<Report> generateReport(ReportType type, AnalyticsPeriod period,
      {Map<String, dynamic>? filters}) async {
    await Future.delayed(Duration(milliseconds: 200));
    return Report(
      id: 'report_${DateTime.now().millisecondsSinceEpoch}',
      name: '${type.name} Report',
      type: type,
      generatedAt: DateTime.now(),
      data: {
        'totalBookings': 25,
        'totalRevenue': 150000.0,
        'averageRating': 4.7,
        'topSpecialists': ['specialist_1', 'specialist_2'],
      },
      period: period,
    );
  }

  @override
  Future<List<Report>> getReports({String? userId}) async {
    await Future.delayed(Duration(milliseconds: 100));
    return [
      Report(
        id: 'report_1',
        name: 'Monthly Report',
        type: ReportType.monthly,
        generatedAt: DateTime.now().subtract(Duration(days: 1)),
        data: {'totalBookings': 25, 'totalRevenue': 150000.0},
        period: AnalyticsPeriod.month,
      ),
    ];
  }

  @override
  Future<Dashboard> createDashboard(
      String name, String userId, List<Map<String, dynamic>> widgets) async {
    await Future.delayed(Duration(milliseconds: 100));
    return Dashboard(
      id: 'dashboard_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      userId: userId,
      widgets: widgets,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Dashboard?> getDashboard(String id) async {
    await Future.delayed(Duration(milliseconds: 100));
    return Dashboard(
      id: id,
      name: 'Test Dashboard',
      userId: 'test_user',
      widgets: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateDashboard(
      String id, List<Map<String, dynamic>> widgets) async {
    await Future.delayed(Duration(milliseconds: 100));
    // Mock implementation
  }

  @override
  Future<List<KPI>> getKPIs({String? userId}) async {
    await Future.delayed(Duration(milliseconds: 100));
    return [
      KPI(
        id: 'kpi_1',
        name: 'Total Bookings',
        value: 25.0,
        target: 30.0,
        unit: 'bookings',
        trend: KPITrend.up,
      ),
      KPI(
        id: 'kpi_2',
        name: 'Revenue',
        value: 150000.0,
        target: 200000.0,
        unit: 'RUB',
        trend: KPITrend.up,
      ),
    ];
  }

  @override
  Future<List<PeriodStatistics>> getPeriodStatistics(
      AnalyticsPeriod period) async {
    await Future.delayed(Duration(milliseconds: 100));
    return [
      PeriodStatistics(
        period: period,
        bookingsCount: 25,
        revenue: 150000.0,
        newUsers: 10,
      ),
    ];
  }
}

// Mock Calendar Service
class MockCalendarService implements CalendarService {
  final List<ScheduleEvent> _events = TestData.testScheduleEvents;

  @override
  Future<void> createBookingEvent(Booking booking) async {
    await Future.delayed(Duration(milliseconds: 100));
    final event = ScheduleEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      specialistId: booking.specialistId,
      type: ScheduleEventType.booking,
      title: booking.eventName,
      description: booking.eventDescription,
      startTime: booking.eventDate,
      endTime: booking.eventDate.add(booking.duration),
      isAllDay: false,
      bookingId: booking.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _events.add(event);
  }

  @override
  Future<void> removeBookingEvent(String bookingId) async {
    await Future.delayed(Duration(milliseconds: 100));
    _events.removeWhere((e) => e.bookingId == bookingId);
  }

  @override
  Future<bool> isDateTimeAvailable(
      String specialistId, DateTime dateTime) async {
    await Future.delayed(Duration(milliseconds: 50));
    return !_events.any((e) =>
        e.specialistId == specialistId &&
        e.startTime.isBefore(dateTime) &&
        e.endTime.isAfter(dateTime));
  }

  @override
  Future<List<DateTime>> getAvailableTimeSlots(
      String specialistId, DateTime date,
      {Duration slotDuration = const Duration(hours: 1)}) async {
    await Future.delayed(Duration(milliseconds: 100));
    return [
      DateTime(date.year, date.month, date.day, 9, 0),
      DateTime(date.year, date.month, date.day, 10, 0),
      DateTime(date.year, date.month, date.day, 11, 0),
      DateTime(date.year, date.month, date.day, 14, 0),
      DateTime(date.year, date.month, date.day, 15, 0),
    ];
  }

  @override
  Future<List<ScheduleEvent>> getEventsForDate(
      String specialistId, DateTime date) async {
    await Future.delayed(Duration(milliseconds: 100));
    return _events
        .where((e) =>
            e.specialistId == specialistId &&
            e.startTime.year == date.year &&
            e.startTime.month == date.month &&
            e.startTime.day == date.day)
        .toList();
  }

  @override
  Future<void> addUnavailablePeriod(String specialistId, DateTime startTime,
      DateTime endTime, String reason) async {
    await Future.delayed(Duration(milliseconds: 100));
    final event = ScheduleEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      specialistId: specialistId,
      type: ScheduleEventType.unavailable,
      title: 'Недоступен',
      description: reason,
      startTime: startTime,
      endTime: endTime,
      isAllDay: false,
      bookingId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _events.add(event);
  }

  @override
  Future<void> addVacationPeriod(String specialistId, DateTime startTime,
      DateTime endTime, String reason) async {
    await Future.delayed(Duration(milliseconds: 100));
    final event = ScheduleEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      specialistId: specialistId,
      type: ScheduleEventType.vacation,
      title: 'Отпуск',
      description: reason,
      startTime: startTime,
      endTime: endTime,
      isAllDay: true,
      bookingId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _events.add(event);
  }
}

// Mock Auth Service
class MockAuthService implements AuthService {
  AppUser? _currentUser;
  bool _isAuthenticated = false;

  @override
  Stream<AppUser?> get authStateChanges async* {
    await Future.delayed(Duration(milliseconds: 100));
    yield _currentUser;
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  Future<AppUser?> signInWithEmailAndPassword(
      String email, String password) async {
    await Future.delayed(Duration(milliseconds: 200));
    if (email == 'test@example.com' && password == 'password') {
      _currentUser = TestData.testUsers.first;
      _isAuthenticated = true;
      return _currentUser;
    }
    throw Exception('Invalid credentials');
  }

  @override
  Future<AppUser?> createUserWithEmailAndPassword(
      String email, String password, String name) async {
    await Future.delayed(Duration(milliseconds: 200));
    _currentUser = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name,
      role: UserRole.customer,
      phone: '',
      avatar: '',
      isVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _isAuthenticated = true;
    return _currentUser;
  }

  @override
  Future<AppUser?> signInAsGuest() async {
    await Future.delayed(Duration(milliseconds: 100));
    _currentUser = AppUser(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: '',
      name: 'Гость',
      role: UserRole.guest,
      phone: '',
      avatar: '',
      isVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _isAuthenticated = true;
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(Duration(milliseconds: 100));
    _currentUser = null;
    _isAuthenticated = false;
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(Duration(milliseconds: 200));
    _currentUser = null;
    _isAuthenticated = false;
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    await Future.delayed(Duration(milliseconds: 100));
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: updates['name'] ?? _currentUser!.name,
        phone: updates['phone'] ?? _currentUser!.phone,
        avatar: updates['avatar'] ?? _currentUser!.avatar,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(Duration(milliseconds: 200));
    // Mock implementation
  }
}
