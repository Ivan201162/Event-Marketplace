import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/specialist.dart';
import '../test_data/mock_data.dart';

class BestSpecialistsCarousel extends ConsumerWidget {
  const BestSpecialistsCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialists = MockData.specialists.take(5).toList();

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
        SizedBox(
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
        ),
      ],
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
