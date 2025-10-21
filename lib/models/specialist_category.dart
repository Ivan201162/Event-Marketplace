import 'package:equatable/equatable.dart';

/// Specialist category model
class SpecialistCategory extends Equatable {
  final String id;
  final String name;
  final String displayName;
  final String? description;
  final String? icon;
  final String? color;
  final List<String> subcategories;
  final bool isActive;
  final int sortOrder;

  const SpecialistCategory({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.icon,
    this.color,
    this.subcategories = const [],
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// Create SpecialistCategory from Map
  factory SpecialistCategory.fromMap(Map<String, dynamic> data) {
    return SpecialistCategory(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      displayName: data['displayName'] ?? '',
      description: data['description'],
      icon: data['icon'],
      color: data['color'],
      subcategories: List<String>.from(data['subcategories'] ?? []),
      isActive: data['isActive'] ?? true,
      sortOrder: data['sortOrder'] ?? 0,
    );
  }

  /// Convert SpecialistCategory to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
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

  /// Create a copy with updated fields
  SpecialistCategory copyWith({
    String? id,
    String? name,
    String? displayName,
    String? description,
    String? icon,
    String? color,
    List<String>? subcategories,
    bool? isActive,
    int? sortOrder,
  }) {
    return SpecialistCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      subcategories: subcategories ?? this.subcategories,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        displayName,
        description,
        icon,
        color,
        subcategories,
        isActive,
        sortOrder,
      ];

  @override
  String toString() {
    return 'SpecialistCategory(id: $id, name: $name, displayName: $displayName)';
  }
}

/// Predefined specialist categories
enum SpecialistCategoryEnum {
  host('host', 'Ведущий', '🎤'),
  dj('dj', 'DJ', '🎧'),
  photographer('photographer', 'Фотограф', '📸'),
  videographer('videographer', 'Видеограф', '🎥'),
  decorator('decorator', 'Декоратор', '🎨'),
  florist('florist', 'Флорист', '🌸'),
  musician('musician', 'Музыкант', '🎵'),
  dancer('dancer', 'Танцор', '💃'),
  animator('animator', 'Аниматор', '🎭'),
  security('security', 'Охрана', '🛡️'),
  catering('catering', 'Кейтеринг', '🍽️'),
  transport('transport', 'Транспорт', '🚗'),
  equipment('equipment', 'Оборудование', '🔧'),
  other('other', 'Другое', '⭐');

  const SpecialistCategoryEnum(this.id, this.displayName, this.icon);

  final String id;
  final String displayName;
  final String icon;

  /// Get category by id
  static SpecialistCategoryEnum? getById(String id) {
    try {
      return SpecialistCategoryEnum.values.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all active categories
  static List<SpecialistCategoryEnum> get activeCategories {
    return SpecialistCategoryEnum.values.where((e) => e != SpecialistCategoryEnum.other).toList();
  }
}
