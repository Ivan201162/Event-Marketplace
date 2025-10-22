import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist.dart';
import '../core/feature_flags.dart';

/// Реальные провайдеры для специалистов из Firestore
class RealSpecialistsProviders {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Провайдер для получения всех специалистов
  static final specialistsProvider = StreamProvider<List<Specialist>>((ref) {
    if (!FeatureFlags.useRealSpecialists) {
      return Stream.value([]);
    }

    return _firestore
        .collection('specialists')
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Specialist.fromFirestore(doc);
      }).toList();
    });
  });

  /// Провайдер для получения специалистов по категории
  static final specialistsByCategoryProvider = StreamProvider.family<List<Specialist>, String>((ref, categoryId) {
    if (!FeatureFlags.useRealSpecialists) {
      return Stream.value([]);
    }

    return _firestore
        .collection('specialists')
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Specialist.fromFirestore(doc);
      }).toList();
    });
  });

  /// Провайдер для получения топ специалистов
  static final topSpecialistsProvider = StreamProvider<List<Specialist>>((ref) {
    if (!FeatureFlags.useRealSpecialists) {
      return Stream.value([]);
    }

    return _firestore
        .collection('specialists')
        .where('isActive', isEqualTo: true)
        .where('rating', isGreaterThanOrEqualTo: 4.5)
        .orderBy('rating', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Specialist.fromFirestore(doc);
      }).toList();
    });
  });

  /// Провайдер для поиска специалистов
  static final searchSpecialistsProvider = StreamProvider.family<List<Specialist>, String>((ref, query) {
    if (!FeatureFlags.useRealSpecialists || query.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('specialists')
        .where('isActive', isEqualTo: true)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Specialist.fromFirestore(doc);
      }).toList();
    });
  });

  /// Провайдер для получения специалиста по ID
  static final specialistByIdProvider = StreamProvider.family<Specialist?, String>((ref, specialistId) {
    if (!FeatureFlags.useRealSpecialists) {
      return Stream.value(null);
    }

    return _firestore
        .collection('specialists')
        .doc(specialistId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return Specialist.fromFirestore(doc);
      }
      return null;
    });
  });

  /// Провайдер для состояния загрузки специалистов
  static final specialistsLoadingProvider = Provider<bool>((ref) => false);

  /// Провайдер для ошибок загрузки специалистов
  static final specialistsErrorProvider = Provider<String?>((ref) => null);
}
