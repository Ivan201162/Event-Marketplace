import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/voice_message_service.dart';
import '../models/chat_message_extended.dart';

/// Виджет для записи голосовых сообщений
class VoiceRecorderWidget extends ConsumerStatefulWidget {
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final Function(ChatMessageExtended) onVoiceMessageSent;

  const VoiceRecorderWidget({
    super.key,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.onVoiceMessageSent,
  });

  @override
  ConsumerState<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends ConsumerState<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  final VoiceMessageService _voiceService = VoiceMessageService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _isRecording = false;
  bool _isUploading = false;
  Duration _recordingDuration = Duration.zero;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording) ...[
            _buildRecordingUI(),
          ] else if (_isUploading) ...[
            _buildUploadingUI(),
          ] else ...[
            _buildReadyToRecordUI(),
          ],
        ],
      ),
    );
  }

  Widget _buildReadyToRecordUI() {
    return Column(
      children: [
        const Icon(
          Icons.mic,
          size: 48,
          color: Colors.red,
        ),
        const SizedBox(height: 16),
        const Text(
          'Нажмите и удерживайте для записи',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTapDown: (_) => _startRecording(),
          onTapUp: (_) => _stopRecording(),
          onTapCancel: () => _cancelRecording(),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.mic,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(_pulseAnimation.value * 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stop,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          _formatDuration(_recordingDuration),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Запись...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.cancel,
              label: 'Отмена',
              color: Colors.grey,
              onTap: _cancelRecording,
            ),
            _buildActionButton(
              icon: Icons.send,
              label: 'Отправить',
              color: Colors.green,
              onTap: _sendVoiceMessage,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadingUI() {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        const Text(
          'Отправка голосового сообщения...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startRecording() async {
    final success = await _voiceService.startRecording();
    if (success) {
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      
      _animationController.repeat(reverse: true);
      _startTimer();
    } else {
      _showErrorSnackBar('Не удалось начать запись');
    }
  }

  void _stopRecording() async {
    final path = await _voiceService.stopRecording();
    if (path != null) {
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });
      
      _animationController.stop();
      _animationController.reset();
    }
  }

  void _cancelRecording() async {
    await _voiceService.cancelRecording();
    setState(() {
      _isRecording = false;
      _recordingPath = null;
      _recordingDuration = Duration.zero;
    });
    
    _animationController.stop();
    _animationController.reset();
  }

  void _sendVoiceMessage() async {
    if (_recordingPath == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Загружаем аудио файл
      final audioUrl = await _voiceService.uploadVoiceMessage(
        _recordingPath!,
        widget.chatId,
        widget.senderId,
      );

      if (audioUrl != null) {
        // Получаем длительность
        final duration = await _voiceService.getAudioDuration(audioUrl);
        final durationSeconds = duration?.inSeconds ?? 0;

        // Создаём сообщение
        final messageId = await _voiceService.createVoiceMessage(
          chatId: widget.chatId,
          senderId: widget.senderId,
          senderName: widget.senderName,
          senderAvatar: widget.senderAvatar,
          audioUrl: audioUrl,
          duration: durationSeconds,
        );

        if (messageId != null) {
          // Создаём объект сообщения для callback
          final message = ChatMessageExtended(
            id: messageId,
            chatId: widget.chatId,
            senderId: widget.senderId,
            senderName: widget.senderName,
            senderAvatar: widget.senderAvatar,
            content: '🎤 Голосовое сообщение',
            timestamp: DateTime.now(),
            type: MessageType.voice,
            audioUrl: audioUrl,
            audioDuration: durationSeconds,
          );

          widget.onVoiceMessageSent(message);
          
          setState(() {
            _isUploading = false;
            _recordingPath = null;
            _recordingDuration = Duration.zero;
          });
        } else {
          _showErrorSnackBar('Не удалось создать сообщение');
        }
      } else {
        _showErrorSnackBar('Не удалось загрузить аудио');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка отправки: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      if (_isRecording) {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
        });
        return true;
      }
      return false;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
