import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Screen for creating a new post
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  
  List<File> _selectedImages = [];
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать пост'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _publishPost,
            child: Text(
              'Опубликовать',
              style: TextStyle(
                color:
                    _isLoading ? Colors.grey : Theme.of(context).primaryColor,
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
                // User info
                if (currentUser != null) ...[
                  Row(
                    children: [
                      FutureBuilder(
                        future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final userData = snapshot.data!.data() ?? {};
                          final firstName = userData['firstName'] as String? ?? '';
                          final lastName = userData['lastName'] as String? ?? '';
                          final name = '$firstName $lastName'.trim().isEmpty
                              ? (userData['name'] as String? ?? currentUser.displayName ?? 'Пользователь')
                              : '$firstName $lastName'.trim();
                          final photoUrl = userData['photoURL'] as String? ?? currentUser.photoURL;
                          
                          return Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                            : null,
                                child: photoUrl == null || photoUrl.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                      name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Поделитесь чем-то интересным',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Text input (optional)
                TextField(
                  controller: _textController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Что у вас на уме? (необязательно)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),

                const SizedBox(height: 16),

                // Photos preview (до 10)
                if (_selectedImages.isNotEmpty) ...[
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                  Container(
                                width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                                    _selectedImages[index],
                        fit: BoxFit.cover,
                      ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  onPressed: () => _removeImage(index),
                                  icon: const Icon(Icons.close, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectedImages.length >= 10 ? null : _pickImages,
                        icon: const Icon(Icons.image),
                        label: Text('Добавить фото (${_selectedImages.length}/10)'),
                      ),
                    ),
                  ],
                ),
                
                // Upload progress
                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 4),
                  Text(
                    '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],

                const SizedBox(height: 24),

                // Guidelines
                Container(
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
                            'Рекомендации',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Поделитесь интересными событиями и новостями\n'
                        '• Будьте вежливы и уважайте других пользователей\n'
                        '• Можно добавить до 10 фотографий\n'
                        '• Текст поста необязателен',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final remaining = 10 - _selectedImages.length;
      final images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          final newImages = images.take(remaining).map((img) => File(img.path)).toList();
          _selectedImages.addAll(newImages);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора изображений: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _publishPost() async {
    if (_isLoading) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Войдите в аккаунт для публикации постов'),
          backgroundColor: Colors.red,
        ),
      );
      }
      return;
    }

    if (_selectedImages.isEmpty && _textController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Добавьте текст или фото'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
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

      // Загружаем фото
      final postId = _firestore.collection('posts').doc().id;
      final photoUrls = <String>[];
      
      for (int i = 0; i < _selectedImages.length; i++) {
        final photoPath = 'uploads/posts/${currentUser.uid}/$postId/photo_$i.jpg';
        final photoRef = _storage.ref().child(photoPath);
        final uploadTask = photoRef.putFile(_selectedImages[i]);
        
        uploadTask.snapshotEvents.listen((snapshot) {
          if (mounted) {
            setState(() {
              _uploadProgress = ((i + snapshot.bytesTransferred / snapshot.totalBytes) / _selectedImages.length);
            });
          }
        });

        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        photoUrls.add(url);
      }

      // Получаем имя и фото автора
      final authorName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
      final authorPhotoUrl = userData['photoURL'] as String? ?? currentUser.photoURL ?? '';

      // Сохраняем в Firestore
      await _firestore.collection('posts').doc(postId).set({
        'id': postId,
        'authorId': currentUser.uid,
        'authorName': authorName.isNotEmpty ? authorName : (currentUser.displayName ?? 'Пользователь'),
        'authorPhotoUrl': authorPhotoUrl,
        'text': _textController.text.trim(),
        'photos': photoUrls,
        'cityLower': cityLower,
        'rolesLower': rolesLower,
        'visibility': 'public',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugLog("POST_PUBLISHED:$postId");
      
      // Firebase Analytics
      try {
        await FirebaseAnalytics.instance.logEvent(
          name: 'publish_post',
          parameters: {'post_id': postId, 'photos_count': photoUrls.length},
        );
      } catch (e) {
        debugPrint('Analytics error: $e');
      }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Пост успешно опубликован!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
      }
    } catch (e) {
      final errorCode = e is FirebaseException ? e.code : 'unknown';
      debugLog("POST_PUBLISH_ERR:$errorCode:$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка публикации: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }
}
