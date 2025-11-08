import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Экран создания рилса
class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({super.key});

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  
  File? _selectedVideo;
  File? _posterFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать рилс'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading || _selectedVideo == null ? null : _createReel,
            child: Text(
              'Опубликовать',
              style: TextStyle(
                color: _isUploading || _selectedVideo == null
                    ? Colors.grey
                    : Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Выбор видео
            _buildVideoSelector(),
            
            const SizedBox(height: 24),
            
            // Превью видео
            if (_selectedVideo != null) _buildVideoPreview(),
            
            const SizedBox(height: 24),
            
            // Прогресс загрузки
            if (_isUploading) _buildUploadProgress(),
            
            const SizedBox(height: 24),
            
            // Информация
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выберите видео',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _selectedVideo == null
              ? InkWell(
                  onTap: _pickVideo,
                  borderRadius: BorderRadius.circular(12),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Нажмите для выбора видео',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _posterFile != null
                          ? Image.file(_posterFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                          : Container(
                              color: Colors.black,
                              child: const Center(
                                child: Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedVideo = null;
                            _posterFile = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _pickVideo,
          icon: const Icon(Icons.video_library),
          label: const Text('Выбрать видео'),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Превью видео',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _posterFile != null
                ? Image.file(_posterFile!, fit: BoxFit.cover)
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _generatePoster,
          icon: const Icon(Icons.image),
          label: const Text('Сгенерировать постер'),
        ),
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Загрузка...',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: _uploadProgress),
        const SizedBox(height: 4),
        Text(
          '${(_uploadProgress * 100).toStringAsFixed(0)}%',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Информация',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Видео до 60 секунд\n'
            '• Постер будет сгенерирован автоматически\n'
            '• Рилс будет доступен всем пользователям',
            style: TextStyle(color: Colors.blue[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _pickVideo() async {
    try {
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );

      if (video != null) {
        setState(() {
          _selectedVideo = File(video.path);
          _posterFile = null;
        });
        // Автоматически генерируем постер
        await _generatePoster();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора видео: $e')),
        );
      }
    }
  }

  Future<void> _generatePoster() async {
    if (_selectedVideo == null) return;

    try {
      setState(() => _isUploading = true);
      
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: _selectedVideo!.path,
        thumbnailPath: '${_selectedVideo!.path}.thumb',
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 75,
      );

      if (thumbnail != null && mounted) {
        setState(() {
          _posterFile = File(thumbnail);
        });
      }
    } catch (e) {
      debugPrint('Error generating poster: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _createReel() async {
    if (_selectedVideo == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Войдите в аккаунт')),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Получаем данные пользователя
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() ?? {};
      final city = (userData['city'] as String?) ?? '';
      final cityLower = city.toLowerCase();
      final roles = (userData['roles'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final rolesLower = roles.map((r) => (r['id'] as String? ?? '').toLowerCase()).where((r) => r.isNotEmpty).toList();

      // Получаем длительность видео
      final videoDuration = await _getVideoDuration(_selectedVideo!);

      // Загружаем видео
      final reelId = _firestore.collection('reels').doc().id;
      final videoPath = 'uploads/reels/${currentUser.uid}/$reelId/video.mp4';
      final videoRef = _storage.ref().child(videoPath);
      
      final videoUploadTask = videoRef.putFile(_selectedVideo!);
      
      videoUploadTask.snapshotEvents.listen((snapshot) {
        if (mounted) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes * 0.7; // 70% для видео
          });
        }
      });

      final videoSnapshot = await videoUploadTask;
      final videoUrl = await videoSnapshot.ref.getDownloadURL();

      // Загружаем постер
      String? posterUrl;
      if (_posterFile != null) {
        final posterPath = 'uploads/reels/${currentUser.uid}/$reelId/poster.jpg';
        final posterRef = _storage.ref().child(posterPath);
        final posterUploadTask = posterRef.putFile(_posterFile!);
        
        posterUploadTask.snapshotEvents.listen((snapshot) {
          if (mounted) {
            setState(() {
              _uploadProgress = 0.7 + (snapshot.bytesTransferred / snapshot.totalBytes * 0.3); // 30% для постера
            });
          }
        });

        final posterSnapshot = await posterUploadTask;
        posterUrl = await posterSnapshot.ref.getDownloadURL();
      }

      // Получаем имя и фото автора
      final authorName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
      final authorPhotoUrl = userData['photoURL'] as String? ?? currentUser.photoURL ?? '';

      // Сохраняем в Firestore
      await _firestore.collection('reels').doc(reelId).set({
        'id': reelId,
        'authorId': currentUser.uid,
        'authorName': authorName.isNotEmpty ? authorName : (currentUser.displayName ?? 'Пользователь'),
        'authorPhotoUrl': authorPhotoUrl,
        'videoUrl': videoUrl,
        'thumbnailUrl': posterUrl ?? videoUrl, // используем постер или видео как thumbnail
        'durationSec': videoDuration,
        'visibility': 'public',
        'createdAt': FieldValue.serverTimestamp(),
        'cityLower': cityLower,
        'rolesLower': rolesLower,
      });

      debugLog("REEL_PUBLISHED:$reelId");
      
      // Firebase Analytics
      try {
        await FirebaseAnalytics.instance.logEvent(
          name: 'publish_reel',
          parameters: {'reel_id': reelId},
        );
      } catch (e) {
        debugPrint('Analytics error: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Рилс успешно опубликован!')),
        );
        context.pop();
      }
    } catch (e) {
      final errorCode = e is FirebaseException ? e.code : 'unknown';
      debugLog("REEL_PUBLISH_ERR:$errorCode:$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка публикации: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<int> _getVideoDuration(File videoFile) async {
    try {
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      final duration = controller.value.duration.inSeconds;
      await controller.dispose();
      return duration;
    } catch (e) {
      debugPrint('Error getting video duration: $e');
      return 0;
    }
  }
}


