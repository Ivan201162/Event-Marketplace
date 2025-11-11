import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Профиль")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: doc,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() as Map<String, dynamic>? ?? {};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: data['photoUrl'] != null
                      ? NetworkImage(data['photoUrl'] as String)
                      : null,
                  child: data['photoUrl'] == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "${data['city'] ?? ''}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                "Роли: ${(data['roles'] as List?)?.join(', ') ?? 'Не указаны'}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              if (data['rating'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  "Рейтинг: ${data['rating']}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
