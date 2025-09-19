import 'package:flutter/material.dart';

/// Статусы бронирований
enum BookingStatus {
  pending, // На рассмотрении
  confirmed, // Подтверждено
  completed, // Завершено
  cancelled, // Отменено
  rejected, // Отклонено
}

/// Расширения для BookingStatus
extension BookingStatusExtension on BookingStatus {
  /// Получить название статуса
  String get name {
    switch (this) {
      case BookingStatus.pending:
        return 'На рассмотрении';
      case BookingStatus.confirmed:
        return 'Подтверждено';
      case BookingStatus.completed:
        return 'Завершено';
      case BookingStatus.cancelled:
        return 'Отменено';
      case BookingStatus.rejected:
        return 'Отклонено';
    }
  }

  /// Получить описание статуса
  String get description {
    switch (this) {
      case BookingStatus.pending:
        return 'Ожидает подтверждения от специалиста';
      case BookingStatus.confirmed:
        return 'Бронирование подтверждено';
      case BookingStatus.completed:
        return 'Услуга оказана';
      case BookingStatus.cancelled:
        return 'Бронирование отменено';
      case BookingStatus.rejected:
        return 'Бронирование отклонено';
    }
  }

  /// Получить цвет статуса
  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.rejected:
        return Colors.red;
    }
  }

  /// Получить иконку статуса
  IconData get icon {
    switch (this) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle_outline;
      case BookingStatus.completed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.rejected:
        return Icons.close;
    }
  }

  /// Получить порядок сортировки
  int get sortOrder {
    switch (this) {
      case BookingStatus.pending:
        return 1;
      case BookingStatus.confirmed:
        return 2;
      case BookingStatus.completed:
        return 3;
      case BookingStatus.cancelled:
        return 4;
      case BookingStatus.rejected:
        return 5;
    }
  }

  /// Проверить, можно ли отменить бронирование
  bool get canCancel =>
      this == BookingStatus.pending || this == BookingStatus.confirmed;

  /// Проверить, можно ли подтвердить бронирование
  bool get canConfirm => this == BookingStatus.pending;

  /// Проверить, можно ли отклонить бронирование
  bool get canReject => this == BookingStatus.pending;

  /// Проверить, можно ли завершить бронирование
  bool get canComplete => this == BookingStatus.confirmed;
}

/// Информация о статусе бронирования
class BookingStatusInfo {
  const BookingStatusInfo({
    required this.status,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.sortOrder,
    required this.canCancel,
    required this.canConfirm,
    required this.canReject,
    required this.canComplete,
  });

  /// Создать из статуса
  factory BookingStatusInfo.fromStatus(BookingStatus status) =>
      BookingStatusInfo(
        status: status,
        name: status.name,
        description: status.description,
        color: status.color,
        icon: status.icon,
        sortOrder: status.sortOrder,
        canCancel: status.canCancel,
        canConfirm: status.canConfirm,
        canReject: status.canReject,
        canComplete: status.canComplete,
      );
  final BookingStatus status;
  final String name;
  final String description;
  final Color color;
  final IconData icon;
  final int sortOrder;
  final bool canCancel;
  final bool canConfirm;
  final bool canReject;
  final bool canComplete;
}

/// Утилиты для работы со статусами бронирований
class BookingStatusUtils {
  /// Получить все доступные статусы
  static List<BookingStatus> get allStatuses => BookingStatus.values;

  /// Получить активные статусы (не завершенные)
  static List<BookingStatus> get activeStatuses => [
        BookingStatus.pending,
        BookingStatus.confirmed,
      ];

  /// Получить завершенные статусы
  static List<BookingStatus> get completedStatuses => [
        BookingStatus.completed,
        BookingStatus.cancelled,
        BookingStatus.rejected,
      ];

  /// Получить статусы для клиента
  static List<BookingStatus> get customerStatuses => [
        BookingStatus.pending,
        BookingStatus.confirmed,
        BookingStatus.completed,
        BookingStatus.cancelled,
      ];

  /// Получить статусы для специалиста
  static List<BookingStatus> get specialistStatuses => [
        BookingStatus.pending,
        BookingStatus.confirmed,
        BookingStatus.completed,
        BookingStatus.rejected,
      ];

  /// Получить информацию о статусе
  static BookingStatusInfo getStatusInfo(BookingStatus status) =>
      BookingStatusInfo.fromStatus(status);

  /// Получить следующий возможный статус
  static BookingStatus? getNextStatus(BookingStatus currentStatus) {
    switch (currentStatus) {
      case BookingStatus.pending:
        return BookingStatus.confirmed;
      case BookingStatus.confirmed:
        return BookingStatus.completed;
      case BookingStatus.completed:
        return null; // Финальный статус
      case BookingStatus.cancelled:
        return null; // Финальный статус
      case BookingStatus.rejected:
        return null; // Финальный статус
    }
  }

  /// Получить возможные действия для статуса
  static List<BookingAction> getAvailableActions(BookingStatus status) {
    final actions = <BookingAction>[];

    if (status.canConfirm) {
      actions.add(BookingAction.confirm);
    }
    if (status.canReject) {
      actions.add(BookingAction.reject);
    }
    if (status.canCancel) {
      actions.add(BookingAction.cancel);
    }
    if (status.canComplete) {
      actions.add(BookingAction.complete);
    }

    return actions;
  }
}

/// Действия с бронированием
enum BookingAction {
  confirm, // Подтвердить
  reject, // Отклонить
  cancel, // Отменить
  complete, // Завершить
  view, // Просмотреть
  edit, // Редактировать
  delete, // Удалить
}

/// Расширения для BookingAction
extension BookingActionExtension on BookingAction {
  /// Получить название действия
  String get name {
    switch (this) {
      case BookingAction.confirm:
        return 'Подтвердить';
      case BookingAction.reject:
        return 'Отклонить';
      case BookingAction.cancel:
        return 'Отменить';
      case BookingAction.complete:
        return 'Завершить';
      case BookingAction.view:
        return 'Просмотреть';
      case BookingAction.edit:
        return 'Редактировать';
      case BookingAction.delete:
        return 'Удалить';
    }
  }

  /// Получить иконку действия
  IconData get icon {
    switch (this) {
      case BookingAction.confirm:
        return Icons.check;
      case BookingAction.reject:
        return Icons.close;
      case BookingAction.cancel:
        return Icons.cancel;
      case BookingAction.complete:
        return Icons.check_circle;
      case BookingAction.view:
        return Icons.visibility;
      case BookingAction.edit:
        return Icons.edit;
      case BookingAction.delete:
        return Icons.delete;
    }
  }

  /// Получить цвет действия
  Color get color {
    switch (this) {
      case BookingAction.confirm:
        return Colors.green;
      case BookingAction.reject:
        return Colors.red;
      case BookingAction.cancel:
        return Colors.orange;
      case BookingAction.complete:
        return Colors.blue;
      case BookingAction.view:
        return Colors.blue;
      case BookingAction.edit:
        return Colors.orange;
      case BookingAction.delete:
        return Colors.red;
    }
  }
}
