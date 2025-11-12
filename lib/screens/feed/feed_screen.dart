import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/debug_log.dart';
import '../../ui/components/gradient_appbar.dart';
import '../../theme/colors.dart';
import '../../services/feedback_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    debugLog('FEED_LOADED');
  }

  Widget _buildStories() {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stories')
          .where('expiresAt', isGreaterThan: FieldValue.serverTimestamp())
          .orderBy('expiresAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const SizedBox(height: 100);
        }
        
        final docs = snap.data!.docs;
        final storiesByAuthor = <String, List<DocumentSnapshot>>{};
        
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final authorId = data['authorId'] as String? ?? '';
          if (authorId.isNotEmpty) {
            storiesByAuthor.putIfAbsent(authorId, () => []).add(doc);
          }
        }

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: storiesByAuthor.length + 1, // +1 для "Ваша сторис"
            itemBuilder: (ctx, i) {
              if (i == 0) {
                // "Ваша сторис" с "+"
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[300],
                            child: currentUser != null
                                ? StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(currentUser.uid)
                                        .snapshots(),
                                    builder: (ctx, userSnap) {
                                      final userData = userSnap.data?.data() as Map<String, dynamic>?;
                                      final photoUrl = userData?['photoUrl'] as String?;
                                      return photoUrl != null
                                          ? CircleAvatar(
                                              radius: 40,
                                              backgroundImage: NetworkImage(photoUrl),
                                            )
                                          : const Icon(Icons.person, size: 40);
                                    },
                                  )
                                : const Icon(Icons.person, size: 40),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Ваша', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }

              final authorId = storiesByAuthor.keys.elementAt(i - 1);
              final authorStories = storiesByAuthor[authorId]!;
              final firstStory = authorStories.first.data() as Map<String, dynamic>;
              final mediaUrl = firstStory['mediaUrl'] as String?;

              return Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: Открыть сторис
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: ClipOval(
                          child: mediaUrl != null
                              ? Image.network(mediaUrl, fit: BoxFit.cover)
                              : Container(color: Colors.grey[300]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(authorId)
                          .get(),
                      builder: (ctx, userSnap) {
                        final userData = userSnap.data?.data() as Map<String, dynamic>?;
                        final firstName = userData?['firstName'] as String? ?? '';
                        return Text(
                          firstName.isNotEmpty ? firstName : 'Пользователь',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPostsList() {
    final posts = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: posts,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text("Постов пока нет"));
        }

        final docs = snap.data!.docs;
        final count = docs.length;
        if (count > 0) {
          debugLog('FEED_LOADED:$count');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;
            final authorId = d['authorId'] as String?;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Автор поста
                    if (authorId != null)
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(authorId)
                            .get(),
                        builder: (ctx, userSnap) {
                          final userData = userSnap.data?.data() as Map<String, dynamic>?;
                          final firstName = userData?['firstName'] ?? '';
                          final lastName = userData?['lastName'] ?? '';
                          final photoUrl = userData?['photoUrl'] as String?;
                          
                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                child: photoUrl == null ? const Icon(Icons.person) : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$firstName $lastName',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                    if (d['text'] != null && (d['text'] as String).isNotEmpty)
                      Text(
                        d['text'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                    if (d['text'] != null && (d['text'] as String).isNotEmpty &&
                        d['mediaUrls'] != null && (d['mediaUrls'] as List).isNotEmpty)
                      const SizedBox(height: 8),
                    if (d['mediaUrls'] != null && (d['mediaUrls'] as List).isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: PageView(
                          children: (d['mediaUrls'] as List)
                              .map((u) => ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      u.toString(),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.error);
                                      },
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () {
                            // TODO: Лайк
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.comment_outlined),
                          onPressed: () {
                            // TODO: Комментарии
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined),
                          onPressed: () {
                            // TODO: Поделиться
                          },
                        ),
                        const Spacer(),
                        Text(
                          d['createdAt'] != null && d['createdAt'] is Timestamp
                              ? _formatDate((d['createdAt'] as Timestamp).toDate())
                              : (d['createdAt']?.toString() ?? ''),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} мин. назад';
      }
      return '${diff.inHours} ч. назад';
    } else if (diff.inDays == 1) {
      return 'Вчера';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: "Лента"),
      body: SafeArea(
        child: Column(
          children: [
            // Stories ниже статус-бара (SafeArea)
            _buildStories(),
            const Divider(height: 1),
            // Лента контента
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  debugLog('FEED_REFRESH');
                  // Обновление происходит через StreamBuilder
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: _buildPostsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
