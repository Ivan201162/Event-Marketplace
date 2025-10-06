import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist.dart';
import '../services/specialist_profile_service.dart';
import '../services/specialist_service.dart';

class SpecialistProfileEditScreen extends ConsumerStatefulWidget {
  const SpecialistProfileEditScreen({
    super.key,
    required this.specialistId,
  });
  final String specialistId;

  @override
  ConsumerState<SpecialistProfileEditScreen> createState() =>
      _SpecialistProfileEditScreenState();
}

class _SpecialistProfileEditScreenState
    extends ConsumerState<SpecialistProfileEditScreen> {
  final SpecialistProfileService _profileService = SpecialistProfileService();
  final SpecialistService _specialistService = SpecialistService();

  Specialist? _specialist;
  bool _isLoading = true;

  final Map<String, TextEditingController> _contactControllers = {};
  final Map<String, TextEditingController> _serviceControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};

  @override
  void initState() {
    super.initState();
    _loadSpecialist();
  }

  @override
  void dispose() {
    // Очищаем контроллеры
    for (final controller in _contactControllers.values) {
      controller.dispose();
    }
    for (final controller in _serviceControllers.values) {
      controller.dispose();
    }
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSpecialist() async {
    try {
      final specialist =
          await _specialistService.getSpecialistById(widget.specialistId);
      setState(() {
        _specialist = specialist;
        _isLoading = false;
      });

      // Инициализируем контроллеры для контактов
      for (final contact in specialist?.contacts.entries ?? []) {
        _contactControllers[contact.key] =
            TextEditingController(text: contact.value);
      }

      // Инициализируем контроллеры для услуг
      for (final service in specialist?.servicesWithPrices.entries ?? []) {
        _serviceControllers[service.key] =
            TextEditingController(text: service.key);
        _priceControllers[service.key] =
            TextEditingController(text: service.value.toString());
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки профиля: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveContacts() async {
    try {
      final contacts = <String, String>{};
      for (final entry in _contactControllers.entries) {
        if (entry.value.text.trim().isNotEmpty) {
          contacts[entry.key] = entry.value.text.trim();
        }
      }

      await _profileService.updateContacts(widget.specialistId, contacts);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Контакты сохранены'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения контактов: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveServices() async {
    try {
      final services = <String, double>{};
      for (final serviceKey in _serviceControllers.keys) {
        final serviceName = _serviceControllers[serviceKey]!.text.trim();
        final priceText = _priceControllers[serviceKey]!.text.trim();

        if (serviceName.isNotEmpty && priceText.isNotEmpty) {
          final price = double.tryParse(priceText);
          if (price != null && price > 0) {
            services[serviceName] = price;
          }
        }
      }

      await _profileService.updateServicesWithPrices(
        widget.specialistId,
        services,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Услуги сохранены'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения услуг: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addContact() {
    final contactTypes = [
      'Телефон',
      'Email',
      'Instagram',
      'VK',
      'Telegram',
      'Другое',
    ];

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить контакт'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Тип контакта'),
              items: contactTypes
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null && !_contactControllers.containsKey(value)) {
                  setState(() {
                    _contactControllers[value] = TextEditingController();
                  });
                }
              },
            ),
            if (_contactControllers.isNotEmpty)
              TextField(
                controller: _contactControllers.values.last,
                decoration: const InputDecoration(labelText: 'Значение'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _addService() {
    final serviceKey = 'service_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _serviceControllers[serviceKey] = TextEditingController();
      _priceControllers[serviceKey] = TextEditingController();
    });
  }

  void _removeContact(String contactType) {
    setState(() {
      _contactControllers[contactType]?.dispose();
      _contactControllers.remove(contactType);
    });
  }

  void _removeService(String serviceKey) {
    setState(() {
      _serviceControllers[serviceKey]?.dispose();
      _priceControllers[serviceKey]?.dispose();
      _serviceControllers.remove(serviceKey);
      _priceControllers.remove(serviceKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_specialist == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Редактирование профиля'),
        ),
        body: const Center(
          child: Text('Специалист не найден'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование профиля'),
        actions: [
          TextButton(
            onPressed: () async {
              await _saveContacts();
              await _saveServices();
            },
            child: const Text(
              'Сохранить',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Контакты
            _buildContactsSection(),
            const SizedBox(height: 24),
            // Услуги
            _buildServicesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Контакты',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _addContact,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_contactControllers.isEmpty)
                const Center(
                  child: Text(
                    'Контакты не добавлены',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ..._contactControllers.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: entry.value,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeContact(entry.key),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildServicesSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Услуги и цены',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _addService,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_serviceControllers.isEmpty)
                const Center(
                  child: Text(
                    'Услуги не добавлены',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ..._serviceControllers.keys.map(
                  (serviceKey) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _serviceControllers[serviceKey],
                            decoration: const InputDecoration(
                              labelText: 'Название услуги',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _priceControllers[serviceKey],
                            decoration: const InputDecoration(
                              labelText: 'Цена (₽)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeService(serviceKey),
                          icon: const Icon(Icons.delete, color: Colors.red),
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
