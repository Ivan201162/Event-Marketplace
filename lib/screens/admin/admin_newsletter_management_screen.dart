import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/admin_models.dart';
import '../../services/marketing_admin_service.dart';

class AdminNewsletterManagementScreen extends StatefulWidget {
  const AdminNewsletterManagementScreen({super.key});

  @override
  State<AdminNewsletterManagementScreen> createState() =>
      _AdminNewsletterManagementScreenState();
}

class _AdminNewsletterManagementScreenState
    extends State<AdminNewsletterManagementScreen> {
  final MarketingAdminService _marketingService = MarketingAdminService();
  final Uuid _uuid = const Uuid();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  NewsletterType _selectedType = NewsletterType.email;
  NewsletterStatus _selectedStatus = NewsletterStatus.draft;
  String? _selectedSegment;
  DateTime? _scheduledAt;

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление рассылками'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateNewsletterDialog()),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('marketing_newsletters')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final newsletters = snapshot.data?.docs ?? [];
          if (newsletters.isEmpty) {
            return const Center(child: Text('Нет рассылок'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: newsletters.length,
            itemBuilder: (context, index) {
              final newsletterData =
                  newsletters[index].data() as Map<String, dynamic>;
              final newsletter = MarketingNewsletter.fromMap(newsletterData);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getNewsletterColor(newsletter.status),
                    child: Icon(_getNewsletterIcon(newsletter.type),
                        color: Colors.white),
                  ),
                  title: Text(
                    newsletter.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Тип: ${_getNewsletterTypeName(newsletter.type)}'),
                      Text(
                          'Статус: ${_getNewsletterStatusName(newsletter.status)}'),
                      if (newsletter.totalRecipients != null)
                        Text('Получателей: ${newsletter.totalRecipients}'),
                      if (newsletter.deliveredCount != null)
                        Text('Доставлено: ${newsletter.deliveredCount}'),
                      if (newsletter.openedCount != null)
                        Text('Открыто: ${newsletter.openedCount}'),
                      if (newsletter.clickedCount != null)
                        Text('Кликов: ${newsletter.clickedCount}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleNewsletterAction(value, newsletter),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Редактировать'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'send',
                        child: ListTile(
                          leading: Icon(Icons.send, color: Colors.green),
                          title: Text('Отправить',
                              style: TextStyle(color: Colors.green)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'schedule',
                        child: ListTile(
                          leading: Icon(Icons.schedule, color: Colors.blue),
                          title: Text('Запланировать',
                              style: TextStyle(color: Colors.blue)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'cancel',
                        child: ListTile(
                          leading: Icon(Icons.cancel, color: Colors.red),
                          title: Text('Отменить',
                              style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Удалить',
                              style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateNewsletterDialog() {
    _titleController.clear();
    _subjectController.clear();
    _contentController.clear();
    _selectedType = NewsletterType.email;
    _selectedStatus = NewsletterStatus.draft;
    _selectedSegment = null;
    _scheduledAt = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать рассылку'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название рассылки',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Тема письма',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Содержание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<NewsletterType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип рассылки',
                  border: OutlineInputBorder(),
                ),
                items: NewsletterType.values.map((type) {
                  return DropdownMenuItem(
                      value: type, child: Text(_getNewsletterTypeName(type)));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedSegment,
                decoration: const InputDecoration(
                  labelText: 'Сегмент получателей',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'all', child: Text('Все пользователи')),
                  DropdownMenuItem(
                      value: 'active', child: Text('Активные пользователи')),
                  DropdownMenuItem(
                      value: 'premium', child: Text('Premium пользователи')),
                  DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Неактивные пользователи')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSegment = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Запланировать отправку'),
                subtitle: Text(
                  _scheduledAt != null
                      ? '${_scheduledAt!.day}.${_scheduledAt!.month}.${_scheduledAt!.year} ${_scheduledAt!.hour}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'
                      : 'Немедленно',
                ),
                trailing: const Icon(Icons.schedule),
                onTap: () => _selectScheduleTime(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
              onPressed: _createNewsletter, child: const Text('Создать')),
        ],
      ),
    );
  }

  Future<void> _selectScheduleTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());

      if (time != null) {
        setState(() {
          _scheduledAt =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _createNewsletter() async {
    if (_titleController.text.isEmpty ||
        _subjectController.text.isEmpty ||
        _contentController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          const SnackBar(content: Text('Заполните все обязательные поля')));
      return;
    }

    try {
      final newsletter = MarketingNewsletter(
        id: _uuid.v4(),
        title: _titleController.text,
        subject: _subjectController.text,
        content: _contentController.text,
        type: _selectedType,
        status: _selectedStatus,
        targetSegment: _selectedSegment,
        scheduledAt: _scheduledAt,
        createdBy: 'admin_123', // Mock admin user
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock admin data for testing
      const adminId = 'admin_123';
      const adminEmail = 'admin@example.com';

      final success = await _marketingService.createNewsletter(
        newsletter: newsletter,
        adminId: adminId,
        adminEmail: adminEmail,
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Рассылка создана успешно')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Ошибка создания рассылки')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _handleNewsletterAction(String action, MarketingNewsletter newsletter) {
    switch (action) {
      case 'edit':
        _showEditNewsletterDialog(newsletter);
        break;
      case 'send':
        _sendNewsletter(newsletter);
        break;
      case 'schedule':
        _scheduleNewsletter(newsletter);
        break;
      case 'cancel':
        _cancelNewsletter(newsletter);
        break;
      case 'delete':
        _deleteNewsletter(newsletter);
        break;
    }
  }

  void _showEditNewsletterDialog(MarketingNewsletter newsletter) {
    _titleController.text = newsletter.title;
    _subjectController.text = newsletter.subject;
    _contentController.text = newsletter.content;
    _selectedType = newsletter.type;
    _selectedStatus = newsletter.status;
    _selectedSegment = newsletter.targetSegment;
    _scheduledAt = newsletter.scheduledAt;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать рассылку'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название рассылки',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Тема письма',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Содержание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<NewsletterType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип рассылки',
                  border: OutlineInputBorder(),
                ),
                items: NewsletterType.values.map((type) {
                  return DropdownMenuItem(
                      value: type, child: Text(_getNewsletterTypeName(type)));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedSegment,
                decoration: const InputDecoration(
                  labelText: 'Сегмент получателей',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'all', child: Text('Все пользователи')),
                  DropdownMenuItem(
                      value: 'active', child: Text('Активные пользователи')),
                  DropdownMenuItem(
                      value: 'premium', child: Text('Premium пользователи')),
                  DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Неактивные пользователи')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSegment = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => _updateNewsletter(newsletter),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateNewsletter(MarketingNewsletter newsletter) async {
    try {
      final updates = {
        'title': _titleController.text,
        'subject': _subjectController.text,
        'content': _contentController.text,
        'type': _selectedType.name,
        'status': _selectedStatus.name,
        'targetSegment': _selectedSegment,
        'scheduledAt': _scheduledAt,
        'updatedAt': DateTime.now(),
      };

      await FirebaseFirestore.instance
          .collection('marketing_newsletters')
          .doc(newsletter.id)
          .update(updates);

      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          const SnackBar(content: Text('Рассылка обновлена успешно')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _sendNewsletter(MarketingNewsletter newsletter) async {
    try {
      // Mock admin data for testing
      const adminId = 'admin_123';
      const adminEmail = 'admin@example.com';

      final success = await _marketingService.sendNewsletter(
        newsletterId: newsletter.id,
        adminId: adminId,
        adminEmail: adminEmail,
      );

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Рассылка отправлена')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Ошибка отправки рассылки')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _scheduleNewsletter(MarketingNewsletter newsletter) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());

      if (time != null) {
        try {
          final scheduledAt =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);

          await FirebaseFirestore.instance
              .collection('marketing_newsletters')
              .doc(newsletter.id)
              .update({
            'scheduledAt': scheduledAt,
            'status': NewsletterStatus.scheduled.name,
            'updatedAt': DateTime.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Рассылка запланирована на ${scheduledAt.day}.${scheduledAt.month}.${scheduledAt.year} ${scheduledAt.hour}:${scheduledAt.minute.toString().padLeft(2, '0')}',
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        }
      }
    }
  }

  Future<void> _cancelNewsletter(MarketingNewsletter newsletter) async {
    try {
      await FirebaseFirestore.instance
          .collection('marketing_newsletters')
          .doc(newsletter.id)
          .update({
        'status': NewsletterStatus.cancelled.name,
        'updatedAt': DateTime.now()
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Рассылка отменена')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _deleteNewsletter(MarketingNewsletter newsletter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить рассылку'),
        content: Text(
            'Вы уверены, что хотите удалить рассылку "${newsletter.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('marketing_newsletters')
            .doc(newsletter.id)
            .delete();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Рассылка удалена')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  Color _getNewsletterColor(NewsletterStatus status) {
    switch (status) {
      case NewsletterStatus.draft:
        return Colors.grey;
      case NewsletterStatus.scheduled:
        return Colors.blue;
      case NewsletterStatus.sending:
        return Colors.orange;
      case NewsletterStatus.sent:
        return Colors.green;
      case NewsletterStatus.failed:
        return Colors.red;
      case NewsletterStatus.cancelled:
        return Colors.brown;
    }
  }

  IconData _getNewsletterIcon(NewsletterType type) {
    switch (type) {
      case NewsletterType.email:
        return Icons.email;
      case NewsletterType.push:
        return Icons.push_pin;
      case NewsletterType.sms:
        return Icons.sms;
      case NewsletterType.inApp:
        return Icons.notifications;
    }
  }

  String _getNewsletterTypeName(NewsletterType type) {
    switch (type) {
      case NewsletterType.email:
        return 'Email';
      case NewsletterType.push:
        return 'Push';
      case NewsletterType.sms:
        return 'SMS';
      case NewsletterType.inApp:
        return 'In-App';
    }
  }

  String _getNewsletterStatusName(NewsletterStatus status) {
    switch (status) {
      case NewsletterStatus.draft:
        return 'Черновик';
      case NewsletterStatus.scheduled:
        return 'Запланирована';
      case NewsletterStatus.sending:
        return 'Отправляется';
      case NewsletterStatus.sent:
        return 'Отправлена';
      case NewsletterStatus.failed:
        return 'Ошибка';
      case NewsletterStatus.cancelled:
        return 'Отменена';
    }
  }
}
