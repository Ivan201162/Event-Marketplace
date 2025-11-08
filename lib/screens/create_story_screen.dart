import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();

  File? _selectedFile;
  bool _isVideo = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Создать сторис'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_selectedFile != null)
              TextButton(
                onPressed: _isLoading ? null : _createStory,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Опубликовать'),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Выбор типа контента
              // Выбор файла
            _buildFileSelector(),

              const SizedBox(height: 24),

              // Предварительный просмотр
              if (_selectedFile != null) _buildPreview(),

              const SizedBox(height: 24),

              // Информация о сторис
              _buildStoryInfo(),
            ],
          ),
        ),
      );


  Widget _buildFileSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Выберите файл',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _selectedFile == null
                ? InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(12),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Нажмите для выбора фото или видео',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: !_isVideo
                            ? Image.file(
                                _selectedFile!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: double.infinity,
                                height: double.infinity,
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
                              _selectedFile = null;
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Фото'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library),
                  label: const Text('Видео'),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildPreview() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Предварительный просмотр',
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
              child: !_isVideo
                  ? Image.file(_selectedFile!, fit: BoxFit.cover)
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
                      ),
                    ),
            ),
          ),
        ],
      );


  Widget _buildStoryInfo() => Container(
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
              '• Фото или видео до 15 секунд\n'
              '• Время жизни: 24 часа\n'
              '• Сторис будет доступна всем пользователям',
              style: TextStyle(color: Colors.blue[600], fontSize: 14),
            ),
          ],
        ),
      );


  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _isVideo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора фото: $e')),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 15),
      );

      if (video != null) {
        setState(() {
          _selectedFile = File(video.path);
          _isVideo = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора видео: $e')),
        );
      }
    }
  }

  Future<void> _createStory() async {
    if (_selectedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите файл для сторис')),
        );
      }
      return;
    }

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
      _isLoading = true;
    });

    try {
      // Загружаем файл
      final storyId = _firestore.collection('stories').doc().id;
      final fileExtension = _isVideo ? 'mp4' : 'jpg';
      final filePath = 'uploads/stories/${currentUser.uid}/$storyId/file.$fileExtension';
      final fileRef = _storage.ref().child(filePath);
      
      final uploadTask = fileRef.putFile(_selectedFile!);
      final snapshot = await uploadTask;
      final mediaUrl = await snapshot.ref.getDownloadURL();

      // Вычисляем expiresAt (24 часа)
      final expiresAt = DateTime.now().add(const Duration(hours: 24));

      // Сохраняем в Firestore
      await _firestore.collection('stories').doc(storyId).set({
        'authorId': currentUser.uid,
        'mediaUrl': mediaUrl,
        'mediaType': _isVideo ? 'video' : 'image',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      debugLog("STORY_PUBLISHED:$storyId");
      
      // Firebase Analytics
      try {
        await FirebaseAnalytics.instance.logEvent(
          name: 'publish_story',
          parameters: {'story_id': storyId},
        );
      } catch (e) {
        debugPrint('Analytics error: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сторис успешно создана')),
        );
        context.pop();
      }
    } catch (e) {
      final errorCode = e is FirebaseException ? e.code : 'unknown';
      debugLog("STORY_PUBLISH_ERR:$errorCode:$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания сторис: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
