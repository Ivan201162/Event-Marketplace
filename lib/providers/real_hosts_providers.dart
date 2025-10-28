import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/models/host_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Реальные провайдеры для хостов из Firestore
class RealHostsProviders {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Провайдер для получения всех хостов
  static final hostsProvider = StreamProvider<List<HostProfile>>((ref) {
    if (!FeatureFlags.useRealHosts) {
      return Stream.value([]);
    }

    return _firestore
        .collection('hosts')
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HostProfile.fromFirestore(doc);
      }).toList();
    });
  });

  /// Провайдер для получения хостов по городу
  static final hostsByCityProvider =
      StreamProvider.family<List<HostProfile>, String>((ref, city) {
    if (!FeatureFlags.useRealHosts) {
      return Stream.value([]);
    }

    return _firestore
        .collection('hosts')
        .where('city', isEqualTo: city)
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HostProfile.fromFirestore(doc);
      }).toList();
    });
  });

  /// Провайдер для получения хостов по категории
  static final hostsByCategoryProvider =
      StreamProvider.family<List<HostProfile>, String>((ref, categoryId) {
    if (!FeatureFlags.useRealHosts) {
      return Stream.value([]);
    }

    return _firestore
        .collection('hosts')
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HostProfile.fromFirestore(doc);
      }).toList();
    });
  });

  /// Провайдер для получения топ хостов
  static final topHostsProvider = StreamProvider<List<HostProfile>>((ref) {
    if (!FeatureFlags.useRealHosts) {
      return Stream.value([]);
    }

    return _firestore
        .collection('hosts')
        .where('isActive', isEqualTo: true)
        .where('rating', isGreaterThanOrEqualTo: 4.5)
        .orderBy('rating', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HostProfile.fromFirestore(doc);
      }).toList();
    });
  });

  /// Провайдер для поиска хостов
  static final searchHostsProvider =
      StreamProvider.family<List<HostProfile>, String>((ref, query) {
    if (!FeatureFlags.useRealHosts || query.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('hosts')
        .where('isActive', isEqualTo: true)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HostProfile.fromFirestore(doc);
      }).toList();
    });
  });

  /// Провайдер для получения хоста по ID
  static final hostByIdProvider =
      StreamProvider.family<HostProfile?, String>((ref, hostId) {
    if (!FeatureFlags.useRealHosts) {
      return Stream.value(null);
    }

    return _firestore.collection('hosts').doc(hostId).snapshots().map((doc) {
      if (doc.exists) {
        return HostProfile.fromFirestore(doc);
      }
      return null;
    });
  });

  /// Провайдер для состояния загрузки хостов
  static final hostsLoadingProvider = StateProvider<bool>((ref) => false);

  /// Провайдер для ошибок загрузки хостов
  static final hostsErrorProvider = StateProvider<String?>((ref) => null);
}
