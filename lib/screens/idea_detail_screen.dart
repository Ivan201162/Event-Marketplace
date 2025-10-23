import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_idea.dart';
import '../providers/auth_providers.dart';
import '../services/event_ideas_service.dart';
import 'share_idea_screen.dart';
import 'video_reels_viewer.dart';

class IdeaDetailScreen extends ConsumerStatefulWidget {
  const IdeaDetailScreen({super.key, required this.idea});
  final EventIdea idea;

  @override
  ConsumerState<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends ConsumerState<IdeaDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final EventIdeasService _ideasService = EventIdeasService();
  final TextEditingController _commentController = TextEditingController();
  bool _isCommenting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Идея'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareIdea)
        ],
      ),
      body: Column(
        children: [
          // Медиа контент
          _buildMediaContent(),

          // Информация об идее
          _buildIdeaInfo(),

          // Табы (комментарии и детали)
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Комментарии'),
              Tab(text: 'Детали'),
            ],
          ),

          // Содержимое табов
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildCommentsTab(), _buildDetailsTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() => Container(
        height: 300,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            if (widget.idea.mediaUrl?.isNotEmpty ?? false)
              widget.idea.isVideo ?? false
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.idea.mediaUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.video_library,
                                size: 80, color: Colors.white),
                          ),
                        ),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoReelsViewer(
                                      initialIdea: widget.idea),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow,
                                  color: Colors.white, size: 60),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Image.network(
                      widget.idea.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.image,
                            size: 80, color: Colors.white),
                      ),
                    )
            else
              Container(
                color: Colors.grey[800],
                child: Icon(
                  widget.idea.isVideo ?? false
                      ? Icons.video_library
                      : Icons.image,
                  size: 80,
                  color: Colors.white,
                ),
              ),

            // Кнопки действий
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                children: [
                  _buildActionButton(
                    icon: Icons.favorite_border,
                    color: Colors.white,
                    count: widget.idea.likesCount ?? 0,
                    onTap: _toggleLike,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.comment,
                    color: Colors.white,
                    count: widget.idea.commentsCount ?? 0,
                    onTap: () {
                      _tabController.animateTo(0);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.bookmark_border,
                    color: Colors.white,
                    count: 0,
                    onTap: _toggleSave,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    icon: Icons.share,
                    color: Colors.white,
                    count: widget.idea.sharesCount ?? 0,
                    onTap: _shareIdea,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
              color: Colors.black54, shape: BoxShape.circle),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );

  Widget _buildIdeaInfo() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(widget.idea.title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Автор
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: widget.idea.authorAvatar != null
                      ? NetworkImage(widget.idea.authorAvatar!)
                      : null,
                  child: widget.idea.authorAvatar == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.idea.authorName ?? 'Неизвестный автор',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  _formatDate(widget.idea.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Описание
            if (widget.idea.description.isNotEmpty) ...[
              Text(widget.idea.description,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
            ],

            // Теги
            if (widget.idea.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.idea.tags
                    .map(
                      (tag) => Chip(
                        label: Text('#$tag'),
                        backgroundColor: Colors.grey[200],
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Категория
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.idea.category ?? 'Без категории',
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

  Widget _buildCommentsTab() => FutureBuilder<List<IdeaComment>>(
        future: _ideasService.getIdeaComments(widget.idea.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Ошибка загрузки комментариев: ${snapshot.error}'));
          }

          final comments = snapshot.data ?? [];

          return Column(
            children: [
              // Поле для добавления комментария
              _buildCommentInput(),

              // Список комментариев
              Expanded(
                child: comments.isEmpty
                    ? const Center(child: Text('Пока нет комментариев'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return _buildCommentItem(comment);
                        },
                      ),
              ),
            ],
          );
        },
      );

  Widget _buildCommentInput() {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      data: (user) {
        if (user == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Text('Войдите в аккаунт, чтобы комментировать'),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    user.avatar != null ? NetworkImage(user.avatar!) : null,
                child: user.avatar == null
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Добавить комментарий...',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isCommenting ? null : () => _addComment(user),
                icon: _isCommenting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCommentItem(IdeaComment comment) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: comment.authorAvatar != null
                  ? NetworkImage(comment.authorAvatar!)
                  : null,
              child: comment.authorAvatar == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.authorName ?? 'Неизвестный',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(comment.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.text, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleCommentLike(comment),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_border,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(comment.likes.toString(),
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildDetailsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Местоположение
            if (widget.idea.location != null) ...[
              _buildDetailItem(
                icon: Icons.location_on,
                title: 'Местоположение',
                value: widget.idea.location!,
              ),
              const SizedBox(height: 16),
            ],

            // Цена
            if (widget.idea.price != null) ...[
              _buildDetailItem(
                icon: Icons.attach_money,
                title: 'Цена',
                value:
                    '${widget.idea.price!.toStringAsFixed(0)} ${widget.idea.priceCurrency ?? 'RUB'}',
              ),
              const SizedBox(height: 16),
            ],

            // Длительность
            if (widget.idea.duration != null) ...[
              _buildDetailItem(
                icon: Icons.access_time,
                title: 'Длительность',
                value: '${widget.idea.duration} минут',
              ),
              const SizedBox(height: 16),
            ],

            // Навыки
            if (widget.idea.requiredSkills?.isNotEmpty ?? false) ...[
              const Text(
                'Требуемые навыки:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.idea.requiredSkills!
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                        backgroundColor: Colors.blue[100],
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Статистика
            _buildDetailItem(
              icon: Icons.favorite,
              title: 'Лайки',
              value: (widget.idea.likesCount ?? 0).toString(),
            ),
            const SizedBox(height: 8),
            _buildDetailItem(
              icon: Icons.comment,
              title: 'Комментарии',
              value: (widget.idea.commentsCount ?? 0).toString(),
            ),
            const SizedBox(height: 8),
            _buildDetailItem(
              icon: Icons.bookmark,
              title: 'Сохранения',
              value: (widget.idea.savesCount ?? 0).toString(),
            ),
            const SizedBox(height: 8),
            _buildDetailItem(
              icon: Icons.share,
              title: 'Репосты',
              value: (widget.idea.sharesCount ?? 0).toString(),
            ),
          ],
        ),
      );

  Widget _buildDetailItem(
          {required IconData icon,
          required String title,
          required String value}) =>
      Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      );

  Future<void> _toggleLike() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    // await _ideasService.toggleLike(widget.idea.id, currentUser.id);
  }

  Future<void> _toggleSave() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    // await _ideasService.toggleSave(widget.idea.id, currentUser.id);
  }

  Future<void> _shareIdea() async {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ShareIdeaScreen(idea: widget.idea)),
    );
  }

  Future<void> _addComment(user) async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isCommenting = true;
    });

    try {
      await _ideasService.addComment(
        ideaId: widget.idea.id,
        userId: user.uid,
        userName: user.name ?? 'Пользователь',
        userAvatar: user.avatar,
        content: _commentController.text.trim(),
      );

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('Ошибка добавления комментария: $e')));
    } finally {
      setState(() {
        _isCommenting = false;
      });
    }
  }

  Future<void> _toggleCommentLike(IdeaComment comment) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    // await _ideasService.toggleCommentLike(comment.id, currentUser.id);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'только что';
    }
  }
}
