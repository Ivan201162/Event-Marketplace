import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип рекламного объявления
enum AdvertisementType {
  feed('feed', 'В ленте'),
  ideas('ideas', 'В идеях'),
  search('search', 'В поиске'),
  banner('banner', 'Баннер');

  const AdvertisementType(this.value, this.displayName);

  final String value;
  final String displayName;

  static AdvertisementType fromString(String value) =>
      AdvertisementType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => AdvertisementType.banner,
      );
}

/// Статус рекламного объявления
enum AdvertisementStatus {
  pending('pending', 'На рассмотрении'),
  active('active', 'Активно'),
  paused('paused', 'Приостановлено'),
  rejected('rejected', 'Отклонено'),
  completed('completed', 'Завершено');

  const AdvertisementStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static AdvertisementStatus fromString(String value) =>
      AdvertisementStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => AdvertisementStatus.pending,
      );
}

/// Модель рекламного объявления
class Advertisement {
  const Advertisement({
    required this.id,
    required this.advertiserId,
    required this.type,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.targetUrl,
    required this.budget,
    required this.startDate,
    required this.endDate,
    required this.targetAudience,
    this.videoUrl,
    this.spentAmount = 0.0,
    this.status = AdvertisementStatus.pending,
    this.impressions = 0,
    this.clicks = 0,
    this.conversions = 0,
    this.ctr = 0.0,
    this.cpm = 0.0,
    this.cpc = 0.0,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать рекламу из Map
  factory Advertisement.fromMap(Map<String, dynamic> data) => Advertisement(
        id: data['id'] ?? '',
        advertiserId: data['advertiserId'] ?? '',
        type: AdvertisementType.fromString(data['type'] ?? 'banner'),
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        videoUrl: data['videoUrl'],
        targetUrl: data['targetUrl'] ?? '',
        budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
        spentAmount: (data['spentAmount'] as num?)?.toDouble() ?? 0.0,
        status: AdvertisementStatus.fromString(data['status'] ?? 'pending'),
        startDate: data['startDate'] != null
            ? (data['startDate'] is Timestamp
                ? (data['startDate'] as Timestamp).toDate()
                : DateTime.parse(data['startDate'].toString()))
            : DateTime.now(),
        endDate: data['endDate'] != null
            ? (data['endDate'] is Timestamp
                ? (data['endDate'] as Timestamp).toDate()
                : DateTime.parse(data['endDate'].toString()))
            : DateTime.now(),
        targetAudience: List<String>.from(data['targetAudience'] ?? []),
        impressions: data['impressions'] ?? 0,
        clicks: data['clicks'] ?? 0,
        conversions: data['conversions'] ?? 0,
        ctr: (data['ctr'] as num?)?.toDouble() ?? 0.0,
        cpm: (data['cpm'] as num?)?.toDouble() ?? 0.0,
        cpc: (data['cpc'] as num?)?.toDouble() ?? 0.0,
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.parse(data['createdAt'].toString()))
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] is Timestamp
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.parse(data['updatedAt'].toString()))
            : DateTime.now(),
      );

  /// Создать рекламу из DocumentSnapshot
  factory Advertisement.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Advertisement.fromMap({...data, 'id': doc.id});
  }

  final String id;
  final String advertiserId;
  final AdvertisementType type;
  final String title;
  final String description;
  final String imageUrl;
  final String? videoUrl;
  final String targetUrl;
  final double budget;
  final double spentAmount;
  final AdvertisementStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> targetAudience;
  final int impressions;
  final int clicks;
  final int conversions;
  final double ctr;
  final double cpm;
  final double cpc;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'advertiserId': advertiserId,
        'type': type.value,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        if (videoUrl != null) 'videoUrl': videoUrl,
        'targetUrl': targetUrl,
        'budget': budget,
        'spentAmount': spentAmount,
        'status': status.value,
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
        'targetAudience': targetAudience,
        'impressions': impressions,
        'clicks': clicks,
        'conversions': conversions,
        'ctr': ctr,
        'cpm': cpm,
        'cpc': cpc,
        'metadata': metadata,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  /// Создать копию с изменениями
  Advertisement copyWith({
    String? id,
    String? advertiserId,
    AdvertisementType? type,
    String? title,
    String? description,
    String? imageUrl,
    String? videoUrl,
    String? targetUrl,
    double? budget,
    double? spentAmount,
    AdvertisementStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? targetAudience,
    int? impressions,
    int? clicks,
    int? conversions,
    double? ctr,
    double? cpm,
    double? cpc,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Advertisement(
        id: id ?? this.id,
        advertiserId: advertiserId ?? this.advertiserId,
        type: type ?? this.type,
        title: title ?? this.title,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        videoUrl: videoUrl ?? this.videoUrl,
        targetUrl: targetUrl ?? this.targetUrl,
        budget: budget ?? this.budget,
        spentAmount: spentAmount ?? this.spentAmount,
        status: status ?? this.status,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        targetAudience: targetAudience ?? this.targetAudience,
        impressions: impressions ?? this.impressions,
        clicks: clicks ?? this.clicks,
        conversions: conversions ?? this.conversions,
        ctr: ctr ?? this.ctr,
        cpm: cpm ?? this.cpm,
        cpc: cpc ?? this.cpc,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Advertisement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Advertisement{id: $id, title: $title, type: $type, status: $status}';
}
