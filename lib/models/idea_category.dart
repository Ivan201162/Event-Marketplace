import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель категории идеи
class IdeaCategory {
  const IdeaCategory({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    this.color,
    this.parentId,
    this.children = const [],
    this.tags = const [],
    this.isActive = true,
    this.isFeatured = false,
    this.order = 0,
    this.ideasCount = 0,
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String? icon;
  final String? color;
  final String? parentId;
  final List<IdeaCategory> children;
  final List<String> tags;
  final bool isActive;
  final bool isFeatured;
  final int order;
  final int ideasCount;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Создать из Map
  factory IdeaCategory.fromMap(Map<String, dynamic> data) {
    return IdeaCategory(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String?,
      color: data['color'] as String?,
      parentId: data['parentId'] as String?,
      children: (data['children'] as List<dynamic>?)
              ?.map((e) => IdeaCategory.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      tags: List<String>.from(data['tags'] ?? []),
      isActive: data['isActive'] as bool? ?? true,
      isFeatured: data['isFeatured'] as bool? ?? false,
      order: data['order'] as int? ?? 0,
      ideasCount: data['ideasCount'] as int? ?? 0,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
    );
  }

  /// Создать из документа Firestore
  factory IdeaCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return IdeaCategory.fromMap({
      'id': doc.id,
      ...data,
    });
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
        'parentId': parentId,
        'children': children.map((e) => e.toMap()).toList(),
        'tags': tags,
        'isActive': isActive,
        'isFeatured': isFeatured,
        'order': order,
        'ideasCount': ideasCount,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Копировать с изменениями
  IdeaCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    String? parentId,
    List<IdeaCategory>? children,
    List<String>? tags,
    bool? isActive,
    bool? isFeatured,
    int? order,
    int? ideasCount,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      IdeaCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        parentId: parentId ?? this.parentId,
        children: children ?? this.children,
        tags: tags ?? this.tags,
        isActive: isActive ?? this.isActive,
        isFeatured: isFeatured ?? this.isFeatured,
        order: order ?? this.order,
        ideasCount: ideasCount ?? this.ideasCount,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Проверить, активна ли категория
  bool get isActive => isActive;

  /// Проверить, является ли категория рекомендуемой
  bool get isFeatured => isFeatured;

  /// Проверить, является ли категория родительской
  bool get isParent => parentId == null;

  /// Проверить, является ли категория дочерней
  bool get isChild => parentId != null;

  /// Проверить, есть ли дочерние категории
  bool get hasChildren => children.isNotEmpty;

  /// Проверить, есть ли теги
  bool get hasTags => tags.isNotEmpty;

  /// Проверить, есть ли иконка
  bool get hasIcon => icon != null && icon!.isNotEmpty;

  /// Проверить, есть ли цвет
  bool get hasColor => color != null && color!.isNotEmpty;

  /// Получить отформатированное количество идей
  String get formattedIdeasCount {
    if (ideasCount < 1000) {
      return ideasCount.toString();
    } else if (ideasCount < 1000000) {
      return '${(ideasCount / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(ideasCount / 1000000).toStringAsFixed(1)}M';
    }
  }

  /// Получить отображаемое название с количеством идей
  String get displayNameWithCount {
    return '$name ($formattedIdeasCount)';
  }

  /// Получить полное название с родительской категорией
  String get fullName {
    if (isChild) {
      return '$name (подкатегория)';
    }
    return name;
  }

  /// Получить иконку по умолчанию
  String get defaultIcon {
    if (hasIcon) return icon!;
    return '💡'; // Иконка лампочки по умолчанию
  }

  /// Получить цвет по умолчанию
  String get defaultColor {
    if (hasColor) return color!;
    return '#FF6B6B'; // Цвет по умолчанию
  }
}
