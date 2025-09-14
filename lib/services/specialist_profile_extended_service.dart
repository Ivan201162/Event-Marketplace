import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/specialist_profile_extended.dart';
import '../models/specialist.dart';

/// Сервис для работы с расширенным профилем специалиста
class SpecialistProfileExtendedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Получить расширенный профиль специалиста
  Future<SpecialistProfileExtended?> getExtendedProfile(String specialistId) async {
    try {
      final doc = await _db
          .collection('specialist_profiles_extended')
          .where('userId', isEqualTo: specialistId)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) {
        // Создаём расширенный профиль на основе базового
        return await _createExtendedProfile(specialistId);
      }

      return SpecialistProfileExtended.fromDocument(doc.docs.first);
    } catch (e) {
      print('Error getting extended specialist profile: $e');
      return null;
    }
  }

  /// Создать расширенный профиль
  Future<SpecialistProfileExtended?> _createExtendedProfile(String specialistId) async {
    try {
      // Получаем базовый профиль
      final baseProfileDoc = await _db
          .collection('specialist_profiles')
          .where('userId', isEqualTo: specialistId)
          .limit(1)
          .get();

      if (baseProfileDoc.docs.isEmpty) {
        return null;
      }

      final baseProfile = Specialist.fromDocument(baseProfileDoc.docs.first);
      
      // Создаём расширенный профиль
      final extendedProfile = SpecialistProfileExtended.fromSpecialist(baseProfile);

      final docRef = await _db.collection('specialist_profiles_extended').add(extendedProfile.toMap());
      
      return extendedProfile.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating extended specialist profile: $e');
      return null;
    }
  }

  /// Обновить расширенный профиль
  Future<void> updateExtendedProfile(SpecialistProfileExtended profile) async {
    try {
      await _db
          .collection('specialist_profiles_extended')
          .doc(profile.id)
          .update(profile.copyWith(lastUpdated: DateTime.now()).toMap());
    } catch (e) {
      print('Error updating extended specialist profile: $e');
    }
  }

  /// Добавить FAQ элемент
  Future<FAQItem?> addFAQItem({
    required String specialistId,
    required String question,
    required String answer,
    required String category,
    int order = 0,
    bool isPublished = true,
  }) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return null;

      final faqItem = FAQItem(
        id: '',
        question: question,
        answer: answer,
        category: category,
        order: order,
        isPublished: isPublished,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedFAQItems = [...profile.faqItems, faqItem];
      final updatedProfile = profile.copyWith(faqItems: updatedFAQItems);
      
      await updateExtendedProfile(updatedProfile);
      
      return faqItem;
    } catch (e) {
      print('Error adding FAQ item: $e');
      return null;
    }
  }

  /// Обновить FAQ элемент
  Future<void> updateFAQItem(String specialistId, FAQItem updatedFAQItem) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return;

      final updatedFAQItems = profile.faqItems.map((item) {
        return item.id == updatedFAQItem.id 
            ? updatedFAQItem.copyWith(updatedAt: DateTime.now())
            : item;
      }).toList();

      final updatedProfile = profile.copyWith(faqItems: updatedFAQItems);
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error updating FAQ item: $e');
    }
  }

  /// Удалить FAQ элемент
  Future<void> removeFAQItem(String specialistId, String faqItemId) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return;

      final updatedFAQItems = profile.faqItems
          .where((item) => item.id != faqItemId)
          .toList();

      final updatedProfile = profile.copyWith(faqItems: updatedFAQItems);
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error removing FAQ item: $e');
    }
  }

  /// Добавить портфолио видео
  Future<PortfolioVideo?> addPortfolioVideo({
    required String specialistId,
    required String title,
    required String description,
    required String url,
    required String thumbnailUrl,
    required String platform,
    required String duration,
    List<String> tags = const [],
    bool isPublic = true,
  }) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return null;

      final video = PortfolioVideo(
        id: '',
        title: title,
        description: description,
        url: url,
        thumbnailUrl: thumbnailUrl,
        platform: platform,
        duration: duration,
        tags: tags,
        isPublic: isPublic,
        uploadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedVideos = [...profile.portfolioVideos, video];
      final updatedProfile = profile.copyWith(portfolioVideos: updatedVideos);
      
      await updateExtendedProfile(updatedProfile);
      
      return video;
    } catch (e) {
      print('Error adding portfolio video: $e');
      return null;
    }
  }

  /// Обновить портфолио видео
  Future<void> updatePortfolioVideo(String specialistId, PortfolioVideo updatedVideo) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return;

      final updatedVideos = profile.portfolioVideos.map((video) {
        return video.id == updatedVideo.id 
            ? updatedVideo.copyWith(updatedAt: DateTime.now())
            : video;
      }).toList();

      final updatedProfile = profile.copyWith(portfolioVideos: updatedVideos);
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error updating portfolio video: $e');
    }
  }

  /// Удалить портфолио видео
  Future<void> removePortfolioVideo(String specialistId, String videoId) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return;

      final updatedVideos = profile.portfolioVideos
          .where((video) => video.id != videoId)
          .toList();

      final updatedProfile = profile.copyWith(portfolioVideos: updatedVideos);
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error removing portfolio video: $e');
    }
  }

  /// Добавить сертификат
  Future<void> addCertification(String specialistId, String certification) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return;

      if (profile.certifications.contains(certification)) return;

      final updatedCertifications = [...profile.certifications, certification];
      final updatedProfile = profile.copyWith(certifications: updatedCertifications);
      
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error adding certification: $e');
    }
  }

  /// Удалить сертификат
  Future<void> removeCertification(String specialistId, String certification) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return;

      final updatedCertifications = profile.certifications
          .where((cert) => cert != certification)
          .toList();

      final updatedProfile = profile.copyWith(certifications: updatedCertifications);
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error removing certification: $e');
    }
  }

  /// Добавить награду
  Future<void> addAward(String specialistId, String award) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return;

      if (profile.awards.contains(award)) return;

      final updatedAwards = [...profile.awards, award];
      final updatedProfile = profile.copyWith(awards: updatedAwards);
      
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error adding award: $e');
    }
  }

  /// Удалить награду
  Future<void> removeAward(String specialistId, String award) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return;

      final updatedAwards = profile.awards
          .where((a) => a != award)
          .toList();

      final updatedProfile = profile.copyWith(awards: updatedAwards);
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error removing award: $e');
    }
  }

  /// Добавить отзыв
  Future<void> addTestimonial(String specialistId, String testimonial) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return;

      final updatedTestimonials = [...profile.testimonials, testimonial];
      final updatedProfile = profile.copyWith(testimonials: updatedTestimonials);
      
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error adding testimonial: $e');
    }
  }

  /// Удалить отзыв
  Future<void> removeTestimonial(String specialistId, String testimonial) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return;

      final updatedTestimonials = profile.testimonials
          .where((t) => t != testimonial)
          .toList();

      final updatedProfile = profile.copyWith(testimonials: updatedTestimonials);
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error removing testimonial: $e');
    }
  }

  /// Получить FAQ по категории
  Future<List<FAQItem>> getFAQByCategory(String specialistId, String category) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return [];

      return profile.faqItems
          .where((item) => item.category == category && item.isPublished)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      print('Error getting FAQ by category: $e');
      return [];
    }
  }

  /// Получить публичные видео
  Future<List<PortfolioVideo>> getPublicVideos(String specialistId) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return [];

      return profile.portfolioVideos
          .where((video) => video.isPublic)
          .toList()
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    } catch (e) {
      print('Error getting public videos: $e');
      return [];
    }
  }

  /// Поиск по FAQ
  Future<List<FAQItem>> searchFAQ(String specialistId, String query) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return [];

      final lowercaseQuery = query.toLowerCase();
      return profile.faqItems.where((item) {
        return item.question.toLowerCase().contains(lowercaseQuery) ||
               item.answer.toLowerCase().contains(lowercaseQuery) ||
               item.category.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      print('Error searching FAQ: $e');
      return [];
    }
  }

  /// Поиск по видео
  Future<List<PortfolioVideo>> searchVideos(String specialistId, String query) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) return [];

      final lowercaseQuery = query.toLowerCase();
      return profile.portfolioVideos.where((video) {
        return video.title.toLowerCase().contains(lowercaseQuery) ||
               video.description.toLowerCase().contains(lowercaseQuery) ||
               video.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (e) {
      print('Error searching videos: $e');
      return [];
    }
  }

  /// Получить статистику профиля
  Future<SpecialistProfileStats> getProfileStats(String specialistId) async {
    try {
      final profile = await getExtendedProfile(specialistId);
      if (profile == null) {
        return SpecialistProfileStats.empty();
      }

      return SpecialistProfileStats(
        totalFAQItems: profile.faqItems.length,
        publishedFAQItems: profile.faqItems.where((item) => item.isPublished).length,
        totalVideos: profile.portfolioVideos.length,
        publicVideos: profile.portfolioVideos.where((video) => video.isPublic).length,
        totalCertifications: profile.certifications.length,
        totalAwards: profile.awards.length,
        totalTestimonials: profile.testimonials.length,
        lastActivity: profile.lastUpdated,
      );
    } catch (e) {
      print('Error getting specialist profile stats: $e');
      return SpecialistProfileStats.empty();
    }
  }
}

/// Статистика профиля специалиста
class SpecialistProfileStats {
  final int totalFAQItems;
  final int publishedFAQItems;
  final int totalVideos;
  final int publicVideos;
  final int totalCertifications;
  final int totalAwards;
  final int totalTestimonials;
  final DateTime lastActivity;

  const SpecialistProfileStats({
    required this.totalFAQItems,
    required this.publishedFAQItems,
    required this.totalVideos,
    required this.publicVideos,
    required this.totalCertifications,
    required this.totalAwards,
    required this.totalTestimonials,
    required this.lastActivity,
  });

  factory SpecialistProfileStats.empty() {
    return SpecialistProfileStats(
      totalFAQItems: 0,
      publishedFAQItems: 0,
      totalVideos: 0,
      publicVideos: 0,
      totalCertifications: 0,
      totalAwards: 0,
      totalTestimonials: 0,
      lastActivity: DateTime.now(),
    );
  }
}
