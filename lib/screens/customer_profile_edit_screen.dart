import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class CustomerProfileEditScreen extends ConsumerStatefulWidget {
  const CustomerProfileEditScreen({super.key});

  @override
  ConsumerState<CustomerProfileEditScreen> createState() =>
      _CustomerProfileEditScreenState();
}

class _CustomerProfileEditScreenState
    extends ConsumerState<CustomerProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  MaritalStatus? _selectedMaritalStatus;
  DateTime? _weddingDate;
  DateTime? _anniversaryDate;
  List<String> _interests = [];
  List<String> _eventTypes = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      ref
          .read(customerProfileEditProvider.notifier)
          .loadProfile(currentUser.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(customerProfileEditProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    // Инициализация полей при загрузке профиля
    if (editState.profile != null && !editState.isDirty) {
      final profile = editState.profile!;
      _bioController.text = profile.bio ?? '';
      _phoneController.text = profile.phoneNumber ?? '';
      _locationController.text = profile.location ?? '';
      _selectedMaritalStatus = profile.maritalStatus;
      _weddingDate = profile.weddingDate;
      _anniversaryDate = profile.anniversaryDate;
      _interests = List.from(profile.interests);
      _eventTypes = List.from(profile.eventTypes);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование профиля'),
        actions: [
          if (editState.isDirty)
            TextButton(
              onPressed: editState.isLoading
                  ? null
                  : () {
                      ref
                          .read(customerProfileEditProvider.notifier)
                          .saveProfile();
                    },
              child: editState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
        ],
      ),
      body: editState.isLoading && editState.profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Фото профиля
                    _buildProfilePhoto(),
                    const SizedBox(height: 24),

                    // Основная информация
                    _buildBasicInfo(),
                    const SizedBox(height: 24),

                    // Семейное положение
                    _buildMaritalStatus(),
                    const SizedBox(height: 24),

                    // Важные даты
                    _buildImportantDates(),
                    const SizedBox(height: 24),

                    // Интересы
                    _buildInterests(),
                    const SizedBox(height: 24),

                    // Типы мероприятий
                    _buildEventTypes(),
                    const SizedBox(height: 24),

                    // Ошибка
                    if (editState.errorMessage != null)
                      _buildErrorMessage(editState.errorMessage!),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePhoto() => Center(
        child: Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Colors.grey,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () {
                    // TODO(developer): Реализовать загрузку фото
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Загрузка фото будет реализована позже'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildBasicInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Основная информация',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Биография
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'О себе',
                  hintText: 'Расскажите о себе и ваших интересах',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  ref
                      .read(customerProfileEditProvider.notifier)
                      .updateField(bio: value);
                },
              ),
              const SizedBox(height: 16),

              // Телефон
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  hintText: '+7 (999) 123-45-67',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  ref
                      .read(customerProfileEditProvider.notifier)
                      .updateField(phoneNumber: value);
                },
              ),
              const SizedBox(height: 16),

              // Локация
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Город',
                  hintText: 'Москва',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                onChanged: (value) {
                  ref
                      .read(customerProfileEditProvider.notifier)
                      .updateField(location: value);
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildMaritalStatus() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Семейное положение',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: MaritalStatus.values
                    .map(
                      (status) => FilterChip(
                        label: Text(_getMaritalStatusDisplayName(status)),
                        selected: _selectedMaritalStatus == status,
                        onSelected: (selected) {
                          setState(() {
                            _selectedMaritalStatus = selected ? status : null;
                          });
                          ref
                              .read(customerProfileEditProvider.notifier)
                              .updateField(
                                maritalStatus: _selectedMaritalStatus,
                              );
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      );

  Widget _buildImportantDates() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Важные даты',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Дата свадьбы
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Дата свадьбы'),
                subtitle: Text(
                  _weddingDate != null
                      ? '${_weddingDate!.day}.${_weddingDate!.month}.${_weddingDate!.year}'
                      : 'Не указана',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _weddingDate ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365 * 10)),
                  );
                  if (date != null) {
                    setState(() {
                      _weddingDate = date;
                    });
                    ref.read(customerProfileEditProvider.notifier).updateField(
                          weddingDate: _weddingDate,
                        );
                  }
                },
              ),

              // Дата годовщины
              ListTile(
                leading: const Icon(Icons.celebration),
                title: const Text('Дата годовщины'),
                subtitle: Text(
                  _anniversaryDate != null
                      ? '${_anniversaryDate!.day}.${_anniversaryDate!.month}.${_anniversaryDate!.year}'
                      : 'Не указана',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _anniversaryDate ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365 * 10)),
                  );
                  if (date != null) {
                    setState(() {
                      _anniversaryDate = date;
                    });
                    ref.read(customerProfileEditProvider.notifier).updateField(
                          anniversaryDate: _anniversaryDate,
                        );
                  }
                },
              ),
            ],
          ),
        ),
      );

  Widget _buildInterests() {
    final predefinedInterests = [
      'Спорт',
      'Музыка',
      'Кино',
      'Книги',
      'Путешествия',
      'Кулинария',
      'Фотография',
      'Искусство',
      'Театр',
      'Танцы',
      'Йога',
      'Готовка',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Интересы',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: predefinedInterests.map((interest) {
                final isSelected = _interests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _interests.add(interest);
                      } else {
                        _interests.remove(interest);
                      }
                    });
                    ref.read(customerProfileEditProvider.notifier).updateField(
                          interests: _interests,
                        );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypes() {
    final eventTypes = [
      'Свадьба',
      'День рождения',
      'Корпоратив',
      'Детский праздник',
      'Юбилей',
      'Выпускной',
      'Новый год',
      '8 марта',
      '23 февраля',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Типы мероприятий',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Какие мероприятия вы планируете?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: eventTypes.map((eventType) {
                final isSelected = _eventTypes.contains(eventType);
                return FilterChip(
                  label: Text(eventType),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _eventTypes.add(eventType);
                      } else {
                        _eventTypes.remove(eventType);
                      }
                    });
                    ref.read(customerProfileEditProvider.notifier).updateField(
                          eventTypes: _eventTypes,
                        );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

  String _getMaritalStatusDisplayName(MaritalStatus status) {
    switch (status) {
      case MaritalStatus.single:
        return 'Холост/не замужем';
      case MaritalStatus.married:
        return 'Женат/замужем';
      case MaritalStatus.divorced:
        return 'Разведен/разведена';
      case MaritalStatus.widowed:
        return 'Вдовец/вдова';
      case MaritalStatus.inRelationship:
        return 'В отношениях';
    }
  }
}
