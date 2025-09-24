import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Upload image from gallery or camera
  Future<String> uploadImage({
    required String chatId,
    required String userId,
    ImageSource source = ImageSource.gallery,
    Function(double)? onProgress,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        throw Exception('Изображение не выбрано');
      }

      return await _uploadFile(
        file: File(image.path),
        chatId: chatId,
        userId: userId,
        fileType: 'image',
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Ошибка загрузки изображения: $e');
    }
  }

  /// Upload video from gallery or camera
  Future<String> uploadVideo({
    required String chatId,
    required String userId,
    ImageSource source = ImageSource.gallery,
    Function(double)? onProgress,
  }) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5), // 5 minutes max
      );

      if (video == null) {
        throw Exception('Видео не выбрано');
      }

      return await _uploadFile(
        file: File(video.path),
        chatId: chatId,
        userId: userId,
        fileType: 'video',
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('Error uploading video: $e');
      throw Exception('Ошибка загрузки видео: $e');
    }
  }

  /// Upload document file
  Future<String> uploadDocument({
    required String chatId,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
        withReadStream: true,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('Файл не выбран');
      }

      final file = result.files.first;
      if (file.path == null) {
        throw Exception('Путь к файлу не найден');
      }

      return await _uploadFile(
        file: File(file.path!),
        chatId: chatId,
        userId: userId,
        fileType: 'document',
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('Error uploading document: $e');
      throw Exception('Ошибка загрузки документа: $e');
    }
  }

  /// Upload file to Firebase Storage
  Future<String> _uploadFile({
    required File file,
    required String chatId,
    required String userId,
    required String fileType,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(fileName);
      final fileNameWithoutExtension = path.basenameWithoutExtension(fileName);
      
      // Create unique file name
      final uniqueFileName = '${fileNameWithoutExtension}_${timestamp}$fileExtension';
      
      // Create storage reference
      final ref = _storage
          .ref()
          .child('chats')
          .child(chatId)
          .child(fileType)
          .child(uniqueFileName);

      // Upload file with progress tracking
      final uploadTask = ref.putFile(file);
      
      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      throw Exception('Ошибка загрузки файла: $e');
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required String chatId,
    required String userId,
    int maxImages = 10,
    Function(double)? onProgress,
  }) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isEmpty) {
        throw Exception('Изображения не выбраны');
      }

      if (images.length > maxImages) {
        throw Exception('Максимум $maxImages изображений');
      }

      final List<String> downloadUrls = [];
      for (int i = 0; i < images.length; i++) {
        final progress = (i / images.length);
        onProgress?.call(progress);
        
        final downloadUrl = await _uploadFile(
          file: File(images[i].path),
          chatId: chatId,
          userId: userId,
          fileType: 'image',
        );
        
        downloadUrls.add(downloadUrl);
      }

      onProgress?.call(1.0);
      return downloadUrls;
    } catch (e) {
      debugPrint('Error uploading multiple images: $e');
      throw Exception('Ошибка загрузки изображений: $e');
    }
  }

  /// Delete file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      debugPrint('File deleted: $fileUrl');
    } catch (e) {
      debugPrint('Error deleting file: $e');
      throw Exception('Ошибка удаления файла: $e');
    }
  }

  /// Get file info from URL
  Future<Map<String, dynamic>> getFileInfo(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final metadata = await ref.getMetadata();
      
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'timeCreated': metadata.timeCreated,
        'updated': metadata.updated,
        'bucket': metadata.bucket,
        'generation': metadata.generation,
        'metageneration': metadata.metageneration,
        'fullPath': metadata.fullPath,
        'downloadUrl': fileUrl,
      };
    } catch (e) {
      debugPrint('Error getting file info: $e');
      return {};
    }
  }

  /// Check if file type is supported
  bool isSupportedFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    const supportedExtensions = [
      '.jpg', '.jpeg', '.png', '.gif', '.webp', // Images
      '.mp4', '.mov', '.avi', '.mkv', '.webm', // Videos
      '.pdf', '.doc', '.docx', '.txt', '.rtf', // Documents
      '.xls', '.xlsx', '.ppt', '.pptx', // Office
      '.zip', '.rar', '.7z', // Archives
    ];
    
    return supportedExtensions.contains(extension);
  }

  /// Get file type category
  String getFileTypeCategory(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
      return 'image';
    } else if (['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(extension)) {
      return 'video';
    } else if (['.pdf', '.doc', '.docx', '.txt', '.rtf'].contains(extension)) {
      return 'document';
    } else if (['.xls', '.xlsx', '.ppt', '.pptx'].contains(extension)) {
      return 'office';
    } else if (['.zip', '.rar', '.7z'].contains(extension)) {
      return 'archive';
    } else {
      return 'other';
    }
  }

  /// Get file size in human readable format
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get maximum file size for different types
  int getMaxFileSize(String fileType) {
    switch (fileType) {
      case 'image':
        return 10 * 1024 * 1024; // 10 MB
      case 'video':
        return 100 * 1024 * 1024; // 100 MB
      case 'document':
        return 50 * 1024 * 1024; // 50 MB
      default:
        return 25 * 1024 * 1024; // 25 MB
    }
  }

  /// Check if file size is within limits
  bool isFileSizeValid(File file, String fileType) {
    final fileSize = file.lengthSync();
    final maxSize = getMaxFileSize(fileType);
    return fileSize <= maxSize;
  }
}
