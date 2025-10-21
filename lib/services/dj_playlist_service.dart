import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../core/feature_flags.dart';
import '../models/dj_playlist.dart';

/// Сервис для работы с плейлистами и медиафайлами диджеев
class DJPlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Загрузить медиафайл
  Future<String> uploadMediaFile({
    required String djId,
    required File file,
    required String originalName,
    required MediaType type,
    Map<String, dynamic>? metadata,
  }) async {
    if (!FeatureFlags.djPlaylistsEnabled) {
      throw Exception('Плейлисты диджеев отключены');
    }

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$originalName';
      final filePath = 'dj_media/$djId/$fileName';

      // Загружаем файл в Firebase Storage
      final ref = _storage.ref().child(filePath);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Создаем запись в Firestore
      final mediaFile = MediaFile(
        id: '', // Будет установлен Firestore
        djId: djId,
        fileName: fileName,
        originalName: originalName,
        filePath: downloadUrl,
        type: type,
        status: MediaStatus.processing,
        fileSize: await file.length(),
        mimeType: _getMimeType(file.path),
        metadata: metadata ?? {},
        uploadedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('dj_media_files').add(mediaFile.toMap());

      // Обновляем статус на готов
      await _firestore.collection('dj_media_files').doc(docRef.id).update({
        'status': MediaStatus.ready.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error uploading media file: $e');
      throw Exception('Ошибка загрузки файла: $e');
    }
  }

  /// Получить медиафайлы диджея
  Stream<List<MediaFile>> getDJMediaFiles(String djId) {
    if (!FeatureFlags.djPlaylistsEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('dj_media_files')
        .where('djId', isEqualTo: djId)
        .where('status', isEqualTo: MediaStatus.ready.name)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => MediaFile.fromMap({'id': doc.id, ...doc.data()})).toList(),
        );
  }

  /// Создать плейлист
  Future<String> createPlaylist({
    required String djId,
    required String name,
    String? description,
    List<String>? mediaFileIds,
    bool isPublic = false,
    Map<String, dynamic>? settings,
  }) async {
    if (!FeatureFlags.djPlaylistsEnabled) {
      throw Exception('Плейлисты диджеев отключены');
    }

    try {
      final playlist = DJPlaylist(
        id: '', // Будет установлен Firestore
        djId: djId,
        name: name,
        description: description,
        mediaFileIds: mediaFileIds ?? [],
        mediaFiles: [], // Будет заполнено отдельно
        settings: settings ?? {},
        isPublic: isPublic,
        isDefault: false,
        playCount: 0,
        ratingCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('dj_playlists').add(playlist.toMap());

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating playlist: $e');
      throw Exception('Ошибка создания плейлиста: $e');
    }
  }

  /// Получить плейлисты диджея
  Stream<List<DJPlaylist>> getDJPlaylists(String djId) {
    if (!FeatureFlags.djPlaylistsEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('dj_playlists')
        .where('djId', isEqualTo: djId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) async {
          final playlists = <DJPlaylist>[];

          for (final doc in snapshot.docs) {
            final playlist = DJPlaylist.fromMap({'id': doc.id, ...doc.data()});

            // Загружаем медиафайлы для плейлиста
            final mediaFiles = await _getMediaFilesByIds(playlist.mediaFileIds);
            playlists.add(playlist.copyWith(mediaFiles: mediaFiles));
          }

          return playlists;
        })
        .asyncMap((future) => future);
  }

  /// Получить публичные плейлисты
  Stream<List<DJPlaylist>> getPublicPlaylists() {
    if (!FeatureFlags.djPlaylistsEnabled) {
      return Stream.value([]);
    }

    return _firestore
        .collection('dj_playlists')
        .where('isPublic', isEqualTo: true)
        .orderBy('playCount', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) async {
          final playlists = <DJPlaylist>[];

          for (final doc in snapshot.docs) {
            final playlist = DJPlaylist.fromMap({'id': doc.id, ...doc.data()});

            // Загружаем медиафайлы для плейлиста
            final mediaFiles = await _getMediaFilesByIds(playlist.mediaFileIds);
            playlists.add(playlist.copyWith(mediaFiles: mediaFiles));
          }

          return playlists;
        })
        .asyncMap((future) => future);
  }

  /// Обновить плейлист
  Future<void> updatePlaylist(String playlistId, Map<String, dynamic> updates) async {
    if (!FeatureFlags.djPlaylistsEnabled) {
      throw Exception('Плейлисты диджеев отключены');
    }

    try {
      await _firestore.collection('dj_playlists').doc(playlistId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating playlist: $e');
      throw Exception('Ошибка обновления плейлиста: $e');
    }
  }

  /// Удалить плейлист
  Future<void> deletePlaylist(String playlistId) async {
    if (!FeatureFlags.djPlaylistsEnabled) {
      throw Exception('Плейлисты диджеев отключены');
    }

    try {
      await _firestore.collection('dj_playlists').doc(playlistId).delete();
    } catch (e) {
      debugPrint('Error deleting playlist: $e');
      throw Exception('Ошибка удаления плейлиста: $e');
    }
  }

  /// Удалить медиафайл
  Future<void> deleteMediaFile(String mediaFileId) async {
    if (!FeatureFlags.djPlaylistsEnabled) {
      throw Exception('Плейлисты диджеев отключены');
    }

    try {
      // Получаем информацию о файле
      final doc = await _firestore.collection('dj_media_files').doc(mediaFileId).get();

      if (!doc.exists) {
        throw Exception('Файл не найден');
      }

      final mediaFile = MediaFile.fromMap({'id': doc.id, ...doc.data()!});

      // Удаляем файл из Storage
      try {
        final ref = _storage.refFromURL(mediaFile.filePath);
        await ref.delete();
      } catch (e) {
        debugPrint('Error deleting file from storage: $e');
      }

      // Удаляем запись из Firestore
      await _firestore.collection('dj_media_files').doc(mediaFileId).delete();

      // Удаляем файл из всех плейлистов
      await _removeMediaFileFromPlaylists(mediaFileId);
    } catch (e) {
      debugPrint('Error deleting media file: $e');
      throw Exception('Ошибка удаления файла: $e');
    }
  }

  /// Импортировать VK плейлист
  Future<String> importVKPlaylist({
    required String djId,
    required String vkPlaylistUrl,
    required String playlistName,
    String? description,
  }) async {
    if (!FeatureFlags.djPlaylistsEnabled) {
      throw Exception('Плейлисты диджеев отключены');
    }

    try {
      // В демо-режиме создаем mock плейлист
      final mockPlaylist = _createMockVKPlaylist();

      // Создаем плейлист
      final playlistId = await createPlaylist(
        djId: djId,
        name: playlistName,
        description: description ?? 'Импортировано из VK',
        settings: {
          'source': 'vk',
          'vk_url': vkPlaylistUrl,
          'imported_at': DateTime.now().toIso8601String(),
        },
      );

      // TODO(developer): В реальном приложении здесь будет логика импорта треков из VK
      // Пока создаем mock медиафайлы
      final mockMediaFiles = _createMockMediaFiles(djId, mockPlaylist.tracks);

      // Добавляем mock медиафайлы в плейлист
      await updatePlaylist(playlistId, {
        'mediaFileIds': mockMediaFiles.map((file) => file.id).toList(),
      });

      return playlistId;
    } catch (e) {
      debugPrint('Error importing VK playlist: $e');
      throw Exception('Ошибка импорта VK плейлиста: $e');
    }
  }

  /// Скачать трек из VK
  Future<File?> downloadVKTrack(VKTrack track) async {
    if (!FeatureFlags.djPlaylistsEnabled) {
      return null;
    }

    try {
      if (track.url == null) {
        throw Exception('URL трека недоступен');
      }

      final response = await http.get(Uri.parse(track.url!));
      if (response.statusCode != 200) {
        throw Exception('Ошибка загрузки трека');
      }

      final directory = await getTemporaryDirectory();
      final fileName = '${track.artist} - ${track.title}.mp3';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      debugPrint('Error downloading VK track: $e');
      return null;
    }
  }

  /// Получить медиафайлы по ID
  Future<List<MediaFile>> _getMediaFilesByIds(List<String> mediaFileIds) async {
    if (mediaFileIds.isEmpty) return [];

    try {
      final query = await _firestore
          .collection('dj_media_files')
          .where(FieldPath.documentId, whereIn: mediaFileIds)
          .get();

      return query.docs.map((doc) => MediaFile.fromMap({'id': doc.id, ...doc.data()})).toList();
    } catch (e) {
      debugPrint('Error getting media files by IDs: $e');
      return [];
    }
  }

  /// Удалить медиафайл из всех плейлистов
  Future<void> _removeMediaFileFromPlaylists(String mediaFileId) async {
    try {
      final playlistsQuery = await _firestore
          .collection('dj_playlists')
          .where('mediaFileIds', arrayContains: mediaFileId)
          .get();

      final batch = _firestore.batch();

      for (final doc in playlistsQuery.docs) {
        final playlist = DJPlaylist.fromMap({'id': doc.id, ...doc.data()});

        final updatedMediaFileIds = playlist.mediaFileIds.where((id) => id != mediaFileId).toList();

        batch.update(doc.reference, {
          'mediaFileIds': updatedMediaFileIds,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error removing media file from playlists: $e');
    }
  }

  /// Получить MIME тип файла
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'flac':
        return 'audio/flac';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/avi';
      case 'mov':
        return 'video/quicktime';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  /// Создать mock VK плейлист для демонстрации
  VKPlaylist _createMockVKPlaylist() => VKPlaylist(
    id: 'mock_vk_playlist',
    title: 'Лучшие хиты 2024',
    description: 'Популярные треки этого года',
    coverImageUrl: 'https://via.placeholder.com/300x300/4CAF50/FFFFFF?text=VK+Playlist',
    trackCount: 5,
    ownerId: 'mock_user',
    ownerName: 'Mock DJ',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    tracks: [
      const VKTrack(
        id: '1',
        title: 'Summer Vibes',
        artist: 'Chill Artist',
        duration: Duration(minutes: 3, seconds: 45),
        url: 'https://example.com/track1.mp3',
        albumTitle: 'Summer Collection',
      ),
      const VKTrack(
        id: '2',
        title: 'Night Drive',
        artist: 'Electronic DJ',
        duration: Duration(minutes: 4, seconds: 12),
        url: 'https://example.com/track2.mp3',
        albumTitle: 'Night Sessions',
      ),
      const VKTrack(
        id: '3',
        title: 'Dance Floor',
        artist: 'Party Master',
        duration: Duration(minutes: 3, seconds: 28),
        url: 'https://example.com/track3.mp3',
        albumTitle: 'Club Hits',
      ),
      const VKTrack(
        id: '4',
        title: 'Sunset Dreams',
        artist: 'Ambient Creator',
        duration: Duration(minutes: 5, seconds: 33),
        url: 'https://example.com/track4.mp3',
        albumTitle: 'Dreams & Visions',
      ),
      const VKTrack(
        id: '5',
        title: 'Energy Boost',
        artist: 'Power DJ',
        duration: Duration(minutes: 3, seconds: 56),
        url: 'https://example.com/track5.mp3',
        albumTitle: 'High Energy',
      ),
    ],
  );

  /// Создать mock медиафайлы для демонстрации
  List<MediaFile> _createMockMediaFiles(String djId, List<VKTrack> tracks) => tracks
      .map(
        (track) => MediaFile(
          id: 'mock_${track.id}',
          djId: djId,
          fileName: '${track.artist} - ${track.title}.mp3',
          originalName: '${track.artist} - ${track.title}.mp3',
          filePath: track.url ?? 'https://example.com/mock_track.mp3',
          type: MediaType.audio,
          status: MediaStatus.ready,
          fileSize: 5000000, // 5MB
          duration: track.duration,
          mimeType: 'audio/mpeg',
          metadata: {
            'artist': track.artist,
            'title': track.title,
            'album': track.albumTitle,
            'source': 'vk_import',
          },
          uploadedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      )
      .toList();

  /// Получить статистику плейлистов диджея
  Future<Map<String, dynamic>> getDJPlaylistStats(String djId) async {
    if (!FeatureFlags.djPlaylistsEnabled) {
      return {};
    }

    try {
      final playlistsQuery = await _firestore
          .collection('dj_playlists')
          .where('djId', isEqualTo: djId)
          .get();

      final mediaFilesQuery = await _firestore
          .collection('dj_media_files')
          .where('djId', isEqualTo: djId)
          .get();

      final stats = <String, dynamic>{
        'total_playlists': playlistsQuery.docs.length,
        'total_media_files': mediaFilesQuery.docs.length,
        'total_play_count': 0,
        'total_size': 0,
        'total_duration': 0,
        'public_playlists': 0,
      };

      for (final doc in playlistsQuery.docs) {
        final playlist = DJPlaylist.fromMap({'id': doc.id, ...doc.data()});

        stats['total_play_count'] = (stats['total_play_count'] as int) + playlist.playCount;
        if (playlist.isPublic) {
          stats['public_playlists'] = (stats['public_playlists'] as int) + 1;
        }
      }

      for (final doc in mediaFilesQuery.docs) {
        final mediaFile = MediaFile.fromMap({'id': doc.id, ...doc.data()});

        stats['total_size'] = (stats['total_size'] as int) + mediaFile.fileSize;
        if (mediaFile.duration != null) {
          stats['total_duration'] =
              (stats['total_duration'] as int) + mediaFile.duration!.inSeconds;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting DJ playlist stats: $e');
      return {};
    }
  }
}
