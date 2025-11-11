import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/debug_log.dart';
import 'chat_screen_enhanced.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Необходима авторизация')));
    }

    final chats = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Чаты"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chats,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final chatsList = snap.data!.docs;
          if (chatsList.isEmpty) {
            return const Center(child: Text("Нет сообщений"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: chatsList.length,
            itemBuilder: (ctx, i) {
              final doc = chatsList[i];
              final d = doc.data() as Map<String, dynamic>;
              final chatId = doc.id;
              final participants = (d['participants'] as List?)?.cast<String>() ?? [];
              final otherUserId = participants.firstWhere((p) => p != uid, orElse: () => '');
              final lastMessage = d['lastMessage'] as String? ?? '';
              final updatedAt = d['updatedAt'] as Timestamp?;
              final unreadCount = (d['unreadCount'] as Map<String, dynamic>?)?[uid] as int? ?? 0;

              return FutureBuilder<DocumentSnapshot>(
                future: otherUserId.isNotEmpty
                    ? FirebaseFirestore.instance.collection('users').doc(otherUserId).get()
                    : Future.value(null),
                builder: (ctx, userSnap) {
                  final userData = userSnap.data?.data() as Map<String, dynamic>?;
                  final firstName = userData?['firstName'] ?? '';
                  final lastName = userData?['lastName'] ?? '';
                  final photoUrl = userData?['photoUrl'] as String?;
                  final name = '$firstName $lastName'.trim();
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(name.isNotEmpty ? name : 'Пользователь'),
                      subtitle: Text(
                        lastMessage.isNotEmpty ? lastMessage : 'Нет сообщений',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (updatedAt != null)
                            Text(
                              _formatTime(updatedAt.toDate()),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          if (unreadCount > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : unreadCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () {
                        debugLog('CHAT_OPENED:$chatId');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreenEnhanced(
                              chatId: chatId,
                              recipientName: name,
                              recipientAvatar: photoUrl,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Вчера';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}';
    }
  }
}
