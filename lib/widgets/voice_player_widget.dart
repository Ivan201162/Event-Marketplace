import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/voice_message_service.dart';
import '../models/chat_message_extended.dart';

/// Виджет для воспроизведения голосовых сообщений
class VoicePlayerWidget extends ConsumerStatefulWidget {
  final ChatMessageExtended message;
  final bool isOwnMessage;

  const VoicePlayerWidget({
    super.key,
    required this.message,
    this.isOwnMessage = false,
  });

  @override
  ConsumerState<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends ConsumerState<VoicePlayerWidget>
    with TickerProviderStateMixin {
  final VoiceMessageService _voiceService = VoiceMessageService();
  late AnimationController _waveformController;
  late Animation<double> _waveformAnimation;

  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _waveformAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveformController,
      curve: Curves.easeInOut,
    ));

    _totalDuration = Duration(seconds: widget.message.audioDuration ?? 0);
  }

  @override
  void dispose() {
    _waveformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: widget.isOwnMessage
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isOwnMessage
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок голосового сообщения
          Row(
            children: [
              Icon(
                Icons.mic,
                size: 16,
                color: widget.isOwnMessage
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Голосовое сообщение',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.isOwnMessage
                      ? Theme.of(context).primaryColor
                      : Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Контролы воспроизведения
          Row(
            children: [
              // Кнопка воспроизведения/паузы
              GestureDetector(
                onTap: _togglePlayback,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.isOwnMessage
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Waveform и прогресс
              Expanded(
                child: Column(
                  children: [
                    _buildWaveform(),
                    const SizedBox(height: 4),
                    _buildProgressBar(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 30,
      child: AnimatedBuilder(
        animation: _waveformAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: WaveformPainter(
              progress: _waveformAnimation.value,
              isPlaying: _isPlaying,
              isOwnMessage: widget.isOwnMessage,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(
        widget.isOwnMessage
            ? Theme.of(context).primaryColor
            : Colors.grey[600]!,
      ),
    );
  }

  void _togglePlayback() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isPlaying) {
        await _voiceService.pausePlaying();
        setState(() {
          _isPlaying = false;
        });
        _waveformController.stop();
      } else {
        final success = await _voiceService.playVoiceMessage(
          widget.message.audioUrl!,
          widget.message.id,
        );

        if (success) {
          setState(() {
            _isPlaying = true;
          });
          _waveformController.repeat();
          _startPositionTracking();
        } else {
          _showErrorSnackBar('Не удалось воспроизвести аудио');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка воспроизведения: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startPositionTracking() {
    Future.doWhile(() async {
      if (_isPlaying) {
        await Future.delayed(const Duration(milliseconds: 100));
        // TODO: Получать реальную позицию воспроизведения
        setState(() {
          _currentPosition = Duration(
            milliseconds: _currentPosition.inMilliseconds + 100,
          );
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

/// Кастомный painter для отрисовки waveform
class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final bool isOwnMessage;

  WaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.isOwnMessage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isOwnMessage
          ? Colors.blue.withOpacity(0.7)
          : Colors.grey.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = isOwnMessage ? Colors.blue : Colors.grey[600]!
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Генерируем случайные высоты для waveform
    final random = DateTime.now().millisecondsSinceEpoch;
    final barCount = (size.width / 4).floor();
    final activeBarCount = (barCount * progress).floor();

    for (int i = 0; i < barCount; i++) {
      final x = i * 4.0 + 2.0;
      final height = (20 + (random + i) % 20).toDouble();
      final y = (size.height - height) / 2;

      final currentPaint = i < activeBarCount ? activePaint : paint;

      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + height),
        currentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.isOwnMessage != isOwnMessage;
  }
}
