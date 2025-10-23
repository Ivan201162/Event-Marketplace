import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/idea.dart';
import '../services/idea_service.dart';
import '../widgets/idea_collection_widget.dart';
import 'create_idea_collection_screen.dart';

/// Экран коллекций идей
class IdeaCollectionsScreen extends ConsumerStatefulWidget {
  const IdeaCollectionsScreen({super.key, required this.userId});
  final String userId;

  @override
  ConsumerState<IdeaCollectionsScreen> createState() =>
      _IdeaCollectionsScreenState();
}

class _IdeaCollectionsScreenState extends ConsumerState<IdeaCollectionsScreen> {
  final IdeaService _ideaService = IdeaService();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Мои коллекции'),
          actions: [
            IconButton(
                icon: const Icon(Icons.add), onPressed: _createCollection)
          ],
        ),
        body: StreamBuilder<List<IdeaCollection>>(
          stream: _ideaService.getUserCollections(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Ошибка: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Повторить')),
                  ],
                ),
              );
            }

            final collections = snapshot.data ?? [];
            if (collections.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: collections.length,
              itemBuilder: (context, index) {
                final collection = collections[index];
                return IdeaCollectionWidget(
                  collection: collection,
                  onTap: () => _showCollectionDetail(collection),
                  onEdit: () => _editCollection(collection),
                  onDelete: () => _deleteCollection(collection),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createCollection,
          child: const Icon(Icons.add),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.collections_bookmark,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Нет коллекций',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Создайте коллекцию для организации ваших идей',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createCollection,
              icon: const Icon(Icons.add),
              label: const Text('Создать коллекцию'),
            ),
          ],
        ),
      );

  void _createCollection() {
    Navigator.of(context)
        .push(
      MaterialPageRoute<bool>(
        builder: (context) => CreateIdeaCollectionScreen(userId: widget.userId),
      ),
    )
        .then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showCollectionDetail(IdeaCollection collection) {
    // TODO(developer): Реализовать экран детального просмотра коллекции
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Коллекция: ${collection.name}')));
  }

  void _editCollection(IdeaCollection collection) {
    // TODO(developer): Реализовать редактирование коллекции
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text('Редактирование: ${collection.name}')));
  }

  void _deleteCollection(IdeaCollection collection) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить коллекцию'),
        content: Text(
            'Вы уверены, что хотите удалить коллекцию "${collection.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO(developer): Реализовать удаление коллекции
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(
                  content: Text('Коллекция "${collection.name}" удалена')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

/// Экран создания коллекции идей
class CreateIdeaCollectionScreen extends ConsumerStatefulWidget {
  const CreateIdeaCollectionScreen({super.key, required this.userId});
  final String userId;

  @override
  ConsumerState<CreateIdeaCollectionScreen> createState() =>
      _CreateIdeaCollectionScreenState();
}

class _CreateIdeaCollectionScreenState
    extends ConsumerState<CreateIdeaCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final IdeaService _ideaService = IdeaService();

  bool _isPublic = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Создать коллекцию'),
          actions: [
            TextButton(
                onPressed: _isLoading ? null : _saveCollection,
                child: const Text('Сохранить')),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
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

                        // Название
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Название коллекции *',
                            border: OutlineInputBorder(),
                            hintText: 'Введите название коллекции',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Пожалуйста, введите название коллекции';
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
                            border: OutlineInputBorder(),
                            hintText: 'Опишите коллекцию',
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Настройки
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Настройки',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Публичная коллекция
                        SwitchListTile(
                          title: const Text('Публичная коллекция'),
                          subtitle: const Text(
                              'Коллекция будет видна всем пользователям'),
                          value: _isPublic,
                          onChanged: (value) {
                            setState(() {
                              _isPublic = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Кнопка сохранения
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveCollection,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Создать коллекцию'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _saveCollection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final collectionId = await _ideaService.createIdeaCollection(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        userId: widget.userId,
      );

      if (collectionId != null) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Коллекция успешно создана'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ошибка создания коллекции'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
