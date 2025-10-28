import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Утилиты для обработки навигации "Назад"
class BackUtils {
  /// Обработка кнопки "Назад" с проверкой возможности возврата
  static void handleBackButton(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      // Если нельзя вернуться назад, переходим на главную страницу
      context.go('/');
    }
  }

  /// Обработка кнопки "Назад" с возможностью передачи результата
  static void handleBackButtonWithResult(BuildContext context, [result]) {
    if (Navigator.of(context).canPop()) {
      context.pop(result);
    } else {
      context.go('/');
    }
  }

  /// Проверка, можно ли вернуться назад
  static bool canGoBack(BuildContext context) => Navigator.of(context).canPop();

  /// Создание стандартной кнопки "Назад"
  static Widget createBackButton(BuildContext context,
          {VoidCallback? onPressed,}) =>
      IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onPressed ?? () => handleBackButton(context),
      );

  /// Создание кнопки "Назад" с кастомным действием
  static Widget createCustomBackButton(
    BuildContext context, {
    required VoidCallback onPressed,
    IconData icon = Icons.arrow_back,
  }) =>
      IconButton(icon: Icon(icon), onPressed: onPressed);

  /// Создание AppBar с кнопкой "Назад"
  static AppBar createAppBarWithBackButton(
    BuildContext context, {
    required String title,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
  }) =>
      AppBar(
        title: Text(title),
        leading: automaticallyImplyLeading
            ? createBackButton(context, onPressed: onBackPressed)
            : null,
        actions: actions,
      );

  /// Создание SliverAppBar с кнопкой "Назад"
  static SliverAppBar createSliverAppBarWithBackButton(
    BuildContext context, {
    required String title,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    bool pinned = false,
    bool floating = false,
    double? expandedHeight,
    Widget? flexibleSpace,
  }) =>
      SliverAppBar(
        title: Text(title),
        leading: createBackButton(context, onPressed: onBackPressed),
        actions: actions,
        pinned: pinned,
        floating: floating,
        expandedHeight: expandedHeight,
        flexibleSpace: flexibleSpace,
      );

  /// Обработка системной кнопки "Назад" на Android
  static Future<bool> handleSystemBackButton(BuildContext context) async {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return false; // Не закрываем приложение
    } else {
      return true; // Закрываем приложение
    }
  }

  /// Создание PopScope для обработки системной кнопки "Назад"
  static Widget createPopScope(
    BuildContext context, {
    required Widget child,
    Future<bool> Function()? onWillPop,
  }) =>
      PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            if (onWillPop != null) {
              await onWillPop();
            } else {
              handleSystemBackButton(context);
            }
          }
        },
        child: child,
      );

  /// Переход на предыдущую страницу с анимацией
  static void popWithAnimation(BuildContext context, [result]) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    } else {
      context.go('/');
    }
  }

  /// Переход на главную страницу
  static void goToHome(BuildContext context) {
    context.go('/');
  }

  /// Переход на страницу профиля
  static void goToProfile(BuildContext context) {
    context.go('/profile');
  }

  /// Переход на страницу специалиста
  static void goToSpecialist(BuildContext context, String specialistId) {
    context.go('/specialist/$specialistId');
  }

  /// Переход на страницу заказчика
  static void goToCustomer(BuildContext context, String customerId) {
    context.go('/customer/$customerId');
  }

  /// Переход на страницу бронирования
  static void goToBooking(BuildContext context, String specialistId) {
    context.go('/booking/$specialistId');
  }

  /// Переход на страницу чата
  static void goToChat(BuildContext context, String chatId) {
    context.go('/chat/$chatId');
  }

  /// Переход на страницу написания отзыва
  static void goToWriteReview(BuildContext context, String specialistId,
      {String? bookingId,}) {
    final path = bookingId != null
        ? '/write-review/$specialistId?bookingId=$bookingId'
        : '/write-review/$specialistId';
    context.go(path);
  }

  /// Переход на страницу отзывов специалиста
  static void goToSpecialistReviews(BuildContext context, String specialistId) {
    context.go('/specialist/$specialistId/reviews');
  }

  /// Переход на страницу портфолио специалиста
  static void goToSpecialistPortfolio(
      BuildContext context, String specialistId,) {
    context.go('/specialist/$specialistId/portfolio');
  }

  /// Переход на страницу прайс-листа специалиста
  static void goToSpecialistPriceList(
      BuildContext context, String specialistId,) {
    context.go('/specialist/$specialistId/price-list');
  }

  /// Переход на страницу календаря специалиста
  static void goToSpecialistCalendar(
      BuildContext context, String specialistId,) {
    context.go('/specialist/$specialistId/calendar');
  }

  /// Переход на страницу истории заявок заказчика
  static void goToCustomerBookings(BuildContext context, String customerId) {
    context.go('/customer/$customerId/bookings');
  }

  /// Переход на страницу избранного заказчика
  static void goToCustomerFavorites(BuildContext context, String customerId) {
    context.go('/customer/$customerId/favorites');
  }

  /// Переход на страницу годовщин заказчика
  static void goToCustomerAnniversaries(
      BuildContext context, String customerId,) {
    context.go('/customer/$customerId/anniversaries');
  }

  /// Показать диалог подтверждения выхода
  static Future<bool?> showExitConfirmationDialog(BuildContext context) =>
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Выход'),
          content: const Text('Вы уверены, что хотите выйти из приложения?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Выйти'),),
          ],
        ),
      );

  /// Показать диалог подтверждения возврата
  static Future<bool?> showBackConfirmationDialog(BuildContext context) =>
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Возврат'),
          content:
              const Text('Несохраненные изменения будут потеряны. Продолжить?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Продолжить'),
            ),
          ],
        ),
      );
}
