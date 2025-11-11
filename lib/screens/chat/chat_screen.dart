import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final chats = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Чаты")),
      body: StreamBuilder<QuerySnapshot>(
        stream: chats,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data!.docs.isEmpty) {
            return const Center(child: Text("Нет сообщений"));
          }

          return ListView(
            children: snap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(d['lastMessage'] ?? 'Новое сообщение'),
                  subtitle: Text(
                    d['updatedAt'] != null
                        ? (d['updatedAt'] is Timestamp
                            ? "Обновлено: ${d['updatedAt'].toDate()}"
                            : "Обновлено: ${d['updatedAt']}")
                        : 'Дата не указана',
                  ),
                  onTap: () {
                    // TODO: Открыть детальный чат
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
