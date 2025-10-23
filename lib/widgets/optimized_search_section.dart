import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Оптимизированная секция поиска
class OptimizedSearchSection extends StatelessWidget {
  const OptimizedSearchSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Найти специалиста',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildSearchBar(context),
          const SizedBox(height: 12),
          _buildQuickFilters(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        onTap: () => context.push('/search'),
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'Поиск по специалистам, услугам, категориям...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: IconButton(
            icon: Icon(Icons.tune, color: Colors.grey[600]),
            onPressed: () => context.push('/search/advanced'),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    final filters = [
      {
        'label': 'Фотографы',
        'icon': Icons.camera_alt,
        'category': 'photographer'
      },
      {
        'label': 'Видеографы',
        'icon': Icons.videocam,
        'category': 'videographer'
      },
      {'label': 'Ведущие', 'icon': Icons.mic, 'category': 'host'},
      {'label': 'DJ', 'icon': Icons.music_note, 'category': 'dj'},
      {'label': 'Декораторы', 'icon': Icons.palette, 'category': 'decorator'},
      {'label': 'Флористы', 'icon': Icons.local_florist, 'category': 'florist'},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          return _buildFilterChip(
            context,
            label: filter['label']!,
            icon: filter['icon'] as IconData,
            onTap: () => context.push('/search?category=${filter['category']}'),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
