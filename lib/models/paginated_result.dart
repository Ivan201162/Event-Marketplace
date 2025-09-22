import 'package:cloud_firestore/cloud_firestore.dart';

/// Результат пагинированного запроса
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.hasMore,
    this.lastDocument,
  });

  /// Список элементов
  final List<T> items;

  /// Есть ли еще данные для загрузки
  final bool hasMore;

  /// Последний документ для пагинации
  final DocumentSnapshot? lastDocument;

  /// Создать пустой результат
  factory PaginatedResult.empty() {
    return PaginatedResult<T>(
      items: [],
      hasMore: false,
    );
  }

  /// Создать результат из списка
  factory PaginatedResult.fromList(List<T> items, {bool hasMore = false}) {
    return PaginatedResult<T>(
      items: items,
      hasMore: hasMore,
    );
  }
}
