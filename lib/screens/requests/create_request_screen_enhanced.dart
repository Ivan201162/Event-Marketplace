import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/request_enhanced.dart';
import '../../services/request_service_enhanced.dart';
import '../../providers/request_providers_enhanced.dart';
import '../../widgets/common/enhanced_button.dart';
import '../../widgets/common/enhanced_card.dart';

/// Экран создания заявки с полным функционалом
class CreateRequestScreenEnhanced extends ConsumerStatefulWidget {
  const CreateRequestScreenEnhanced({super.key});

  @override
  ConsumerState<CreateRequestScreenEnhanced> createState() =>
      _CreateRequestScreenEnhancedState();
}

class _CreateRequestScreenEnhancedState
    extends ConsumerState<CreateRequestScreenEnhanced>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _maxApplicantsController = TextEditingController();

  String _selectedCategory = '';
  String _selectedSubcategory = '';
  String _selectedCity = '';
  String _selectedLanguage = 'ru';
  RequestPriority _selectedPriority = RequestPriority.medium;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isRemote = false;
  List<String> _selectedTags = [];
  List<String> _selectedSkills = [];
  List<String> _attachments = [];
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _maxApplicantsController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      print('Ошибка получения геолокации: $e');
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _selectLocation() async {
    // Здесь можно интегрировать с картами для выбора локации
    // Пока используем текстовый ввод
    final location = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выбор локации'),
        content: TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            hintText: 'Введите адрес или название места',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _locationController.text),
            child: const Text('Выбрать'),
          ),
        ],
      ),
    );

    if (location != null) {
      setState(() {
        _locationController.text = location;
      });
    }
  }

  Future<void> _selectAttachments() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      builder: (context) => _buildAttachmentSelector(),
    );

    if (result != null) {
      setState(() {
        _attachments = result;
      });
    }
  }

  Widget _buildAttachmentSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Выберите тип вложения',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Фото'),
            onTap: () async {
              final picker = ImagePicker();
              final images = await picker.pickMultiImage();
              if (images.isNotEmpty) {
                Navigator.pop(context, images.map((e) => e.path).toList());
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Видео'),
            onTap: () async {
              final picker = ImagePicker();
              final video = await picker.pickVideo();
              if (video != null) {
                Navigator.pop(context, [video.path]);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: const Text('Файлы'),
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                allowMultiple: true,
                type: FileType.any,
              );
              if (result != null) {
                Navigator.pop(
                    context, result.files.map((e) => e.path!).toList());
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectTags() async {
    final tags = await showDialog<List<String>>(
      context: context,
      builder: (context) => _buildTagSelector(),
    );

    if (tags != null) {
      setState(() {
        _selectedTags = tags;
      });
    }
  }

  Widget _buildTagSelector() {
    return AlertDialog(
      title: const Text('Выберите теги'),
      content: Consumer(
        builder: (context, ref, child) {
          final tagsAsync = ref.watch(requestTagsProvider);
          return tagsAsync.when(
            data: (tags) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Ошибка: $error'),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedTags),
          child: const Text('Выбрать'),
        ),
      ],
    );
  }

  Future<void> _selectSkills() async {
    final skills = await showDialog<List<String>>(
      context: context,
      builder: (context) => _buildSkillSelector(),
    );

    if (skills != null) {
      setState(() {
        _selectedSkills = skills;
      });
    }
  }

  Widget _buildSkillSelector() {
    return AlertDialog(
      title: const Text('Выберите навыки'),
      content: Consumer(
        builder: (context, ref, child) {
          final skillsAsync = ref.watch(requestSkillsProvider);
          return skillsAsync.when(
            data: (skills) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) {
                final isSelected = _selectedSkills.contains(skill);
                return FilterChip(
                  label: Text(skill),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSkills.add(skill);
                      } else {
                        _selectedSkills.remove(skill);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Ошибка: $error'),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedSkills),
          child: const Text('Выбрать'),
        ),
      ],
    );
  }

  Future<void> _createRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final deadline = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final requestId = await RequestServiceEnhanced.createRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        location: _locationController.text.trim(),
        city: _selectedCity,
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        budget: double.parse(_budgetController.text),
        deadline: deadline,
        priority: _selectedPriority,
        attachments: _attachments,
        tags: _selectedTags,
        requiredSkills: _selectedSkills,
        language: _selectedLanguage,
        isRemote: _isRemote,
        maxApplicants: int.parse(_maxApplicantsController.text),
        metadata: {
          'createdVia': 'mobile_app',
          'version': '1.0.0',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заявка успешно создана!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания заявки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать заявку'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Основная информация
                EnhancedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Основная информация',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Название заявки',
                          hintText: 'Введите название заявки',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название заявки';
                          }
                          if (value.trim().length < 5) {
                            return 'Название должно содержать минимум 5 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          hintText: 'Подробно опишите задачу',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите описание заявки';
                          }
                          if (value.trim().length < 20) {
                            return 'Описание должно содержать минимум 20 символов';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Категория и подкатегория
                EnhancedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Категория',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Consumer(
                        builder: (context, ref, child) {
                          final categoriesAsync =
                              ref.watch(requestCategoriesProvider);
                          return categoriesAsync.when(
                            data: (categories) =>
                                DropdownButtonFormField<String>(
                              value: _selectedCategory.isEmpty
                                  ? null
                                  : _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Выберите категорию',
                                border: OutlineInputBorder(),
                              ),
                              items: categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value ?? '';
                                  _selectedSubcategory = '';
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Выберите категорию';
                                }
                                return null;
                              },
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (error, stack) => Text('Ошибка: $error'),
                          );
                        },
                      ),
                      if (_selectedCategory.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            final subcategoriesAsync = ref.watch(
                              requestSubcategoriesProvider(_selectedCategory),
                            );
                            return subcategoriesAsync.when(
                              data: (subcategories) =>
                                  DropdownButtonFormField<String>(
                                value: _selectedSubcategory.isEmpty
                                    ? null
                                    : _selectedSubcategory,
                                decoration: const InputDecoration(
                                  labelText: 'Выберите подкатегорию',
                                  border: OutlineInputBorder(),
                                ),
                                items: subcategories.map((subcategory) {
                                  return DropdownMenuItem(
                                    value: subcategory,
                                    child: Text(subcategory),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSubcategory = value ?? '';
                                  });
                                },
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (error, stack) => Text('Ошибка: $error'),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Локация и дата
                EnhancedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Локация и время',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: 'Локация',
                                hintText: 'Введите адрес',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите локацию';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _selectLocation,
                            icon: const Icon(Icons.location_on),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Город',
                                hintText: 'Введите город',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCity = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите город';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Дата',
                                border: OutlineInputBorder(),
                              ),
                              controller: TextEditingController(
                                text:
                                    '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                              ),
                              readOnly: true,
                              onTap: _selectDate,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Время',
                                border: OutlineInputBorder(),
                              ),
                              controller: TextEditingController(
                                text: _selectedTime.format(context),
                              ),
                              readOnly: true,
                              onTap: _selectTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Удаленная работа'),
                        subtitle:
                            const Text('Заявка может выполняться удаленно'),
                        value: _isRemote,
                        onChanged: (value) {
                          setState(() {
                            _isRemote = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Бюджет и параметры
                EnhancedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Бюджет и параметры',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _budgetController,
                              decoration: const InputDecoration(
                                labelText: 'Бюджет (руб.)',
                                hintText: '10000',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите бюджет';
                                }
                                final budget = double.tryParse(value);
                                if (budget == null || budget <= 0) {
                                  return 'Введите корректный бюджет';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _maxApplicantsController,
                              decoration: const InputDecoration(
                                labelText: 'Макс. откликов',
                                hintText: '10',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите количество откликов';
                                }
                                final count = int.tryParse(value);
                                if (count == null || count <= 0) {
                                  return 'Введите корректное количество';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<RequestPriority>(
                        value: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Приоритет',
                          border: OutlineInputBorder(),
                        ),
                        items: RequestPriority.values.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(priority.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPriority = value ?? RequestPriority.medium;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Теги и навыки
                EnhancedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Теги и навыки',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectTags,
                              icon: const Icon(Icons.tag),
                              label: Text('Теги (${_selectedTags.length})'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectSkills,
                              icon: const Icon(Icons.skills),
                              label: Text('Навыки (${_selectedSkills.length})'),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedTags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: _selectedTags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              onDeleted: () {
                                setState(() {
                                  _selectedTags.remove(tag);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      if (_selectedSkills.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: _selectedSkills.map((skill) {
                            return Chip(
                              label: Text(skill),
                              onDeleted: () {
                                setState(() {
                                  _selectedSkills.remove(skill);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Вложения
                EnhancedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Вложения',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _selectAttachments,
                        icon: const Icon(Icons.attach_file),
                        label: Text('Добавить файлы (${_attachments.length})'),
                      ),
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: _attachments.map((attachment) {
                            return Chip(
                              label: Text(attachment.split('/').last),
                              onDeleted: () {
                                setState(() {
                                  _attachments.remove(attachment);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Кнопка создания
                EnhancedButton(
                  onPressed: _isLoading ? null : _createRequest,
                  text: _isLoading ? 'Создание...' : 'Создать заявку',
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
