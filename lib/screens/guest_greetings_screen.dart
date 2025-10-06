import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/feature_flags.dart';
import '../models/event.dart';
import '../models/guest.dart';
import '../services/guest_service.dart';

/// Экран для загрузки приветствий от гостей
class GuestGreetingsScreen extends ConsumerStatefulWidget {
  const GuestGreetingsScreen({
    super.key,
    required this.event,
    required this.guestId,
    required this.guestName,
  });
  final Event event;
  final String guestId;
  final String guestName;

  @override
  ConsumerState<GuestGreetingsScreen> createState() =>
      _GuestGreetingsScreenState();
}

class _GuestGreetingsScreenState extends ConsumerState<GuestGreetingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final GuestService _guestService = GuestService();
  final TextEditingController _textController = TextEditingController();
  GreetingType _selectedType = GreetingType.text;
  String? _imageUrl;
  String? _videoUrl;
  String? _audioUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.guestModeEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Приветствия'),
        ),
        body: const Center(
          child: Text('Гостевой режим отключен'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Приветствия'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все приветствия', icon: Icon(Icons.message)),
            Tab(text: 'Добавить', icon: Icon(Icons.add)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGreetingsList(),
          _buildAddGreetingForm(),
        ],
      ),
    );
  }

  Widget _buildGreetingsList() => StreamBuilder<List<GuestGreeting>>(
        stream: _guestService.getGuestGreetings(widget.event.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка загрузки приветствий: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final greetings = snapshot.data ?? [];
          if (greetings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Пока нет приветствий',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Будьте первым, кто оставит приветствие!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: greetings.length,
            itemBuilder: (context, index) {
              final greeting = greetings[index];
              return _buildGreetingCard(greeting);
            },
          );
        },
      );

  Widget _buildGreetingCard(GuestGreeting greeting) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: greeting.guestAvatar != null
                        ? NetworkImage(greeting.guestAvatar!)
                        : null,
                    child: greeting.guestAvatar == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting.guestName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDateTime(greeting.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(greeting.type.displayName),
                    backgroundColor:
                        _getTypeColor(greeting.type).withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: _getTypeColor(greeting.type),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildGreetingContent(greeting),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      greeting.likedBy.contains(widget.guestId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: greeting.likedBy.contains(widget.guestId)
                          ? Colors.red
                          : Colors.grey,
                    ),
                    onPressed: () => _toggleLike(greeting),
                  ),
                  Text('${greeting.likesCount}'),
                  const Spacer(),
                  Text(
                    _formatDateTime(greeting.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildGreetingContent(GuestGreeting greeting) {
    switch (greeting.type) {
      case GreetingType.text:
        return Text(
          greeting.text ?? '',
          style: const TextStyle(fontSize: 16),
        );
      case GreetingType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (greeting.text != null && greeting.text!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  greeting.text!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            if (greeting.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  greeting.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child:
                        const Icon(Icons.image, size: 48, color: Colors.grey),
                  ),
                ),
              ),
          ],
        );
      case GreetingType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (greeting.text != null && greeting.text!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  greeting.text!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            if (greeting.videoUrl != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text('Видео приветствие'),
                    ],
                  ),
                ),
              ),
          ],
        );
      case GreetingType.audio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (greeting.text != null && greeting.text!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  greeting.text!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            if (greeting.audioUrl != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.audiotrack, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Аудио приветствие'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () {
                        // TODO(developer): Воспроизвести аудио
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
    }
  }

  Widget _buildAddGreetingForm() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventInfo(),
            const SizedBox(height: 24),
            _buildTypeSelector(),
            const SizedBox(height: 24),
            _buildContentInput(),
            const SizedBox(height: 24),
            _buildMediaUpload(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      );

  Widget _buildEventInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Событие',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.event.title,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.event.date.day}.${widget.event.date.month}.${widget.event.date.year}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildTypeSelector() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Тип приветствия',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: GreetingType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return FilterChip(
                    label: Text(type.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedType = type;
                        });
                      }
                    },
                    selectedColor: Colors.blue.withValues(alpha: 0.2),
                    checkmarkColor: Colors.blue,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );

  Widget _buildContentInput() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Содержание',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Введите ваше приветствие...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildMediaUpload() {
    if (_selectedType == GreetingType.text) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Медиафайл',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildMediaUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaUploadButton() {
    IconData icon;
    String label;
    String? currentUrl;

    switch (_selectedType) {
      case GreetingType.image:
        icon = Icons.image;
        label = 'Загрузить фото';
        currentUrl = _imageUrl;
        break;
      case GreetingType.video:
        icon = Icons.videocam;
        label = 'Загрузить видео';
        currentUrl = _videoUrl;
        break;
      case GreetingType.audio:
        icon = Icons.audiotrack;
        label = 'Загрузить аудио';
        currentUrl = _audioUrl;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (currentUrl != null)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Файл загружен'),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _uploadMedia,
            icon: Icon(icon),
            label: Text(label),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _submitGreeting,
          icon: const Icon(Icons.send),
          label: const Text('Отправить приветствие'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );

  Color _getTypeColor(GreetingType type) {
    switch (type) {
      case GreetingType.text:
        return Colors.blue;
      case GreetingType.image:
        return Colors.green;
      case GreetingType.video:
        return Colors.orange;
      case GreetingType.audio:
        return Colors.purple;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  Future<void> _toggleLike(GuestGreeting greeting) async {
    try {
      await _guestService.toggleGreetingLike(greeting.id, widget.guestId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadMedia() async {
    // TODO(developer): Реализовать загрузку медиафайлов
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Функция загрузки медиафайлов будет добавлена в следующих версиях',
        ),
      ),
    );
  }

  Future<void> _submitGreeting() async {
    if (_textController.text.trim().isEmpty &&
        _imageUrl == null &&
        _videoUrl == null &&
        _audioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите текст или загрузите медиафайл'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _guestService.addGuestGreeting(
        eventId: widget.event.id,
        guestId: widget.guestId,
        guestName: widget.guestName,
        type: _selectedType,
        text: _textController.text.trim().isNotEmpty
            ? _textController.text.trim()
            : null,
        imageUrl: _imageUrl,
        videoUrl: _videoUrl,
        audioUrl: _audioUrl,
      );

      _textController.clear();
      setState(() {
        _imageUrl = null;
        _videoUrl = null;
        _audioUrl = null;
      });

      _tabController.animateTo(0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Приветствие отправлено!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
