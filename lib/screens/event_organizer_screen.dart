import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_organizer.dart';
import '../services/error_logging_service.dart';
import '../services/event_organizer_service.dart';

/// Экран режима организатора мероприятий
class EventOrganizerScreen extends ConsumerStatefulWidget {
  const EventOrganizerScreen({super.key});

  @override
  ConsumerState<EventOrganizerScreen> createState() =>
      _EventOrganizerScreenState();
}

class _EventOrganizerScreenState extends ConsumerState<EventOrganizerScreen> {
  final EventOrganizerService _organizerService = EventOrganizerService();
  final ErrorLoggingService _errorLogger = ErrorLoggingService();

  bool _isLoading = false;
  EventOrganizer? _currentOrganizer;
  Map<String, dynamic>? _stats;
  List<EventOrganizer> _topOrganizers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Загружаем топ организаторов
      final topOrganizers = await _organizerService.getTopOrganizers();

      if (mounted) {
        setState(() {
          _topOrganizers = topOrganizers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Ошибка загрузки данных: $e');
      }
    }
  }

  Future<void> _createOrganizerProfile() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(
        builder: (context) => const CreateOrganizerProfileScreen()));

    if (result == true) {
      _loadData();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Организаторы Мероприятий'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _createOrganizerProfile,
              icon: const Icon(Icons.add),
              tooltip: 'Создать профиль организатора',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    const Text(
                      'Топ Организаторы',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Список организаторов
                    if (_topOrganizers.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Организаторы не найдены',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ..._topOrganizers.map(_buildOrganizerCard),

                    const SizedBox(height: 24),

                    // Кнопка создания профиля
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _createOrganizerProfile,
                        icon: const Icon(Icons.business),
                        label: const Text('Стать организатором'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );

  Widget _buildOrganizerCard(EventOrganizer organizer) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок карточки
              Row(
                children: [
                  // Аватар
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.purple[100],
                    child: Text(
                      organizer.companyName.isNotEmpty
                          ? organizer.companyName[0].toUpperCase()
                          : 'О',
                      style: TextStyle(
                        color: Colors.purple[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Информация о компании
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organizer.companyName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (organizer.city != null)
                          Text(
                            organizer.city!,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                      ],
                    ),
                  ),

                  // Рейтинг
                  if (organizer.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            organizer.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Описание
              if (organizer.description != null)
                Text(
                  organizer.description!,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Типы мероприятий
              if (organizer.eventTypes.isNotEmpty) ...[
                const Text(
                  'Типы мероприятий:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: organizer.eventTypes
                      .take(3)
                      .map(
                        (type) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple[200]!),
                          ),
                          child: Text(type,
                              style: TextStyle(
                                  color: Colors.purple[700], fontSize: 10)),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Статистика
              Row(
                children: [
                  _buildStatItem(
                      'Мероприятий', '${organizer.totalEvents}', Icons.event),
                  const SizedBox(width: 16),
                  _buildStatItem('Завершено', '${organizer.completedEvents}',
                      Icons.check_circle),
                  const Spacer(),

                  // Кнопка просмотра
                  TextButton(
                    onPressed: () => _viewOrganizerDetails(organizer),
                    child: const Text('Подробнее'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStatItem(String label, String value, IconData icon) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            ],
          ),
        ],
      );

  void _viewOrganizerDetails(EventOrganizer organizer) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(
        builder: (context) => OrganizerDetailsScreen(organizer: organizer)));
  }
}

/// Экран создания профиля организатора
class CreateOrganizerProfileScreen extends ConsumerStatefulWidget {
  const CreateOrganizerProfileScreen({super.key});

  @override
  ConsumerState<CreateOrganizerProfileScreen> createState() =>
      _CreateOrganizerProfileScreenState();
}

class _CreateOrganizerProfileScreenState
    extends ConsumerState<CreateOrganizerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventOrganizerService _organizerService = EventOrganizerService();
  final ErrorLoggingService _errorLogger = ErrorLoggingService();

  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _taxIdController = TextEditingController();

  final List<String> _selectedEventTypes = [];
  final List<String> _selectedSpecializations = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _licenseNumberController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEventTypes.isEmpty) {
      _showErrorSnackBar('Выберите хотя бы один тип мероприятий');
      return;
    }
    if (_selectedSpecializations.isEmpty) {
      _showErrorSnackBar('Выберите хотя бы одну специализацию');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Здесь должен быть userId текущего пользователя
      const userId = 'current_user_id'; // Заменить на реальный ID

      final organizer = await _organizerService.createOrganizer(
        userId: userId,
        companyName: _companyNameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        website: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        eventTypes: _selectedEventTypes,
        specializations: _selectedSpecializations,
        licenseNumber: _licenseNumberController.text.trim().isNotEmpty
            ? _licenseNumberController.text.trim()
            : null,
        taxId: _taxIdController.text.trim().isNotEmpty
            ? _taxIdController.text.trim()
            : null,
      );

      if (organizer != null) {
        _showSuccessSnackBar('Профиль организатора создан успешно!');
        Navigator.of(context).pop(true);
      } else {
        _showErrorSnackBar('Ошибка создания профиля');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка создания профиля: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Создать профиль организатора'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Основная информация
                      const Text(
                        'Основная информация',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Название компании *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название компании';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Контактная информация
                      const Text(
                        'Контактная информация',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Телефон',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(
                          labelText: 'Веб-сайт',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Адрес',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'Город',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Типы мероприятий
                      const Text(
                        'Типы мероприятий *',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: EventType.values.map((type) {
                          final isSelected =
                              _selectedEventTypes.contains(type.name);
                          return FilterChip(
                            label: Text(type.displayName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedEventTypes.add(type.name);
                                } else {
                                  _selectedEventTypes.remove(type.name);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Специализации
                      const Text(
                        'Специализации *',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: OrganizerSpecialization.values.map((spec) {
                          final isSelected =
                              _selectedSpecializations.contains(spec.name);
                          return FilterChip(
                            label: Text(spec.displayName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSpecializations.add(spec.name);
                                } else {
                                  _selectedSpecializations.remove(spec.name);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Юридическая информация
                      const Text(
                        'Юридическая информация',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _licenseNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Номер лицензии',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _taxIdController,
                        decoration: const InputDecoration(
                          labelText: 'ИНН',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Кнопка создания
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Создать профиль',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      );
}

/// Экран деталей организатора
class OrganizerDetailsScreen extends StatelessWidget {
  const OrganizerDetailsScreen({super.key, required this.organizer});
  final EventOrganizer organizer;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(organizer.companyName),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Основная информация',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (organizer.description != null) ...[
                        Text(organizer.description!),
                        const SizedBox(height: 16),
                      ],
                      if (organizer.city != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 8),
                            Text(organizer.city!),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (organizer.phone != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16),
                            const SizedBox(width: 8),
                            Text(organizer.phone!),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (organizer.email != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.email, size: 16),
                            const SizedBox(width: 8),
                            Text(organizer.email!),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (organizer.website != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.web, size: 16),
                            const SizedBox(width: 8),
                            Text(organizer.website!),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Типы мероприятий
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Типы мероприятий',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: organizer.eventTypes
                            .map((type) => Chip(
                                label: Text(type),
                                backgroundColor: Colors.purple[50]))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Специализации
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Специализации',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: organizer.specializations
                            .map((spec) => Chip(
                                label: Text(spec),
                                backgroundColor: Colors.blue[50]))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Статистика
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Статистика',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Всего мероприятий',
                              '${organizer.totalEvents}',
                              Icons.event,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Завершено',
                              '${organizer.completedEvents}',
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (organizer.rating != null) ...[
                        const SizedBox(height: 16),
                        _buildStatCard(
                          'Рейтинг',
                          organizer.rating!.toStringAsFixed(1),
                          Icons.star,
                          Colors.amber,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildStatCard(
          String title, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style:
                  TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
