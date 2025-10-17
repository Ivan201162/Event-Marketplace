import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../models/app_user.dart';
import '../models/photo_studio.dart';
import '../providers/auth_providers.dart';
import '../services/photographer_studio_link_service.dart';

/// Диалог предложения фотостудии
class SuggestStudioDialog extends ConsumerStatefulWidget {
  const SuggestStudioDialog({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  ConsumerState<SuggestStudioDialog> createState() => _SuggestStudioDialogState();
}

class _SuggestStudioDialogState extends ConsumerState<SuggestStudioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();

  final PhotographerStudioLinkService _linkService = PhotographerStudioLinkService();
  // final PhotoStudioService _photoStudioService = PhotoStudioService(); // Unused field removed

  List<PhotoStudio> _availableStudios = [];
  PhotoStudio? _selectedStudio;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableStudios();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableStudios() async {
    final currentUserAsync = ref.read(currentUserProvider);

    if (currentUserAsync is! AsyncData) {
      return;
    }

    final currentUser = currentUserAsync.value;
    if (currentUser == null) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final studios = await _linkService.getRecommendedStudios(currentUser.uid);

      if (mounted) {
        setState(() {
          _availableStudios = studios;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки фотостудий: $e'),
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
    final theme = Theme.of(context);
    // final currentUser = ref.watch(currentUserProvider); // Unused variable removed

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Предложить фотостудию',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Форма
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Выбор фотостудии
                      Text(
                        'Выберите фотостудию',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_availableStudios.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.photo_camera,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Нет доступных фотостудий',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Сначала создайте связку с фотостудией',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: _availableStudios.length,
                            itemBuilder: (context, index) {
                              final studio = _availableStudios[index];
                              // final isSelected = _selectedStudio?.id == studio.id; // Unused variable removed

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: studio.avatarUrl != null
                                      ? NetworkImage(studio.avatarUrl!)
                                      : null,
                                  child: studio.avatarUrl == null
                                      ? const Icon(Icons.photo_camera)
                                      : null,
                                ),
                                title: Text(studio.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(studio.address),
                                    if (studio.hourlyRate != null)
                                      Text(
                                        studio.getFormattedHourlyRate(),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Radio<PhotoStudio>(
                                  value: studio,
                                  // groupValue: _selectedStudio,
                                  // onChanged: (value) {
                                  //   setState(() {
                                  //     _selectedStudio = value;
                                  //   });
                                  // },
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedStudio = studio;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Предлагаемая цена
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Предлагаемая цена (₽)',
                          hintText: 'Введите цену за фотосессию',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Введите корректную цену';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Сообщение
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Сообщение клиенту',
                          hintText: 'Объясните, почему эта фотостудия подходит для заказа...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите сообщение для клиента';
                          }
                          if (value.trim().length < 10) {
                            return 'Сообщение должно содержать минимум 10 символов';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _selectedStudio == null ? null : _submitSuggestion,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Предложить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitSuggestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStudio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите фотостудию'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentUserAsync = ref.read(currentUserProvider);

    if (currentUserAsync is! AsyncData) {
      return;
    }

    final currentUser = currentUserAsync.value;
    if (currentUser == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final suggestedPrice =
          _priceController.text.isNotEmpty ? double.tryParse(_priceController.text) : null;

      await _linkService.createStudioSuggestion(
        bookingId: widget.bookingId,
        photographerId: currentUser.uid,
        studioId: _selectedStudio!.id,
        notes: _notesController.text.trim(),
        suggestedPrice: suggestedPrice,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Предложение фотостудии отправлено!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
