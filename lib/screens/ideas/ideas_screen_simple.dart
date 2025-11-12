import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IdeasScreenSimple extends StatelessWidget {
  const IdeasScreenSimple({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    // Загружаем идеи пользователя
    final userIdeas = FirebaseFirestore.instance
        .collection('ideas')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    // Загружаем рекомендованные идеи (общий поток)
    final recommendedIdeas = FirebaseFirestore.instance
        .collection('ideas')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Идеи"),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Мои идеи'),
              Tab(text: 'Рекомендации'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Мои идеи
            StreamBuilder<QuerySnapshot>(
              stream: userIdeas,
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.data!.docs.isEmpty) {
                  return const Center(child: Text("У вас пока нет идей"));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: snap.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(d['title'] ?? 'Без названия'),
                        subtitle: Text(d['text'] ?? ''),
                        trailing: d['attachments'] != null && (d['attachments'] as List).isNotEmpty
                            ? const Icon(Icons.attachment)
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            // Рекомендации
            StreamBuilder<QuerySnapshot>(
              stream: recommendedIdeas,
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.data!.docs.isEmpty) {
                  return const Center(child: Text("Идей пока нет"));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: snap.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(d['title'] ?? 'Без названия'),
                        subtitle: Text(d['text'] ?? ''),
                        trailing: d['attachments'] != null && (d['attachments'] as List).isNotEmpty
                            ? const Icon(Icons.attachment)
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


