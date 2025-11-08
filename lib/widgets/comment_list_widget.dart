import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Универсальный виджет списка комментариев
class CommentListWidget extends StatelessWidget {
  const CommentListWidget({
    required this.parentType,
    required this.parentId,
    super.key,
  });

  final String parentType; // 'posts', 'reels', 'stories', 'ideas'
  final String parentId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comments')
          .doc(parentType)
          .collection(parentId)
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugLog('COMMENT_ERR:load:${snapshot.error}');
          return Center(
            child: Text('Ошибка загрузки: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Пока нет комментариев',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final comments = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            final data = comment.data() as Map<String, dynamic>;
            return _CommentItem(
              commentId: comment.id,
              authorId: data['authorId'] ?? '',
              authorName: data['authorName'] ?? 'Пользователь',
              authorPhotoUrl: data['authorPhotoUrl'],
              text: data['text'] ?? '',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              parentType: parentType,
              parentId: parentId,
            );
          },
        );
      },
    );
  }
}

class _CommentItem extends StatelessWidget {
  const _CommentItem({
    required this.commentId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
    required this.parentType,
    required this.parentId,
  });

  final String commentId;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;
  final String parentType;
  final String parentId;

  Future<void> _deleteComment(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != authorId) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить комментарий?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('comments')
            .doc(parentType)
            .collection(parentId)
            .doc(commentId)
            .delete();
        debugLog('COMMENT_DELETED:$parentType:$parentId:$commentId');
      } catch (e) {
        debugLog('COMMENT_ERR:delete:$e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnComment = currentUser?.uid == authorId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: authorPhotoUrl != null
                ? NetworkImage(authorPhotoUrl!)
                : null,
            child: authorPhotoUrl == null
                ? Text(authorName.isNotEmpty ? authorName[0].toUpperCase() : '?')
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
                      authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(createdAt),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildCommentText(text),
              ],
            ),
          ),
          if (isOwnComment)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _deleteComment(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  /// Построить текст комментария с поддержкой @упоминаний
  Widget _buildCommentText(String text) {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(text);
    
    if (matches.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 14));
    }
    
    final spans = <TextSpan>[];
    int lastEnd = 0;
    
    for (final match in matches) {
      // Текст до упоминания
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: const TextStyle(fontSize: 14),
        ));
      }
      
      // Упоминание
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ));
      
      lastEnd = match.end;
    }
    
    // Текст после последнего упоминания
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: const TextStyle(fontSize: 14),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

