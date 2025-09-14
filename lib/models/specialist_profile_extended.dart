import 'package:cloud_firestore/cloud_firestore.dart';
import 'specialist.dart';

/// Расширенная модель профиля специалиста
class SpecialistProfileExtended extends Specialist {
  final List<FAQItem> faqItems;
  final List<PortfolioVideo> portfolioVideos;
  final List<String> certifications;
  final List<String> awards;
  final List<String> testimonials;
  final Map<String, dynamic> additionalInfo;
  final DateTime lastUpdated;

  const SpecialistProfileExtended({
    required super.id,
    required super.userId,
    required super.name,
    required super.email,
    required super.phone,
    super.avatarUrl,
    super.bio,
    required super.location,
    required super.categories,
    required super.experienceYears,
    required super.hourlyRate,
    required super.rating,
    required super.reviewCount,
    required super.isAvailable,
    required super.createdAt,
    super.portfolio,
    super.socialLinks,
    super.languages,
    super.specializations,
    super.equipment,
    super.insurance,
    super.licenses,
    super.availability,
    super.pricing,
    super.policies,
    super.gallery,
    super.reviews,
    super.bookings,
    super.earnings,
    super.performance,
    super.verification,
    super.badges,
    super.achievements,
    super.analytics,
    super.settings,
    super.notifications,
    super.preferences,
    super.metadata,
    this.faqItems = const [],
    this.portfolioVideos = const [],
    this.certifications = const [],
    this.awards = const [],
    this.testimonials = const [],
    this.additionalInfo = const {},
    required this.lastUpdated,
  });

  factory SpecialistProfileExtended.fromSpecialist(Specialist specialist) {
    return SpecialistProfileExtended(
      id: specialist.id,
      userId: specialist.userId,
      name: specialist.name,
      email: specialist.email,
      phone: specialist.phone,
      avatarUrl: specialist.avatarUrl,
      bio: specialist.bio,
      location: specialist.location,
      categories: specialist.categories,
      experienceYears: specialist.experienceYears,
      hourlyRate: specialist.hourlyRate,
      rating: specialist.rating,
      reviewCount: specialist.reviewCount,
      isAvailable: specialist.isAvailable,
      createdAt: specialist.createdAt,
      portfolio: specialist.portfolio,
      socialLinks: specialist.socialLinks,
      languages: specialist.languages,
      specializations: specialist.specializations,
      equipment: specialist.equipment,
      insurance: specialist.insurance,
      licenses: specialist.licenses,
      availability: specialist.availability,
      pricing: specialist.pricing,
      policies: specialist.policies,
      gallery: specialist.gallery,
      reviews: specialist.reviews,
      bookings: specialist.bookings,
      earnings: specialist.earnings,
      performance: specialist.performance,
      verification: specialist.verification,
      badges: specialist.badges,
      achievements: specialist.achievements,
      analytics: specialist.analytics,
      settings: specialist.settings,
      notifications: specialist.notifications,
      preferences: specialist.preferences,
      metadata: specialist.metadata,
      lastUpdated: DateTime.now(),
    );
  }

