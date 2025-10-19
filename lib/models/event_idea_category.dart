import 'package:flutter/material.dart';

class EventIdeaCategory {
  final String id;
  final String name;
  final String description;
  final Color color;
  final String? icon;
  final int order;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const EventIdeaCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    this.icon,
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory EventIdeaCategory.fromMap(Map<String, dynamic> map) {
    return EventIdeaCategory(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      color: Color(map['color'] as int? ?? 0xFF6366F1),
      icon: map['icon']?.toString(),
      order: map['order'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.tryParse(map['updatedAt']?.toString() ?? '') 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color.toARGB32(),
      'icon': icon,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  EventIdeaCategory copyWith({
    String? id,
    String? name,
    String? description,
    Color? color,
    String? icon,
    int? order,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventIdeaCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}