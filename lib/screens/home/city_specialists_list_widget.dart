import 'package:event_marketplace_app/models/specialist_enhanced.dart';
import 'package:event_marketplace_app/providers/city_specialists_paged_provider.dart';
import 'package:event_marketplace_app/core/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Виджет списка специалистов города с пагинацией
class CitySpecialistsList extends ConsumerStatefulWidget {
  const CitySpecialistsList({required this.city, super.key});
  final String city;

  @override
  ConsumerState<CitySpecialistsList> createState() => _CitySpecialistsListState();
}

class _CitySpecialistsListState extends ConsumerState<CitySpecialistsList> {
  final List<SpecialistEnhanced> _specialists = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(citySpecialistsPagedProvider((
        city: widget.city,
        startAfter: null,
        limit: 20,
      )).future);

      setState(() {
        _specialists.addAll(result.items);
        _lastDoc = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;

    setState(() => _isLoadingMore = true);
    try {
      final result = await ref.read(citySpecialistsPagedProvider((
        city: widget.city,
        startAfter: _lastDoc,
        limit: 20,
      )).future);

      setState(() {
        _specialists.addAll(result.items);
        _lastDoc = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Специалисты вашего города',
          style: TextStyle(
            fontSize: context.isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_specialists.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Пока нет специалистов в этом городе',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Column(
            children: [
              ..._specialists.map((specialist) => _buildSpecialistCard(context, specialist)).toList(),
              if (_hasMore)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isLoadingMore
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _loadMore,
                          child: const Text('Загрузить ещё'),
                        ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildSpecialistCard(BuildContext context, SpecialistEnhanced specialist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/profile/${specialist.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: specialist.avatarUrl != null
                    ? NetworkImage(specialist.avatarUrl!)
                    : null,
                child: specialist.avatarUrl == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      specialist.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (specialist.categories.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: specialist.categories.take(2).map((cat) {
                          return Chip(
                            label: Text(
                              cat,
                              style: const TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          specialist.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${specialist.reviews.length} отзывов)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (specialist.bio != null && specialist.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        specialist.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

