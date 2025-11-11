import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    // Загружаем заявки где пользователь является специалистом или клиентом
    final requests = FirebaseFirestore.instance
        .collection('bookings')
        .where('specialistId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Заявки")),
      body: StreamBuilder<QuerySnapshot>(
        stream: requests,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data!.docs.isEmpty) {
            return const Center(child: Text("Нет заявок"));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: snap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(d['serviceType'] ?? 'Услуга'),
                  subtitle: Text(
                    d['date'] != null
                        ? (d['date'] is Timestamp
                            ? d['date'].toDate().toString()
                            : d['date'].toString())
                        : 'Дата не указана',
                  ),
                  trailing: Chip(
                    label: Text(d['status'] ?? 'pending'),
                    backgroundColor: _getStatusColor(d['status'] ?? 'pending'),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
