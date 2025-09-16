import 'dart:io';
// import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_message_extended.dart';

/// Сервис для работы с голосовыми сообщениями
class VoiceMessageService {
  static final VoiceMessageService _instance = VoiceMessageService._internal();
  factory VoiceMessageService() => _instance;
  VoiceMessageService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  // final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  String? _currentPlayingMessageId;

  /// Начать запись голосового сообщения
  Future<bool> startRecording() async {
    try {
      // Проверяем разрешения
      if (!await _checkPermissions()) {
        return false;
      }

      // Останавливаем предыдущую запись, если есть
      if (_isRecording) {
        await stopRecording();
      }

      // Получаем путь для временного файла
      final directory = await getTemporaryDirectory();
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = '${directory.path}/$fileName';

      // Начинаем запись
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      return true;
    } catch (e) {
      print('Ошибка начала записи: $e');
      return false;
    }
  }

  /// Остановить запись голосового сообщения
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;
      _currentRecordingPath = null;

      return path;
    } catch (e) {
      print('Ошибка остановки записи: $e');
      return null;
    }
  }

  /// Отменить запись голосового сообщения
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.cancel();
        _isRecording = false;
      }

      // Удаляем временный файл
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      print('Ошибка отмены записи: $e');
    }
  }

  /// Загрузить голосовое сообщение в Firebase Storage
  Future<String?> uploadVoiceMessage(
      String filePath, String chatId, String senderId) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      // Создаём уникальное имя файла
      final fileName =
          'voice_${chatId}_${senderId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      // final ref = _storage.ref().child('voice_messages/$fileName');

      // Загружаем файл
      // final uploadTask = ref.putFile(file);
      // final snapshot = await uploadTask;
      // final downloadUrl = await snapshot.ref.getDownloadURL();
      final downloadUrl =
          'https://example.com/voice_messages/$fileName'; // TODO: Implement actual upload

      // Удаляем временный файл
      await file.delete();

      return downloadUrl;
    } catch (e) {
      print('Ошибка загрузки голосового сообщения: $e');
      return null;
    }
  }

  /// Воспроизвести голосовое сообщение
  Future<bool> playVoiceMessage(String audioUrl, String messageId) async {
    try {
      // Останавливаем предыдущее воспроизведение
      if (_isPlaying) {
        await stopPlaying();
      }

      _currentPlayingMessageId = messageId;
      await _player.play(UrlSource(audioUrl));
      _isPlaying = true;

      // Слушаем завершение воспроизведения
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _currentPlayingMessageId = null;
      });

      return true;
    } catch (e) {
      print('Ошибка воспроизведения: $e');
      return false;
    }
  }

  /// Остановить воспроизведение
  Future<void> stopPlaying() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentPlayingMessageId = null;
    } catch (e) {
      print('Ошибка остановки воспроизведения: $e');
    }
  }

  /// Приостановить воспроизведение
  Future<void> pausePlaying() async {
    try {
      await _player.pause();
    } catch (e) {
      print('Ошибка приостановки воспроизведения: $e');
    }
  }

  /// Возобновить воспроизведение
  Future<void> resumePlaying() async {
    try {
      await _player.resume();
    } catch (e) {
      print('Ошибка возобновления воспроизведения: $e');
    }
  }

  /// Получить длительность аудио файла
  Future<Duration?> getAudioDuration(String audioUrl) async {
    try {
      await _player.setSource(UrlSource(audioUrl));
      return await _player.getDuration();
    } catch (e) {
      print('Ошибка получения длительности: $e');
      return null;
    }
  }

  /// Создать голосовое сообщение в Firestore
  Future<String?> createVoiceMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String audioUrl,
    required int duration,
    String? waveform,
  }) async {
    try {
      final messageRef = _firestore.collection('chat_messages').doc();

      final message = ChatMessageExtended(
        id: messageRef.id,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: '🎤 Голосовое сообщение',
        timestamp: DateTime.now(),
        type: MessageType.voice,
        audioUrl: audioUrl,
        audioDuration: duration,
        audioWaveform: waveform,
      );

      await messageRef.set(message.toMap());
      return messageRef.id;
    } catch (e) {
      print('Ошибка создания голосового сообщения: $e');
      return null;
    }
  }

  /// Генерировать waveform для аудио
  Future<String?> generateWaveform(String audioPath) async {
    try {
      // TODO: Реализовать генерацию waveform
      // Пока возвращаем пустую строку
      return '';
    } catch (e) {
      print('Ошибка генерации waveform: $e');
      return null;
    }
  }

  /// Проверить разрешения
  Future<bool> _checkPermissions() async {
    final microphonePermission = await Permission.microphone.request();
    final storagePermission = await Permission.storage.request();

    return microphonePermission.isGranted && storagePermission.isGranted;
  }

  /// Получить статус записи
  bool get isRecording => _isRecording;

  /// Получить статус воспроизведения
  bool get isPlaying => _isPlaying;

  /// Получить ID текущего воспроизводимого сообщения
  String? get currentPlayingMessageId => _currentPlayingMessageId;

  /// Получить текущий путь записи
  String? get currentRecordingPath => _currentRecordingPath;

  /// Освободить ресурсы
  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}
