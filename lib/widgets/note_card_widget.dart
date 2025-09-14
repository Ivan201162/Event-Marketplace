import 'package:flutter/material.dart';
import '../models/customer_profile_extended.dart';

/// Виджет карточки заметки
class NoteCardWidget extends StatelessWidget {
  final CustomerNote note;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const NoteCardWidget({
    super.key,
    required this.note,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с иконкой закрепления
              Row(
                children: [
                  if (note.isPinned) ...[
                    const Icon(Icons.push_pin, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'pin':
                          onTogglePin();
                          break;
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(
                              note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                              color: note.isPinned ? Colors.grey : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(note.isPinned ? 'Открепить' : 'Закрепить'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Редактировать'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Удалить', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Содержимое заметки
              Text(
                note.content,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Теги
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: note.tags.take(3).map((tag) => Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 12),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
                if (note.tags.length > 3)
                  Text(
                    '+${note.tags.length - 3} ещё',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
              
              const SizedBox(height: 8),
              
              // Информация о дате и связанных объектах
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(note.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  if (note.eventId != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.event,
                      size: 14,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Событие',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                  
                  if (note.specialistId != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.person,
                      size: 14,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Специалист',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
