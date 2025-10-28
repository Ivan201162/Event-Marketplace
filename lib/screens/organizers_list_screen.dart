import 'package:event_marketplace_app/models/organizer_profile.dart';
import 'package:event_marketplace_app/screens/organizer_profile_screen.dart';
import 'package:event_marketplace_app/services/organizer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран списка организаторов
class OrganizersListScreen extends ConsumerStatefulWidget {
  const OrganizersListScreen({super.key});

  @override
  ConsumerState<OrganizersListScreen> createState() =>
      _OrganizersListScreenState();
}

class _OrganizersListScreenState extends ConsumerState<OrganizersListScreen> {
  final OrganizerService _organizerService = OrganizerService();
  final TextEditingController _searchController = TextEditingController();

  List<OrganizerProfile> _organizers = [];
  List<OrganizerProfile> _filteredOrganizers = [];
  bool _isLoading = true;
  String _selectedCategory = 'Все';
  String _sortBy = 'rating';

  final List<String> _categories = [
    'Все',
    'Свадьбы',
    'Корпоративы',
    'Дни рождения',
    'Юбилеи',
    'Конференции',
    'Выставки',
    'Фестивали',
    'Концерты',
    'Вечеринки',
    'Выпускные',
    'Праздники',
    'Другое',
  ];

  final List<Map<String, String>> _sortOptions = [
    {'key': 'rating', 'label': 'По рейтингу'},
    {'key': 'experience', 'label': 'По опыту'},
    {'key': 'projects', 'label': 'По количеству проектов'},
    {'key': 'name', 'label': 'По названию'},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrganizers();
    _searchController.addListener(_filterOrganizers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final organizers = await _organizerService.getAllActiveOrganizers();
      setState(() {
        _organizers = organizers;
        _filteredOrganizers = organizers;
      });
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка загрузки организаторов: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterOrganizers() {
    final searchQuery = _searchController.text.toLowerCase();

    setState(() {
      _filteredOrganizers = _organizers.where((organizer) {
        // Фильтр по категории
        final categoryMatch = _selectedCategory == 'Все' ||
            organizer.categories.contains(_selectedCategory.toLowerCase());

        // Фильтр по поисковому запросу
        final searchMatch = searchQuery.isEmpty ||
            organizer.name.toLowerCase().contains(searchQuery) ||
            (organizer.description?.toLowerCase().contains(searchQuery) ??
                false) ||
            organizer.categories.any(
                (category) => category.toLowerCase().contains(searchQuery),);

        return categoryMatch && searchMatch;
      }).toList();

      _sortOrganizers();
    });
  }

  void _sortOrganizers() {
    _filteredOrganizers.sort((a, b) {
      switch (_sortBy) {
        case 'rating':
          return b.rating.compareTo(a.rating);
        case 'experience':
          return b.experienceYears.compareTo(a.experienceYears);
        case 'projects':
          return b.projectCount.compareTo(a.projectCount);
        case 'name':
          return a.name.compareTo(b.name);
        default:
          return 0;
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Организаторы мероприятий'),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh), onPressed: _loadOrganizers,),
          ],
        ),
        body: Column(
          children: [
            // Поиск и фильтры
            _buildSearchAndFilters(),

            // Список организаторов
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildOrganizersList(),
            ),
          ],
        ),
      );

  Widget _buildSearchAndFilters() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Поиск
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск организаторов...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Фильтры
            Row(
              children: [
                // Категория
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _categories
                        .map((category) => DropdownMenuItem(
                            value: category, child: Text(category),),)
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                        _filterOrganizers();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Сортировка
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sortBy,
                    decoration: const InputDecoration(
                      labelText: 'Сортировка',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _sortOptions
                        .map(
                          (option) => DropdownMenuItem(
                              value: option['key'],
                              child: Text(option['label']!),),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                        _sortOrganizers();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildOrganizersList() {
    if (_filteredOrganizers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Организаторы не найдены',
                style: TextStyle(fontSize: 18, color: Colors.grey),),
            Text('Попробуйте изменить параметры поиска',
                style: TextStyle(color: Colors.grey),),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrganizers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredOrganizers.length,
        itemBuilder: (context, index) {
          final organizer = _filteredOrganizers[index];
          return _buildOrganizerCard(organizer);
        },
      ),
    );
  }

  Widget _buildOrganizerCard(OrganizerProfile organizer) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: () => _viewOrganizerProfile(organizer),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Аватар
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: organizer.logoUrl != null
                          ? NetworkImage(organizer.logoUrl!)
                          : null,
                      child: organizer.logoUrl == null
                          ? const Icon(Icons.business, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Основная информация
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  organizer.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,),
                                ),
                              ),
                              if (organizer.isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2,),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '✓',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (organizer.description != null)
                            Text(
                              organizer.shortDescription,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14,),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Рейтинг и статистика
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      organizer.formattedRating,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${organizer.reviewCount})',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.work, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${organizer.experienceYears} лет',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.event, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${organizer.projectCount} проектов',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Категории
                if (organizer.categories.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: organizer.categories
                        .take(3)
                        .map(
                          (category) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4,),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.3),),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                  color: Colors.blue[700], fontSize: 12,),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Бюджет и локация
                Row(
                  children: [
                    Icon(Icons.attach_money,
                        color: Colors.green[700], size: 16,),
                    const SizedBox(width: 4),
                    Text(
                      organizer.formattedBudget,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    if (organizer.location != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.location_on,
                          color: Colors.grey[600], size: 16,),
                      const SizedBox(width: 4),
                      Text(
                        organizer.location!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  void _viewOrganizerProfile(OrganizerProfile organizer) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OrganizerProfileScreen(organizerId: organizer.id),
      ),
    );
  }
}
