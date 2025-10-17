import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class ChatMediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  /// Выбрать изображение из галереи
  Future<File?> pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image != null ? File(image.path) : null;
    } on Exception {
      // Логирование:'Ошибка при выборе изображения: $e');
      return null;
    }
  }

  /// Сделать фото с камеры
  Future<File?> takePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image != null ? File(image.path) : null;
    } on Exception {
      // Логирование:'Ошибка при съемке фото: $e');
      return null;
    }
  }

  /// Выбрать видео из галереи
  Future<File?> pickVideo() async {
    try {
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      return video != null ? File(video.path) : null;
    } on Exception {
      // Логирование:'Ошибка при выборе видео: $e');
      return null;
    }
  }

  /// Загрузить изображение в Firebase Storage
  Future<String?> uploadImage(File imageFile, String chatId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_${chatId}_image_$timestamp.jpg';
      final ref = _storage.ref().child('chat_images').child(fileName);

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on Exception {
      // Логирование:'Ошибка при загрузке изображения: $e');
      return null;
    }
  }

  /// Загрузить видео в Firebase Storage
  Future<String?> uploadVideo(File videoFile, String chatId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_${chatId}_video_$timestamp.mp4';
      final ref = _storage.ref().child('chat_videos').child(fileName);

      final uploadTask = ref.putFile(videoFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on Exception {
      // Логирование:'Ошибка при загрузке видео: $e');
      return null;
    }
  }

  /// Отправить сообщение с изображением
  Future<bool> sendImageMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required File imageFile,
  }) async {
    try {
      // Загружаем изображение
      final imageUrl = await uploadImage(imageFile, chatId);
      if (imageUrl == null) return false;

      // Сохраняем сообщение в Firestore
      await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': senderId,
        'senderName': senderName,
        'content': '',
        'type': 'image',
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Обновляем последнее сообщение в чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': '📷 Изображение',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } on Exception {
      // Логирование:'Ошибка при отправке изображения: $e');
      return false;
    }
  }

  /// Отправить сообщение с видео
  Future<bool> sendVideoMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required File videoFile,
  }) async {
    try {
      // Загружаем видео
      final videoUrl = await uploadVideo(videoFile, chatId);
      if (videoUrl == null) return false;

      // Создаем превью видео
      final thumbnailUrl = await _generateVideoThumbnail(videoFile);

      // Сохраняем сообщение в Firestore
      await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': senderId,
        'senderName': senderName,
        'content': '',
        'type': 'video',
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Обновляем последнее сообщение в чате
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': '🎥 Видео',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } on Exception {
      // Логирование:'Ошибка при отправке видео: $e');
      return false;
    }
  }

  /// Создать превью видео
  Future<String?> _generateVideoThumbnail(File videoFile) async {
    try {
      final videoPlayerController = VideoPlayerController.file(videoFile);
      await videoPlayerController.initialize();

      // Получаем первый кадр видео
      final thumbnail = videoPlayerController.value;
      await videoPlayerController.dispose();

      // В реальном приложении здесь бы создавался thumbnail
      // Пока возвращаем placeholder
      return 'https://picsum.photos/300?random=${DateTime.now().millisecondsSinceEpoch}';
    } on Exception {
      // Логирование:'Ошибка при создании превью видео: $e');
      return null;
    }
  }

  /// Удалить медиа файл
  Future<bool> deleteMedia(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } on Exception {
      // Логирование:'Ошибка при удалении медиа: $e');
      return false;
    }
  }

  /// Получить размер файла
  Future<int> getFileSize(File file) async => file.length();

  /// Проверить, является ли файл изображением
  bool isImageFile(String fileName) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final extension = fileName.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  /// Проверить, является ли файл видео
  bool isVideoFile(String fileName) {
    final videoExtensions = ['mp4', 'avi', 'mov', 'mkv', 'webm'];
    final extension = fileName.split('.').last.toLowerCase();
    return videoExtensions.contains(extension);
  }
}
