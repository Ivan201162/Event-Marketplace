import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/debug_log.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/chip_badge.dart';
import '../../ui/components/outlined_button_x.dart';
import '../profile/profile_screen_v2.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildSpecialistCard(Map<String, dynamic> data, BuildContext context) {
    final roles = (data['roles'] as List?) ?? [];
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final photoUrl = data['photoUrl'] as String?;
    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    final city = data['city'] ?? '';
    final specialistId = data['uid'] as String? ?? '';

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreenV2(userId: specialistId),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$firstName $lastName',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(city, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text('${rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (roles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: roles.take(2).map((role) {
                return ChipBadge(label: role.toString());
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButtonX(
                  text: 'Профиль',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreenV2(userId: specialistId),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: OutlinedButtonX(
                  text: 'Связаться',
                  onTap: () {
                    // TODO: Открыть чат
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: OutlinedButtonX(
                  text: 'Заказать',
                  onTap: () {
                    // TODO: Открыть календарь для бронирования
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(String title, Query query, String region) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            final count = snap.data!.docs.length;
            if (region == 'RU') {
              debugLog('HOME_TOP_RU_COUNT:$count');
            } else {
              debugLog('HOME_TOP_CITY_COUNT:$count');
            }
            
            if (count == 0) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('Специалисты не найдены')),
              );
            }

            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: count,
                itemBuilder: (ctx, i) {
                  final doc = snap.data!.docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  // Добавляем uid из document ID
                  data['uid'] = doc.id;
                  return SizedBox(
                    width: 300,
                    child: _buildSpecialistCard(data, ctx),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserProfileCard(Map<String, dynamic>? userData) {
    if (userData == null) {
      return const SizedBox.shrink();
    }

    final firstName = userData['firstName'] ?? '';
    final lastName = userData['lastName'] ?? '';
    final city = userData['city'] ?? '';
    final roles = (userData['roles'] as List?) ?? [];
    final photoUrl = userData['photoUrl'] as String?;

    return AppCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? const Icon(Icons.person, size: 32) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$firstName $lastName',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(city, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                if (roles.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: roles.take(3).map((role) {
                      return ChipBadge(label: role.toString());
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Необходима авторизация')));
    }

    debugLog('HOME_LOADED');

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
    final userCity = userDoc.map((snap) {
      final data = snap.data() as Map<String, dynamic>?;
      return data?['city'] as String?;
    });

    // Запрос для лучших по России
    final topRussiaQuery = FirebaseFirestore.instance
        .collection('users')
        .where('roles', isNotEqualTo: null)
        .orderBy('rating', descending: true)
        .limit(10);

    return Scaffold(
      appBar: AppBar(title: const Text("Главная")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userDoc,
        builder: (ctx, userSnap) {
          final userData = userSnap.data?.data() as Map<String, dynamic>?;
          
          return StreamBuilder<String?>(
            stream: userCity,
            builder: (ctx, citySnap) {
              final city = citySnap.data;
              
              // Запрос для лучших в городе
              Query topCityQuery = FirebaseFirestore.instance
                  .collection('users')
                  .where('roles', isNotEqualTo: null);
              
              if (city != null && city.isNotEmpty) {
                topCityQuery = topCityQuery.where('cityLower', isEqualTo: city.toLowerCase());
              }
              topCityQuery = topCityQuery.orderBy('rating', descending: true).limit(10);

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserProfileCard(userData),
                    _buildCarousel('Лучшие специалисты недели — Россия', topRussiaQuery, 'RU'),
                    const SizedBox(height: 16),
                    _buildCarousel(
                      city != null ? 'Лучшие специалисты недели — $city' : 'Лучшие специалисты',
                      topCityQuery,
                      city ?? 'ALL',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
