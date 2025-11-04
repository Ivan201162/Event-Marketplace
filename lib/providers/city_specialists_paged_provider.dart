import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/specialist_enhanced.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Результат пагинации
class PaginatedSpecialists {
  final List<SpecialistEnhanced> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedSpecialists({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });
}

/// Провайдер для специалистов города с пагинацией
final citySpecialistsPagedProvider = FutureProvider.family<PaginatedSpecialists, ({
  String city,
  DocumentSnapshot? startAfter,
  int limit,
})>((ref, params) async {
  try {
    final city = params.city;
    final startAfter = params.startAfter;
    final limit = params.limit;

    // Сначала пытаемся получить через specialist_scores (scoreWeekly)
    Query query = FirebaseFirestore.instance
        .collection('specialist_scores')
        .where('city', isEqualTo: city)
        .orderBy('scoreWeekly', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final scoresSnapshot = await query.get();

    if (scoresSnapshot.docs.isEmpty) {
      // Fallback на specialists напрямую по rating
      Query fallbackQuery = FirebaseFirestore.instance
          .collection('specialists')
          .where('city', isEqualTo: city)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit);

      if (startAfter != null) {
        fallbackQuery = fallbackQuery.startAfterDocument(startAfter);
      }

      final fallbackSnapshot = await fallbackQuery.get();
      final specialists = fallbackSnapshot.docs
          .map(SpecialistEnhanced.fromFirestore)
          .toList();

      return PaginatedSpecialists(
        items: specialists,
        lastDocument: fallbackSnapshot.docs.isNotEmpty
            ? fallbackSnapshot.docs.last
            : null,
        hasMore: fallbackSnapshot.docs.length == limit,
      );
    }

    // Получаем данные специалистов по ID из scores
    final specIds = scoresSnapshot.docs.map((doc) => doc.id).toList();
    final specialists = <SpecialistEnhanced>[];

    for (final specId in specIds) {
      try {
        final specDoc = await FirebaseFirestore.instance
            .collection('specialists')
            .doc(specId)
            .get();

        if (specDoc.exists && (specDoc.data()?['isActive'] == true)) {
          specialists.add(SpecialistEnhanced.fromFirestore(specDoc));
        }
      } catch (e) {
        debugPrint('Error loading specialist $specId: $e');
      }
    }

    return PaginatedSpecialists(
      items: specialists,
      lastDocument: scoresSnapshot.docs.isNotEmpty
          ? scoresSnapshot.docs.last
          : null,
      hasMore: scoresSnapshot.docs.length == limit,
    );
  } catch (e) {
    debugPrint('❌ Error fetching city specialists: $e');
    // Fallback на старую логику
    try {
      Query fallbackQuery = FirebaseFirestore.instance
          .collection('specialists')
          .where('city', isEqualTo: params.city)
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(params.limit);

      if (params.startAfter != null) {
        fallbackQuery = fallbackQuery.startAfterDocument(params.startAfter!);
      }

      final fallbackSnapshot = await fallbackQuery.get();
      final specialists = fallbackSnapshot.docs
          .map(SpecialistEnhanced.fromFirestore)
          .toList();

      return PaginatedSpecialists(
        items: specialists,
        lastDocument: fallbackSnapshot.docs.isNotEmpty
            ? fallbackSnapshot.docs.last
            : null,
        hasMore: fallbackSnapshot.docs.length == params.limit,
      );
    } catch (e2) {
      return PaginatedSpecialists(items: [], hasMore: false);
    }
  }
});

