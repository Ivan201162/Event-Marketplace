import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/specialist.dart';
import '../providers/real_specialists_providers.dart';
import '../core/feature_flags.dart';

class BestSpecialistsCarousel extends ConsumerWidget {
  const BestSpecialistsCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialistsAsync = ref.watch(RealSpecialistsProviders.topSpecialistsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Лучшие специалисты недели',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: () => context.push('/specialists'), child: const Text('Все')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        specialistsAsync.when(
          data: (specialists) {
            if (specialists.isEmpty) {
              return _buildEmptyState();
            }
            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: specialists.length,
                itemBuilder: (context, index) {
                  final specialist = specialists[index];
                  return _SpecialistCard(specialist: specialist);
                },
              ),
            );
          },
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error.toString()),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Специалисты не найдены',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            const Text(
              'Ошибка загрузки',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialistCard extends StatelessWidget {
  const _SpecialistCard({required this.specialist});
  final Specialist specialist;

  @override
  Widget build(BuildContext context) => Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => context.push('/specialist/${specialist.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Аватар специалиста
              Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: specialist.avatar != null
                      ? DecorationImage(image: NetworkImage(specialist.avatar!), fit: BoxFit.cover)
                      : null,
                  color: specialist.avatar == null
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                      : null,
                ),
                child: specialist.avatar == null
                    ? const Center(child: Icon(Icons.person, size: 40, color: Colors.grey))
                    : null,
              ),
              // Информация о специалисте
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialist.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        specialist.category?.displayName ?? 'Категория',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 14),
                          const SizedBox(width: 2),
                          Text(
                            specialist.rating.toString(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            '${specialist.price}₸',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
