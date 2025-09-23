import 'package:cloud_firestore/cloud_firestore.dart';

/// Результат пагинированного запроса
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedResult({
    required this.items,
    this.lastDocument,
    this.hasMore = false,
  });
}