import 'package:flutter/material.dart';

/// Контент профиля (посты, идеи, заявки)
class ProfileContent extends StatelessWidget {

  const ProfileContent({
    required this.type, required this.userId, super.key,
  });
  final String type;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _getItemCount(),
      itemBuilder: _buildContentItem,
    );
  }

  int _getItemCount() {
    switch (type) {
      case 'posts':
        return 10; // Заглушка
      case 'ideas':
        return 8; // Заглушка
      case 'requests':
        return 5; // Заглушка
      default:
        return 0;
    }
  }

  Widget _buildContentItem(BuildContext context, int index) {
    switch (type) {
      case 'posts':
        return _PostItem(index: index);
      case 'ideas':
        return _IdeaItem(index: index);
      case 'requests':
        return _RequestItem(index: index);
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Элемент поста
class _PostItem extends StatelessWidget {

  const _PostItem({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${index + 1}'),
        ),
        title: Text('Пост ${index + 1}'),
        subtitle: const Text('Описание поста...'),
        trailing: const Icon(Icons.more_vert),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Открытие поста ${index + 1}')),
          );
        },
      ),
    );
  }
}

/// Элемент идеи
class _IdeaItem extends StatelessWidget {

  const _IdeaItem({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${index + 1}'),
        ),
        title: Text('Идея ${index + 1}'),
        subtitle: const Text('Описание идеи...'),
        trailing: const Icon(Icons.more_vert),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Открытие идеи ${index + 1}')),
          );
        },
      ),
    );
  }
}

/// Элемент заявки
class _RequestItem extends StatelessWidget {

  const _RequestItem({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${index + 1}'),
        ),
        title: Text('Заявка ${index + 1}'),
        subtitle: const Text('Описание заявки...'),
        trailing: const Icon(Icons.more_vert),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Открытие заявки ${index + 1}')),
          );
        },
      ),
    );
  }
}