  factory SpecialistProfileExtended.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SpecialistProfileExtended(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      avatarUrl: data['avatarUrl'],
      bio: data['bio'],
      location: data['location'] ?? '',
      categories: (data['categories'] as List<dynamic>?)
          ?.map((e) => SpecialistCategory.values.firstWhere(
                (cat) => cat.name == e,
                orElse: () => SpecialistCategory.photographer,
              ))
          .toList() ?? [],
      experienceYears: data['experienceYears'] ?? 0,
      hourlyRate: (data['hourlyRate'] ?? 0).toDouble(),
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      portfolio: data['portfolio'],
      socialLinks: Map<String, String>.from(data['socialLinks'] ?? {}),
      languages: List<String>.from(data['languages'] ?? []),
      specializations: List<String>.from(data['specializations'] ?? []),
      equipment: List<String>.from(data['equipment'] ?? []),
      insurance: data['insurance'],
      licenses: List<String>.from(data['licenses'] ?? []),
      availability: data['availability'],
      pricing: data['pricing'],
      policies: data['policies'],
      gallery: List<String>.from(data['gallery'] ?? []),
      reviews: data['reviews'],
      bookings: data['bookings'],
      earnings: data['earnings'],
      performance: data['performance'],
      verification: data['verification'],
      badges: data['badges'],
      achievements: data['achievements'],
      analytics: data['analytics'],
      settings: data['settings'],
      notifications: data['notifications'],
      preferences: data['preferences'],
      metadata: data['metadata'],
      faqItems: (data['faqItems'] as List<dynamic>?)
          ?.map((e) => FAQItem.fromMap(e))
          .toList() ?? [],
      portfolioVideos: (data['portfolioVideos'] as List<dynamic>?)
          ?.map((e) => PortfolioVideo.fromMap(e))
          .toList() ?? [],
      certifications: List<String>.from(data['certifications'] ?? []),
      awards: List<String>.from(data['awards'] ?? []),
      testimonials: List<String>.from(data['testimonials'] ?? []),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'faqItems': faqItems.map((e) => e.toMap()).toList(),
      'portfolioVideos': portfolioVideos.map((e) => e.toMap()).toList(),
      'certifications': certifications,
      'awards': awards,
      'testimonials': testimonials,
      'additionalInfo': additionalInfo,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  SpecialistProfileExtended copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? location,
    List<SpecialistCategory>? categories,
    int? experienceYears,
    double? hourlyRate,
    double? rating,
    int? reviewCount,
    bool? isAvailable,
    DateTime? createdAt,
    String? portfolio,
    Map<String, String>? socialLinks,
    List<String>? languages,
    List<String>? specializations,
    List<String>? equipment,
    bool? insurance,
    List<String>? licenses,
    Map<String, dynamic>? availability,
    Map<String, dynamic>? pricing,
    Map<String, dynamic>? policies,
    List<String>? gallery,
    List<dynamic>? reviews,
    List<dynamic>? bookings,
    Map<String, dynamic>? earnings,
    Map<String, dynamic>? performance,
    Map<String, dynamic>? verification,
    List<dynamic>? badges,
    List<dynamic>? achievements,
    Map<String, dynamic>? analytics,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? notifications,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
    List<FAQItem>? faqItems,
    List<PortfolioVideo>? portfolioVideos,
    List<String>? certifications,
    List<String>? awards,
    List<String>? testimonials,
    Map<String, dynamic>? additionalInfo,
    DateTime? lastUpdated,
  }) {
    return SpecialistProfileExtended(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      categories: categories ?? this.categories,
      experienceYears: experienceYears ?? this.experienceYears,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      portfolio: portfolio ?? this.portfolio,
      socialLinks: socialLinks ?? this.socialLinks,
      languages: languages ?? this.languages,
      specializations: specializations ?? this.specializations,
      equipment: equipment ?? this.equipment,
      insurance: insurance ?? this.insurance,
      licenses: licenses ?? this.licenses,
      availability: availability ?? this.availability,
      pricing: pricing ?? this.pricing,
      policies: policies ?? this.policies,
      gallery: gallery ?? this.gallery,
      reviews: reviews ?? this.reviews,
      bookings: bookings ?? this.bookings,
      earnings: earnings ?? this.earnings,
      performance: performance ?? this.performance,
      verification: verification ?? this.verification,
      badges: badges ?? this.badges,
      achievements: achievements ?? this.achievements,
      analytics: analytics ?? this.analytics,
      settings: settings ?? this.settings,
      notifications: notifications ?? this.notifications,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
      faqItems: faqItems ?? this.faqItems,
      portfolioVideos: portfolioVideos ?? this.portfolioVideos,
      certifications: certifications ?? this.certifications,
      awards: awards ?? this.awards,
      testimonials: testimonials ?? this.testimonials,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Элемент FAQ
class FAQItem {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int order;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.order,
    this.isPublished = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FAQItem.fromMap(Map<String, dynamic> map) {
    return FAQItem(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      category: map['category'] ?? 'general',
      order: map['order'] ?? 0,
      isPublished: map['isPublished'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'order': order,
      'isPublished': isPublished,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FAQItem copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    int? order,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FAQItem(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      order: order ?? this.order,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Портфолио видео
class PortfolioVideo {
  final String id;
  final String title;
  final String description;
  final String url;
  final String thumbnailUrl;
  final String platform; // youtube, vimeo, direct
  final String duration;
  final List<String> tags;
  final bool isPublic;
  final int viewCount;
  final DateTime uploadedAt;
  final DateTime updatedAt;

  const PortfolioVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.thumbnailUrl,
    required this.platform,
    required this.duration,
    this.tags = const [],
    this.isPublic = true,
    this.viewCount = 0,
    required this.uploadedAt,
    required this.updatedAt,
  });

  factory PortfolioVideo.fromMap(Map<String, dynamic> map) {
    return PortfolioVideo(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      url: map['url'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      platform: map['platform'] ?? 'youtube',
      duration: map['duration'] ?? '0:00',
      tags: List<String>.from(map['tags'] ?? []),
      isPublic: map['isPublic'] ?? true,
      viewCount: map['viewCount'] ?? 0,
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'platform': platform,
      'duration': duration,
      'tags': tags,
      'isPublic': isPublic,
      'viewCount': viewCount,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PortfolioVideo copyWith({
    String? id,
    String? title,
    String? description,
    String? url,
    String? thumbnailUrl,
    String? platform,
    String? duration,
    List<String>? tags,
    bool? isPublic,
    int? viewCount,
    DateTime? uploadedAt,
    DateTime? updatedAt,
  }) {
    return PortfolioVideo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      platform: platform ?? this.platform,
      duration: duration ?? this.duration,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      viewCount: viewCount ?? this.viewCount,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
