import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist_profile.dart';
import '../models/specialist_proposal.dart';
import '../providers/auth_providers.dart';
import '../services/specialist_proposal_service.dart';
import '../services/specialist_service.dart';

/// Диалог создания предложения специалистов
class CreateProposalDialog extends ConsumerStatefulWidget {
  const CreateProposalDialog({
    super.key,
    required this.customerId,
    this.customerName,
  });

  final String customerId;
  final String? customerName;

  @override
  ConsumerState<CreateProposalDialog> createState() =>
      _CreateProposalDialogState();
}

class _CreateProposalDialogState extends ConsumerState<CreateProposalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  final SpecialistProposalService _proposalService =
      SpecialistProposalService();
  final SpecialistService _specialistService = SpecialistService();

  final List<SpecialistProfile> _selectedSpecialists = [];
  List<SpecialistProfile> _searchResults = [];
  bool _isSearching = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);

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
                    'Создать предложение',
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
                      // Информация о клиенте
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Для: ${widget.customerName ?? 'Клиент'}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Заголовок
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Заголовок предложения',
                          hintText: 'Например: "Лучшие фотографы для свадьбы"',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите заголовок';
                          }
                          if (value.trim().length < 5) {
                            return 'Заголовок должен содержать минимум 5 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Описание
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          hintText:
                              'Опишите, почему эти специалисты подходят для клиента...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите описание';
                          }
                          if (value.trim().length < 10) {
                            return 'Описание должно содержать минимум 10 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Поиск специалистов
                      Text(
                        'Выберите специалистов',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск специалистов...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults.clear();
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: _searchSpecialists,
                      ),
                      const SizedBox(height: 16),

                      // Результаты поиска
                      if (_isSearching)
                        const Center(child: CircularProgressIndicator())
                      else if (_searchResults.isNotEmpty) ...[
                        Text(
                          'Результаты поиска:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final specialist = _searchResults[index];
                              final isSelected = _selectedSpecialists
                                  .any((s) => s.id == specialist.id);

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: specialist.avatarUrl != null
                                      ? NetworkImage(specialist.avatarUrl!)
                                      : null,
                                  child: specialist.avatarUrl == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(specialist.displayName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (specialist.specialization.isNotEmpty)
                                      Text(specialist.specialization),
                                    if (specialist.rating > 0)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 14,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            specialist.rating
                                                .toStringAsFixed(1),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  onPressed: () =>
                                      _toggleSpecialist(specialist),
                                  icon: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.add_circle_outline,
                                    color: isSelected ? Colors.green : null,
                                  ),
                                ),
                                onTap: () => _toggleSpecialist(specialist),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Выбранные специалисты
                      if (_selectedSpecialists.isNotEmpty) ...[
                        Text(
                          'Выбранные специалисты (${_selectedSpecialists.length}):',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedSpecialists
                              .map(
                                (specialist) => Chip(
                                  label: Text(specialist.displayName),
                                  avatar: CircleAvatar(
                                    radius: 12,
                                    backgroundImage: specialist.avatarUrl !=
                                            null
                                        ? NetworkImage(specialist.avatarUrl!)
                                        : null,
                                    child: specialist.avatarUrl == null
                                        ? const Icon(Icons.person, size: 12)
                                        : null,
                                  ),
                                  onDeleted: () =>
                                      _removeSpecialist(specialist),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
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
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitProposal,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Создать предложение'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchSpecialists(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _specialistService.searchSpecialists(
        query: query.trim(),
        limit: 10,
      );

      // Исключить уже выбранных специалистов
      final filteredResults = results
          .where(
            (specialist) => !_selectedSpecialists
                .any((selected) => selected.id == specialist.id),
          )
          .toList();

      setState(() {
        _searchResults = filteredResults;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка поиска: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _toggleSpecialist(SpecialistProfile specialist) {
    setState(() {
      if (_selectedSpecialists.any((s) => s.id == specialist.id)) {
        _selectedSpecialists.removeWhere((s) => s.id == specialist.id);
      } else {
        _selectedSpecialists.add(specialist);
      }
    });
  }

  void _removeSpecialist(SpecialistProfile specialist) {
    setState(() {
      _selectedSpecialists.removeWhere((s) => s.id == specialist.id);
    });
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSpecialists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы одного специалиста'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);

    setState(() {
      _isSubmitting = true;
    });

    try {
      final proposal = CreateSpecialistProposal(
        organizerId: currentUser.uid,
        customerId: widget.customerId,
        specialistIds: _selectedSpecialists.map((s) => s.id).toList(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        organizerName: currentUser.displayName,
        organizerAvatar: currentUser.photoURL,
        customerName: widget.customerName,
      );

      await _proposalService.createProposal(proposal);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Предложение создано успешно!'),
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
