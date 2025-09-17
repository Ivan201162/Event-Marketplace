import 'package:cloud_firestore/cloud_firestore.dart';
import 'specialist.dart';

/// Расширенная модель профиля специалиста
class SpecialistProfileExtended {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final List<SpecialistCategory> categories;
  final int experienceYears;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> languages;
  final List<String> specializations;
  final List<String> equipment;
  final bool insurance;
  final List<String> licenses;
  final Map<String, dynamic> availability;
  final Map<String, dynamic> pricing;
  final Map<String, dynamic> policies;
  final List<String> gallery;
  final List<dynamic> reviews;
  final List<dynamic> bookings;
  final Map<String, dynamic> earnings;
  final Map<String, dynamic> performance;
  final Map<String, dynamic> verification;
  final List<dynamic> badges;
  final List<dynamic> achievements;
  final Map<String, dynamic> analytics;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> notifications;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> metadata;
  final String? portfolio;
  final Map<String, String> socialLinks;
  final List<FAQItem> faqItems;
  final List<PortfolioVideo> portfolioVideos;
  final List<String> certifications;
  final List<String> awards;
  final List<String> testimonials;
  final Map<String, dynamic> additionalInfo;
  final DateTime lastUpdated;

  const SpecialistProfileExtended({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.bio,
    this.location,
    this.categories = const [],
    this.experienceYears = 0,
    this.hourlyRate = 0.0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isAvailable = true,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.languages = const [],
    this.specializations = const [],
    this.equipment = const [],
    this.insurance = false,
    this.licenses = const [],
    this.availability = const {},
    this.pricing = const {},
    this.policies = const {},
    this.gallery = const [],
    this.reviews = const [],
    this.bookings = const [],
    this.earnings = const {},
    this.performance = const {},
    this.verification = const {},
    this.badges = const [],
    this.achievements = const [],
    this.analytics = const {},
    this.settings = const {},
    this.notifications = const {},
    this.preferences = const {},
    this.metadata = const {},
    this.portfolio,
    this.socialLinks = const {},
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
      email: specialist.contactInfo?['email'],
      phone: specialist.contactInfo?['phone'],
      avatarUrl: specialist.businessInfo?['avatarUrl'],
      bio: specialist.description,
      location: specialist.serviceAreas.isNotEmpty
          ? specialist.serviceAreas.first
          : null,
      categories: [specialist.category],
      experienceYears: specialist.yearsOfExperience,
      hourlyRate: specialist.hourlyRate,
      rating: specialist.rating,
      reviewCount: specialist.reviewCount,
      isAvailable: specialist.isAvailable,
      isVerified: specialist.isVerified,
      createdAt: specialist.createdAt,
      updatedAt: specialist.updatedAt,
      portfolio:
          specialist.portfolio.isNotEmpty ? specialist.portfolio.first : null,
      socialLinks: specialist.businessInfo?['socialLinks'] ?? {},
      languages: specialist.languages,
      specializations: specialist.subcategories,
      equipment: specialist.equipment,
      insurance: specialist.businessInfo?['insurance'],
      licenses: specialist.businessInfo?['licenses'],
      availability: {'isAvailable': specialist.isAvailable},
      pricing: specialist.businessInfo?['pricing'],
      policies: specialist.businessInfo?['policies'],
      gallery: specialist.businessInfo?['gallery'] ?? [],
      reviews: specialist.businessInfo?['reviews'] ?? [],
      bookings: specialist.businessInfo?['bookings'] ?? [],
      earnings: specialist.businessInfo?['earnings'],
      performance: specialist.businessInfo?['performance'],
      verification: {'isVerified': specialist.isVerified},
      badges: specialist.businessInfo?['badges'] ?? [],
      achievements: specialist.businessInfo?['achievements'] ?? [],
      analytics: specialist.businessInfo?['analytics'],
      settings: specialist.businessInfo?['settings'],
      notifications: specialist.businessInfo?['notifications'],
      preferences: specialist.businessInfo?['preferences'],
      metadata: specialist.metadata ?? {},
      lastUpdated: DateTime.now(),
    );
  }

