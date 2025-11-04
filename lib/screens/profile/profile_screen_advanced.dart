import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/app_user.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Мини-профиль пользователя
class ProfileScreenAdvanced extends ConsumerStatefulWidget {
  const ProfileScreenAdvanced({
    required this.userId,
    super.key,
  });
  final String userId;

  @override
  ConsumerState<ProfileScreenAdvanced> createState() => _ProfileScreenAdvancedState();
}

class _ProfileScreenAdvancedState extends ConsumerState<ProfileScreenAdvanced> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("PROFILE_OPENED:${widget.userId}");
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnProfile = currentUser?.uid == widget.userId;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Профиль'),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Пользователь не найден'));
            }

            try {
              final user = AppUser.fromFirestore(snapshot.data!);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Шапка профиля
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user.photoURL == null || user.photoURL!.isEmpty
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim().isEmpty
                                    ? (user.email ?? user.name ?? 'Пользователь')
                                    : '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (user.username != null && user.username!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '@${user.username}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                user.city ?? 'Город не указан',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (user.role != null) ...[
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                    user.role == 'specialist' ? 'Специалист' : 'Пользователь',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Кнопки действий
                    if (isOwnProfile)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Редактировать профиль'),
                          onPressed: () {
                            context.push('/profile/edit');
                          },
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.person_add),
                              label: const Text('Подписаться'),
                              onPressed: () {
                                // TODO: реализовать подписку
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.message),
                              label: const Text('Написать'),
                              onPressed: () {
                                // TODO: открыть чат
                              },
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 32),

                    // Секции
                    const Text(
                      'Посты',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Пока нет постов', style: TextStyle(color: Colors.grey)),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Рилсы',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Пока нет рилсов', style: TextStyle(color: Colors.grey)),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Отзывы',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Пока нет отзывов', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ],
                ),
              );
            } catch (e) {
              return Center(child: Text('Ошибка загрузки: $e'));
            }
          },
        ),
      ),
    );
  }
}
