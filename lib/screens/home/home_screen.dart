import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../providers/specialist_providers.dart';
import '../../widgets/specialist_card.dart';

/// Home screen with user profile and main content
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.push('/notifications');
            },
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Пользователь не найден'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User profile card
                _buildUserProfileCard(context, user),
                const SizedBox(height: 24),

                // Search section
                _buildSearchSection(context),
                const SizedBox(height: 24),

                // Categories section
                _buildCategoriesSection(context, ref),
                const SizedBox(height: 24),

                // Top specialists section
                _buildTopSpecialistsSection(
                    context, ref, 'Топ-10 недели по России', true),
                const SizedBox(height: 24),
                _buildTopSpecialistsSection(
                  context,
                  ref,
                  'Топ-10 недели по городу ${user.city ?? ''}',
                  false,
                ),
                const SizedBox(height: 24),

                // Quick actions
                _buildQuickActions(context),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
      ),
    );
  }

  Widget _buildUserProfileCard(BuildContext context, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (user.city != null) ...[
                    const SizedBox(height: 4),
                    Text(user.city!,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                  if (user.status != null) ...[
                    const SizedBox(height: 4),
                    Text(user.status!,
                        style:
                            TextStyle(color: Colors.blue[600], fontSize: 14)),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/profile/edit');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Поиск специалистов',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по имени, категории, городу...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    context.push('/search');
                  },
                ),
              ),
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  context.push('/search?query=${Uri.encodeComponent(query)}');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context, WidgetRef ref) {
    final specializationsAsync = ref.watch(popularSpecializationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Популярные категории',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        specializationsAsync.when(
          data: (specializations) {
            if (specializations.isEmpty) {
              return const Center(child: Text('Нет категорий'));
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: specializations.length,
              itemBuilder: (context, index) {
                final specialization = specializations[index];
                final iconData = _getSpecializationIcon(specialization);
                final color = _getSpecializationColor(specialization);

                return GestureDetector(
                  onTap: () {
                    context.push(
                        '/search?specialization=${Uri.encodeComponent(specialization)}');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(iconData, size: 36, color: color),
                        const SizedBox(height: 8),
                        Text(
                          specialization,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Ошибка: $error')),
        ),
      ],
    );
  }

  IconData _getSpecializationIcon(String specialization) {
    switch (specialization.toLowerCase()) {
      case 'ведущий':
      case 'ведущие':
        return Icons.mic;
      case 'фотограф':
      case 'фотографы':
        return Icons.camera_alt;
      case 'dj':
        return Icons.headset;
      case 'видеограф':
      case 'видеографы':
        return Icons.videocam;
      case 'декоратор':
      case 'декораторы':
        return Icons.palette;
      case 'аниматор':
      case 'аниматоры':
        return Icons.sentiment_very_satisfied;
      case 'музыкант':
      case 'музыканты':
        return Icons.music_note;
      case 'танцор':
      case 'танцоры':
        return Icons.music_note;
      case 'кейтеринг':
        return Icons.restaurant;
      default:
        return Icons.work;
    }
  }

  Color _getSpecializationColor(String specialization) {
    switch (specialization.toLowerCase()) {
      case 'ведущий':
      case 'ведущие':
        return Colors.blue;
      case 'фотограф':
      case 'фотографы':
        return Colors.green;
      case 'dj':
        return Colors.purple;
      case 'видеограф':
      case 'видеографы':
        return Colors.red;
      case 'декоратор':
      case 'декораторы':
        return Colors.orange;
      case 'аниматор':
      case 'аниматоры':
        return Colors.pink;
      case 'музыкант':
      case 'музыканты':
        return Colors.indigo;
      case 'танцор':
      case 'танцоры':
        return Colors.teal;
      case 'кейтеринг':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTopSpecialistsSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    bool isCountryWide,
  ) {
    final currentUser = ref.watch(currentUserProvider).value;
    final specialistsAsync = isCountryWide
        ? ref.watch(topSpecialistsRuProvider)
        : ref.watch(topSpecialistsCityProvider(currentUser?.city ?? 'Москва'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
              onPressed: () {
                context.push('/search');
              },
              child: const Text('Все'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        specialistsAsync.when(
          data: (specialists) {
            if (specialists.isEmpty) {
              return const Center(child: Text('Нет специалистов'));
            }
            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: specialists.length,
                itemBuilder: (context, index) {
                  final specialist = specialists[index];
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 12),
                    child: SpecialistCard(
                      specialist: specialist,
                      onTap: () {
                        context.push('/specialist/${specialist.id}');
                      },
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Ошибка: $error')),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Быстрые действия',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/requests/create');
                },
                icon: const Icon(Icons.add),
                label: const Text('Создать заявку'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push('/posts/create');
                },
                icon: const Icon(Icons.post_add),
                label: const Text('Создать пост'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
