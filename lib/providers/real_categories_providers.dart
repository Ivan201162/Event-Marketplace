import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/feature_flags.dart';

/// Модель категории
class Category {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final String icon;
  final String color;
  final List<String> subcategories;
  final bool isActive;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.color,
    required this.subcategories,
    required this.isActive,
    required this.sortOrder,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      displayName: data['displayName'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
      color: data['color'] ?? '#000000',
      subcategories: List<String>.from(data['subcategories'] ?? []),
      isActive: data['isActive'] ?? true,
      sortOrder: data['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'displayName': displayName,
      'description': description,
      'icon': icon,
      'color': color,
      'subcategories': subcategories,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }
}

/// Реальные провайдеры для категорий из Firestore
class RealCategoriesProviders {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Провайдер для получения всех категорий
  static final categoriesProvider = StreamProvider<List<Category>>((ref) {
    if (!FeatureFlags.useRealCategories) {
      return Stream.value([]);
    }

    return _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Category.fromFirestore(doc);
      }).toList();
    });
  });

  /// Провайдер для получения категории по ID
  static final categoryByIdProvider =
      StreamProvider.family<Category?, String>((ref, categoryId) {
    if (!FeatureFlags.useRealCategories) {
      return Stream.value(null);
    }

    return _firestore
        .collection('categories')
        .doc(categoryId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return Category.fromFirestore(doc);
      }
      return null;
    });
  });

  /// Провайдер для состояния загрузки категорий
  static final categoriesLoadingProvider = Provider<bool>((ref) => false);

  /// Провайдер для ошибок загрузки категорий
  static final categoriesErrorProvider = Provider<String?>((ref) => null);
}
