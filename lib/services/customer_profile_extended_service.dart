import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/customer_profile_extended.dart';

/// Сервис для работы с расширенным профилем заказчика
class CustomerProfileExtendedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Получить расширенный профиль заказчика
  Future<CustomerProfileExtended?> getExtendedProfile(String userId) async {
    try {
      final doc = await _db
          .collection('customer_profiles_extended')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) {
        // Создаём расширенный профиль на основе базового
        return await _createExtendedProfile(userId);
      }

      return CustomerProfileExtended.fromDocument(doc.docs.first);
    } catch (e) {
      print('Error getting extended profile: $e');
      return null;
    }
  }

  /// Создать расширенный профиль
  Future<CustomerProfileExtended?> _createExtendedProfile(String userId) async {
    try {
      // Получаем базовый профиль
      final baseProfileDoc = await _db
          .collection('customer_profiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (baseProfileDoc.docs.isEmpty) {
        return null;
      }

      final baseProfile = CustomerProfile.fromDocument(baseProfileDoc.docs.first);
      
      // Создаём расширенный профиль
      final extendedProfile = CustomerProfileExtended(
        id: '',
        userId: userId,
        name: baseProfile.name,
        email: baseProfile.email,
        phone: baseProfile.phone,
        avatarUrl: baseProfile.avatarUrl,
        bio: baseProfile.bio,
        location: baseProfile.location,
        eventTypes: baseProfile.eventTypes,
        budgetRange: baseProfile.budgetRange,
        preferredDates: baseProfile.preferredDates,
        specialRequirements: baseProfile.specialRequirements,
        createdAt: baseProfile.createdAt,
        inspirationPhotos: [],
        notes: [],
        favoriteSpecialists: [],
        savedEvents: [],
        preferences: const CustomerPreferences(),
        lastUpdated: DateTime.now(),
      );

      final docRef = await _db.collection('customer_profiles_extended').add(extendedProfile.toMap());
      
      return extendedProfile.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating extended profile: $e');
      return null;
    }
  }

  /// Обновить расширенный профиль
  Future<void> updateExtendedProfile(CustomerProfileExtended profile) async {
    try {
      await _db
          .collection('customer_profiles_extended')
          .doc(profile.id)
          .update(profile.copyWith(lastUpdated: DateTime.now()).toMap());
    } catch (e) {
      print('Error updating extended profile: $e');
    }
  }

  /// Добавить фото для вдохновения
  Future<InspirationPhoto?> addInspirationPhoto({
    required String userId,
    required File imageFile,
    String? caption,
    List<String> tags = const [],
    bool isPublic = false,
  }) async {
    try {
      // Загружаем изображение в Firebase Storage
      final fileName = 'inspiration_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('inspiration_photos/$userId/$fileName');
      
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Создаём объект фото
      final photo = InspirationPhoto(
        id: '',
        url: downloadUrl,
        caption: caption,
        tags: tags,
        uploadedAt: DateTime.now(),
        isPublic: isPublic,
      );

      // Получаем расширенный профиль
      final profile = await getExtendedProfile(userId);
      if (profile == null) return null;

      // Добавляем фото к профилю
      final updatedPhotos = [...profile.inspirationPhotos, photo];
      final updatedProfile = profile.copyWith(inspirationPhotos: updatedPhotos);
      
      await updateExtendedProfile(updatedProfile);
      
      return photo;
    } catch (e) {
      print('Error adding inspiration photo: $e');
      return null;
    }
  }

  /// Удалить фото для вдохновения
  Future<void> removeInspirationPhoto(String userId, String photoId) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) return;

      // Находим фото для удаления
      final photoToRemove = profile.inspirationPhotos.firstWhere(
        (photo) => photo.id == photoId,
        orElse: () => throw Exception('Photo not found'),
      );

      // Удаляем из Storage
      try {
        final ref = _storage.refFromURL(photoToRemove.url);
        await ref.delete();
      } catch (e) {
        print('Error deleting photo from storage: $e');
      }

      // Удаляем из профиля
      final updatedPhotos = profile.inspirationPhotos
          .where((photo) => photo.id != photoId)
          .toList();
      
      final updatedProfile = profile.copyWith(inspirationPhotos: updatedPhotos);
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error removing inspiration photo: $e');
    }
  }

  /// Добавить заметку
  Future<CustomerNote?> addNote({
    required String userId,
    required String title,
    required String content,
    List<String> tags = const [],
    bool isPinned = false,
    String? eventId,
    String? specialistId,
  }) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) return null;

      final note = CustomerNote(
        id: '',
        title: title,
        content: content,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPinned: isPinned,
        eventId: eventId,
        specialistId: specialistId,
      );

      final updatedNotes = [...profile.notes, note];
      final updatedProfile = profile.copyWith(notes: updatedNotes);
      
      await updateExtendedProfile(updatedProfile);
      
      return note;
    } catch (e) {
      print('Error adding note: $e');
      return null;
    }
  }

  /// Обновить заметку
  Future<void> updateNote(String userId, CustomerNote updatedNote) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) return;

      final updatedNotes = profile.notes.map((note) {
        return note.id == updatedNote.id 
            ? updatedNote.copyWith(updatedAt: DateTime.now())
            : note;
      }).toList();

      final updatedProfile = profile.copyWith(notes: updatedNotes);
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error updating note: $e');
    }
  }

  /// Удалить заметку
  Future<void> removeNote(String userId, String noteId) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) return;

      final updatedNotes = profile.notes
          .where((note) => note.id != noteId)
          .toList();

      final updatedProfile = profile.copyWith(notes: updatedNotes);
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error removing note: $e');
    }
  }

  /// Добавить специалиста в избранное
  Future<void> addToFavorites(String userId, String specialistId) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) return;

      if (profile.favoriteSpecialists.contains(specialistId)) return;

      final updatedFavorites = [...profile.favoriteSpecialists, specialistId];
      final updatedProfile = profile.copyWith(favoriteSpecialists: updatedFavorites);
      
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error adding to favorites: $e');
    }
  }

  /// Удалить специалиста из избранного
  Future<void> removeFromFavorites(String userId, String specialistId) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) return;

      final updatedFavorites = profile.favoriteSpecialists
          .where((id) => id != specialistId)
          .toList();

      final updatedProfile = profile.copyWith(favoriteSpecialists: updatedFavorites);
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }

  /// Сохранить событие
  Future<void> saveEvent(String userId, String eventId) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) return;

      if (profile.savedEvents.contains(eventId)) return;

      final updatedSavedEvents = [...profile.savedEvents, eventId];
      final updatedProfile = profile.copyWith(savedEvents: updatedSavedEvents);
      
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error saving event: $e');
    }
  }

  /// Удалить сохранённое событие
  Future<void> unsaveEvent(String userId, String eventId) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) return;

      final updatedSavedEvents = profile.savedEvents
          .where((id) => id != eventId)
          .toList();

      final updatedProfile = profile.copyWith(savedEvents: updatedSavedEvents);
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error unsaving event: $e');
    }
  }

  /// Обновить предпочтения
  Future<void> updatePreferences(String userId, CustomerPreferences preferences) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) return;

      final updatedProfile = profile.copyWith(preferences: preferences);
      await updateExtendedProfile(updatedProfile);
    } catch (e) {
      print('Error updating preferences: $e');
    }
  }

  /// Получить заметки по тегу
  Future<List<CustomerNote>> getNotesByTag(String userId, String tag) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) return [];

      return profile.getNotesByTag(tag);
    } catch (e) {
      print('Error getting notes by tag: $e');
      return [];
    }
  }

  /// Получить фото по тегу
  Future<List<InspirationPhoto>> getPhotosByTag(String userId, String tag) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) return [];

      return profile.getPhotosByTag(tag);
    } catch (e) {
      print('Error getting photos by tag: $e');
      return [];
    }
  }

  /// Поиск по заметкам
  Future<List<CustomerNote>> searchNotes(String userId, String query) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) return [];

      final lowercaseQuery = query.toLowerCase();
      return profile.notes.where((note) {
        return note.title.toLowerCase().contains(lowercaseQuery) ||
               note.content.toLowerCase().contains(lowercaseQuery) ||
               note.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (e) {
      print('Error searching notes: $e');
      return [];
    }
  }

  /// Поиск по фото
  Future<List<InspirationPhoto>> searchPhotos(String userId, String query) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) return [];

      final lowercaseQuery = query.toLowerCase();
      return profile.inspirationPhotos.where((photo) {
        return (photo.caption?.toLowerCase().contains(lowercaseQuery) ?? false) ||
               photo.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (e) {
      print('Error searching photos: $e');
      return [];
    }
  }

  /// Получить статистику профиля
  Future<CustomerProfileStats> getProfileStats(String userId) async {
    try {
      final profile = await getExtendedProfile(userId);
      if (profile == null) {
        return CustomerProfileStats.empty();
      }

      return CustomerProfileStats(
        totalPhotos: profile.inspirationPhotos.length,
        publicPhotos: profile.publicPhotos.length,
        totalNotes: profile.notes.length,
        pinnedNotes: profile.pinnedNotes.length,
        favoriteSpecialists: profile.favoriteSpecialists.length,
        savedEvents: profile.savedEvents.length,
        totalTags: profile.allTags.length,
        lastActivity: profile.lastUpdated,
      );
    } catch (e) {
      print('Error getting profile stats: $e');
      return CustomerProfileStats.empty();
    }
  }
}

/// Статистика профиля заказчика
class CustomerProfileStats {
  final int totalPhotos;
  final int publicPhotos;
  final int totalNotes;
  final int pinnedNotes;
  final int favoriteSpecialists;
  final int savedEvents;
  final int totalTags;
  final DateTime lastActivity;

  const CustomerProfileStats({
    required this.totalPhotos,
    required this.publicPhotos,
    required this.totalNotes,
    required this.pinnedNotes,
    required this.favoriteSpecialists,
    required this.savedEvents,
    required this.totalTags,
    required this.lastActivity,
  });

  factory CustomerProfileStats.empty() {
    return CustomerProfileStats(
      totalPhotos: 0,
      publicPhotos: 0,
      totalNotes: 0,
      pinnedNotes: 0,
      favoriteSpecialists: 0,
      savedEvents: 0,
      totalTags: 0,
      lastActivity: DateTime.now(),
    );
  }
}
