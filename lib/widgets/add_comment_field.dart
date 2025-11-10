import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Поле для добавления комментария
class AddCommentField extends StatefulWidget {
  const AddCommentField({
    required this.parentType,
    required this.parentId,
    super.key,
  });

  final String parentType; // 'posts', 'reels', 'stories', 'ideas'
  final String parentId;

  @override
  State<AddCommentField> createState() => _AddCommentFieldState();
}

class _AddCommentFieldState extends State<AddCommentField> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Парсинг @упоминаний из текста
  List<String> _parseMentions(String text) {
    final mentions = <String>[];
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(text);
    for (final match in matches) {
      final username = match.group(1);
      if (username != null && !mentions.contains(username)) {
        mentions.add(username);
      }
    }
    return mentions;
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Войдите, чтобы комментировать')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Получаем данные пользователя
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data();
      final authorName = userData?['firstName'] != null && userData?['lastName'] != null
          ? '${userData!['firstName']} ${userData['lastName']}'
          : currentUser.displayName ?? 'Пользователь';
      final authorPhotoUrl = userData?['photoUrl'] ?? currentUser.photoURL;

      // Парсим @упоминания
      final mentions = _parseMentions(text);
      
      // Используем подколлекцию: {contentType}/{contentId}/comments
      final commentRef = FirebaseFirestore.instance
          .collection(widget.parentType) // posts, reels, stories, ideas
          .doc(widget.parentId)
          .collection('comments')
          .doc();

      await commentRef.set({
        'id': commentRef.id,
        'authorId': currentUser.uid,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'text': text,
        'mentions': mentions,
        'parentId': null, // корневой комментарий
        'likesCount': 0,
        'likes': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugLog('COMMENT_ADD:$widget.parentType:$widget.parentId:${commentRef.id}');
      if (widget.parentType == 'posts') {
        debugLog('POST_COMMENT:${widget.parentId}:${commentRef.id}');
      }
      _controller.clear();
    } catch (e) {
      debugLog('COMMENT_ERR:${e.toString()}:$widget.parentType:$widget.parentId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Написать комментарий...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: _controller.text.trim().isEmpty || _isSubmitting
                ? null
                : _submitComment,
          ),
        ],
      ),
    );
  }
}

