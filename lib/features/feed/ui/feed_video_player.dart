import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Видеоплеер для постов в ленте
class FeedVideoPlayer extends StatefulWidget {
  const FeedVideoPlayer({
    required this.videoUrl, super.key,
    this.thumbnailUrl,
    this.autoPlay = false,
  });

  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlay;

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

      await _videoController!.initialize();

      if (mounted) {
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: widget.autoPlay,
          showOptions: false,
          showControlsOnInitialize: false,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.blue,
            handleColor: Colors.blue,
            backgroundColor: Colors.grey[300]!,
            bufferedColor: Colors.grey[200]!,
          ),
          placeholder: widget.thumbnailUrl != null
              ? Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.thumbnailUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.play_circle_outline,
                        size: 64, color: Colors.white,),
                  ),
                ),
          autoInitialize: true,
        );

        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized || _chewieController == null) {
      return _buildLoadingWidget();
    }

    return GestureDetector(
      onTap: () {
        if (_chewieController!.isPlaying) {
          _chewieController!.pause();
        } else {
          _chewieController!.play();
        }
      },
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildLoadingWidget() => Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      );

  Widget _buildErrorWidget() => Container(
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 8),
              Text('Ошибка загрузки видео',
                  style: TextStyle(color: Colors.red, fontSize: 14),),
            ],
          ),
        ),
      );
}

/// Видеоплеер с превью для ленты
class FeedVideoPreview extends StatefulWidget {
  const FeedVideoPreview(
      {required this.videoUrl, super.key, this.thumbnailUrl,});

  final String videoUrl;
  final String? thumbnailUrl;

  @override
  State<FeedVideoPreview> createState() => _FeedVideoPreviewState();
}

class _FeedVideoPreviewState extends State<FeedVideoPreview> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          setState(() {
            _isPlaying = !_isPlaying;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Превью изображение или видео
            if (_isPlaying)
              FeedVideoPlayer(
                videoUrl: widget.videoUrl,
                thumbnailUrl: widget.thumbnailUrl,
                autoPlay: true,
              )
            else
              Container(
                decoration: BoxDecoration(
                  image: widget.thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(widget.thumbnailUrl!),
                          fit: BoxFit.cover,)
                      : null,
                  color: widget.thumbnailUrl == null ? Colors.grey[300] : null,
                ),
                child: widget.thumbnailUrl == null
                    ? const Center(
                        child:
                            Icon(Icons.videocam, size: 48, color: Colors.grey),)
                    : null,
              ),

            // Кнопка воспроизведения
            if (!_isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child:
                    const Icon(Icons.play_arrow, size: 48, color: Colors.white),
              ),
          ],
        ),
      );
}
