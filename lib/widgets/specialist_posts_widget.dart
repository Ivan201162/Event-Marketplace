import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/specialist_post.dart';
import '../services/specialist_content_service.dart';
import '../providers/specialist_providers.dart';

/// Виджет постов специалиста
class SpecialistPostsWidget extends ConsumerStatefulWidget {
  const SpecialistPostsWidget({
    super.key,
    required this.specialistId,
    this.isOwnProfile = false,
    this.onPostTap,
    this.onLikePost,
    this.onCommentPost,
  });

  final String specialistId;
  final bool isOwnProfile;
  final Function(SpecialistPost)? onPostTap;
  final Function(String)? onLikePost;
  final Function(String)? onCommentPost;

  @override
  ConsumerState<SpecialistPostsWidget> createState() => _SpecialistPostsWidgetState();
}

class _SpecialistPostsWidgetState extends ConsumerState<SpecialistPostsWidget> {
  final ScrollController _scrollController = ScrollController();
  List<SpecialistPost> _posts = [];
  bool _isLoading = false;
  String? _lastPostId;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await ref.read(specialistContentServiceProvider).getSpecialistPosts(
        specialistId: widget.specialistId,
        limit: 20,
      );

      setState(() {
        _posts = posts;
        _lastPostId = posts.isNotEmpty ? posts.last.id : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || _lastPostId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await ref.read(specialistContentServiceProvider).getSpecialistPosts(
        specialistId: widget.specialistId,
        limit: 20,
        lastPostId: _lastPostId,
      );

      setState(() {
        _posts.addAll(posts);
        _lastPostId = posts.isNotEmpty ? posts.last.id : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_posts.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final post = _posts[index];
          return _buildPostItem(context, post);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.post_add,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Пока нет постов',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            widget.isOwnProfile 
                ? 'Создайте свой первый пост'
                : 'Специалист еще не публиковал посты',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.isOwnProfile) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => widget.onPostTap?.call(SpecialistPost(
                id: '',
                specialistId: widget.specialistId,
                contentType: PostContentType.text,
                content: '',
                createdAt: DateTime.now(),
              )),
              icon: const Icon(Icons.add),
              label: const Text('Создать пост'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, SpecialistPost post) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок поста
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(
                _getPostIcon(post.contentType),
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              _getPostTitle(post.contentType),
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(post.timeAgo),
            trailing: widget.isOwnProfile
                ? PopupMenuButton<String>(
                    onSelected: (value) => _handlePostAction(value, post),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Редактировать'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'pin',
                        child: ListTile(
                          leading: Icon(Icons.push_pin),
                          title: Text(post.isPinned ? 'Открепить' : 'Закрепить'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Удалить', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          
          // Контент поста
          if (post.content.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Медиа контент
          if (post.hasMedia) ...[
            _buildMediaContent(context, post),
            const SizedBox(height: 12),
          ],
          
          // Хештеги
          if (post.hashtags.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: post.hashtags.map((hashtag) => 
                  GestureDetector(
                    onTap: () => _searchByHashtag(hashtag),
                    child: Text(
                      '#$hashtag',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Действия
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => widget.onLikePost?.call(post.id),
                  icon: Icon(
                    Icons.favorite_border,
                    color: theme.colorScheme.outline,
                  ),
                ),
                Text('${post.likesCount}'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => widget.onCommentPost?.call(post.id),
                  icon: Icon(
                    Icons.comment_outlined,
                    color: theme.colorScheme.outline,
                  ),
                ),
                Text('${post.commentsCount}'),
                const Spacer(),
                IconButton(
                  onPressed: () => _sharePost(post),
                  icon: Icon(
                    Icons.share,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context, SpecialistPost post) {
    final theme = Theme.of(context);
    
    if (post.contentType == PostContentType.carousel && post.mediaUrls.length > 1) {
      return SizedBox(
        height: 200,
        child: PageView.builder(
          itemCount: post.mediaUrls.length,
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: post.mediaUrls[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: theme.colorScheme.surface,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: theme.colorScheme.surface,
                child: const Center(child: Icon(Icons.error)),
              ),
            );
          },
        ),
      );
    } else if (post.mediaUrls.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: post.mediaUrls.first,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: theme.colorScheme.surface,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: theme.colorScheme.surface,
          child: const Center(child: Icon(Icons.error)),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  IconData _getPostIcon(PostContentType type) {
    switch (type) {
      case PostContentType.text:
        return Icons.text_fields;
      case PostContentType.image:
        return Icons.image;
      case PostContentType.video:
        return Icons.videocam;
      case PostContentType.carousel:
        return Icons.photo_library;
    }
  }

  String _getPostTitle(PostContentType type) {
    switch (type) {
      case PostContentType.text:
        return 'Текстовый пост';
      case PostContentType.image:
        return 'Фото';
      case PostContentType.video:
        return 'Видео';
      case PostContentType.carousel:
        return 'Карусель';
    }
  }

  void _handlePostAction(String action, SpecialistPost post) {
    switch (action) {
      case 'edit':
        // Редактирование поста
        break;
      case 'pin':
        // Закрепление/открепление поста
        break;
      case 'delete':
        _deletePost(post);
        break;
    }
  }

  void _deletePost(SpecialistPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить пост'),
        content: const Text('Вы уверены, что хотите удалить этот пост?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(specialistContentServiceProvider).deletePost(post.id);
              _loadPosts();
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _searchByHashtag(String hashtag) {
    // Поиск по хештегу
  }

  void _sharePost(SpecialistPost post) {
    // Шаринг поста
  }
}