  factory SpecialistProfileExtended.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SpecialistProfileExtended(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String,
      avatarUrl: data['avatarUrl'] as String?,
      bio: data['bio'] as String?,
      location: data['location'] as String?,
      categories: (data['categories'] as List?)
              ?.map((cat) => SpecialistCategory.values.firstWhere(
                    (category) => category.name == cat,
                    orElse: () => SpecialistCategory.photographer,
                  ))
              .toList() ??
          [],
      experienceYears: data['experienceYears'] as int? ?? 0,
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      isAvailable: data['isAvailable'] as bool? ?? true,
      isVerified: data['isVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      portfolio: data['portfolio'] as String?,
      socialLinks: Map<String, String>.from(data['socialLinks'] as Map? ?? {}),
      languages: List<String>.from(data['languages'] as List? ?? []),
      specializations:
          List<String>.from(data['specializations'] as List? ?? []),
      equipment: List<String>.from(data['equipment'] as List? ?? []),
      insurance: data['insurance'] as bool? ?? false,
      licenses: List<String>.from(data['licenses'] as List? ?? []),
      availability:
          Map<String, dynamic>.from(data['availability'] as Map? ?? {}),
      pricing: Map<String, dynamic>.from(data['pricing'] as Map? ?? {}),
      policies: Map<String, dynamic>.from(data['policies'] as Map? ?? {}),
      gallery: List<String>.from(data['gallery'] as List? ?? []),
      reviews: data['reviews'] as List? ?? [],
      bookings: data['bookings'] as List? ?? [],
      earnings: Map<String, dynamic>.from(data['earnings'] as Map? ?? {}),
      performance: Map<String, dynamic>.from(data['performance'] as Map? ?? {}),
      verification:
          Map<String, dynamic>.from(data['verification'] as Map? ?? {}),
      badges: data['badges'] as List? ?? [],
      achievements: data['achievements'] as List? ?? [],
      analytics: Map<String, dynamic>.from(data['analytics'] as Map? ?? {}),
      settings: Map<String, dynamic>.from(data['settings'] as Map? ?? {}),
      notifications:
          Map<String, dynamic>.from(data['notifications'] as Map? ?? {}),
      preferences: Map<String, dynamic>.from(data['preferences'] as Map? ?? {}),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      faqItems: (data['faqItems'] as List?)
              ?.map((faq) => FAQItem.fromMap(faq as Map<String, dynamic>))
              .toList() ??
          [],
      portfolioVideos: (data['portfolioVideos'] as List?)
              ?.map((video) =>
                  PortfolioVideo.fromMap(video as Map<String, dynamic>))
              .toList() ??
          [],
      certifications: List<String>.from(data['certifications'] as List? ?? []),
      awards: List<String>.from(data['awards'] as List? ?? []),
      testimonials: List<String>.from(data['testimonials'] as List? ?? []),
      additionalInfo:
          Map<String, dynamic>.from(data['additionalInfo'] as Map? ?? {}),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'location': location,
      'categories': categories.map((cat) => cat.name).toList(),
      'experienceYears': experienceYears,
      'hourlyRate': hourlyRate,
      'rating': rating,
      'reviewCount': reviewCount,
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'languages': languages,
      'specializations': specializations,
      'equipment': equipment,
      'insurance': insurance,
      'licenses': licenses,
      'availability': availability,
      'pricing': pricing,
      'policies': policies,
      'gallery': gallery,
      'reviews': reviews,
      'bookings': bookings,
      'earnings': earnings,
      'performance': performance,
      'verification': verification,
      'badges': badges,
      'achievements': achievements,
      'analytics': analytics,
      'settings': settings,
      'notifications': notifications,
      'preferences': preferences,
      'metadata': metadata,
      'portfolio': portfolio,
      'socialLinks': socialLinks,
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
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
