import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_marketplace_app/models/post.dart';
import 'package:flutter/material.dart';

/// Widget for displaying a post card
class PostCard extends StatelessWidget {

  const PostCard({
    required this.post, super.key,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.showActions = true,
  });
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author info
              _buildAuthorInfo(context),
              const SizedBox(height: 12),

              // Post content
              if (post.text.isNotEmpty) ...[
                Text(post.text, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
              ],

              // Media content
              if (post.hasMedia) ...[
                _buildMediaContent(context),
                const SizedBox(height: 12),
              ],

              // Tags
              if (post.tags.isNotEmpty) ...[
                _buildTags(),
                const SizedBox(height: 12),
              ],

              // Location
              if (post.location != null && post.location!.isNotEmpty) ...[
                _buildLocation(),
                const SizedBox(height: 12),
              ],

              // Actions
              if (showActions) ...[
                _buildActions(context),
                const SizedBox(height: 8),
              ],

              // Stats
              _buildStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[200],
          backgroundImage: post.authorAvatarUrl != null
              ? CachedNetworkImageProvider(post.authorAvatarUrl!)
              : null,
          child: post.authorAvatarUrl == null
              ? Icon(Icons.person, size: 20, color: Colors.grey[600])
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName ?? 'Неизвестный пользователь',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(post.timeAgo,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),),
            ],
          ),
        ),
        if (post.isPinned)
          Icon(Icons.push_pin, color: Colors.blue[600], size: 16),
      ],
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    if (post.mediaType == MediaType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: post.mediaUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          placeholder: (context, url) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: Icon(Icons.error, color: Colors.grey)),
          ),
        ),
      );
    } else if (post.mediaType == MediaType.video) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
            color: Colors.grey[200], borderRadius: BorderRadius.circular(8),),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_filled,
                      size: 60, color: Colors.grey[600],),
                  const SizedBox(height: 8),
                  Text('Видео',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('🎥',
                    style: TextStyle(color: Colors.white, fontSize: 12),),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: post.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
                color: Colors.blue[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(post.location!,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        _buildActionButton(
          icon: post.likesCount > 0 ? Icons.favorite : Icons.favorite_border,
          color: post.likesCount > 0 ? Colors.red : Colors.grey[600],
          label: post.likesCount > 0 ? '${post.likesCount}' : 'Лайк',
          onTap: onLike,
        ),
        const SizedBox(width: 24),
        _buildActionButton(
          icon: Icons.comment_outlined,
          color: Colors.grey[600],
          label:
              post.commentsCount > 0 ? '${post.commentsCount}' : 'Комментарий',
          onTap: onComment,
        ),
        const SizedBox(width: 24),
        _buildActionButton(
          icon: Icons.share_outlined,
          color: Colors.grey[600],
          label: 'Поделиться',
          onTap: onShare,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color? color,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w500,),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        if (post.likesCount > 0) ...[
          Text(
            '${post.likesCount} ${_getLikesText(post.likesCount)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(width: 16),
        ],
        if (post.commentsCount > 0) ...[
          Text(
            '${post.commentsCount} ${_getCommentsText(post.commentsCount)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ],
    );
  }

  String _getLikesText(int count) {
    if (count == 1) return 'лайк';
    if (count >= 2 && count <= 4) return 'лайка';
    return 'лайков';
  }

  String _getCommentsText(int count) {
    if (count == 1) return 'комментарий';
    if (count >= 2 && count <= 4) return 'комментария';
    return 'комментариев';
  }
}
