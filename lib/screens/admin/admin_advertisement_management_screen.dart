import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/advertisement.dart';
import '../../services/marketing_admin_service.dart';

class AdminAdvertisementManagementScreen extends StatefulWidget {
  const AdminAdvertisementManagementScreen({super.key});

  @override
  State<AdminAdvertisementManagementScreen> createState() =>
      _AdminAdvertisementManagementScreenState();
}

class _AdminAdvertisementManagementScreenState
    extends State<AdminAdvertisementManagementScreen> {
  final MarketingAdminService _marketingService = MarketingAdminService();
  final Uuid _uuid = const Uuid();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contentUrlController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  AdvertisementType _selectedType = AdvertisementType.banner;
  AdvertisementStatus _selectedStatus = AdvertisementStatus.pending;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentUrlController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление рекламой'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateAdDialog())
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('advertisements')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final ads = snapshot.data?.docs ?? [];
          if (ads.isEmpty) {
            return const Center(child: Text('Нет рекламных объявлений'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final adData = ads[index].data() as Map<String, dynamic>;
              final ad = Advertisement.fromMap(adData);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getAdColor(ad.status),
                    child: Icon(_getAdIcon(ad.type), color: Colors.white),
                  ),
                  title: Text(
                    ad.title ?? 'Без названия',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Тип: ${_getAdTypeName(ad.type)}'),
                      Text('Статус: ${_getAdStatusName(ad.status)}'),
                      Text('Бюджет: ${ad.budget}₽'),
                      Text('Показы: ${ad.impressions}'),
                      Text('Клики: ${ad.clicks}'),
                      if (ad.ctr > 0)
                        Text('CTR: ${ad.ctr.toStringAsFixed(2)}%'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handleAdAction(value, ad),
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
                        value: 'approve',
                        child: ListTile(
                          leading: Icon(Icons.check, color: Colors.green),
                          title: Text('Одобрить',
                              style: TextStyle(color: Colors.green)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reject',
                        child: ListTile(
                          leading: Icon(Icons.close, color: Colors.red),
                          title: Text('Отклонить',
                              style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'pause',
                        child: ListTile(
                          leading: Icon(Icons.pause, color: Colors.orange),
                          title: Text('Приостановить',
                              style: TextStyle(color: Colors.orange)),
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

  void _showCreateAdDialog() {
    _titleController.clear();
    _descriptionController.clear();
    _contentUrlController.clear();
    _budgetController.clear();
    _selectedType = AdvertisementType.banner;
    _selectedStatus = AdvertisementStatus.pending;
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать рекламное объявление'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Заголовок',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL контента',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Бюджет (₽)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AdvertisementType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип объявления',
                  border: OutlineInputBorder(),
                ),
                items: AdvertisementType.values.map((type) {
                  return DropdownMenuItem(
                      value: type, child: Text(_getAdTypeName(type)));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AdvertisementStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  border: OutlineInputBorder(),
                ),
                items: AdvertisementStatus.values.map((status) {
                  return DropdownMenuItem(
                      value: status, child: Text(_getAdStatusName(status)));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Дата начала'),
                subtitle: Text(
                    '${_startDate.day}.${_startDate.month}.${_startDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
              ),
              ListTile(
                title: const Text('Дата окончания'),
                subtitle:
                    Text('${_endDate.day}.${_endDate.month}.${_endDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(onPressed: _createAd, child: const Text('Создать')),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _createAd() async {
    if (_titleController.text.isEmpty || _budgetController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          const SnackBar(content: Text('Заполните все обязательные поля')));
      return;
    }

    try {
      final ad = Advertisement(
        id: _uuid.v4(),
        userId: 'admin_123', // Mock admin user
        type: _selectedType,
        contentUrl: _contentUrlController.text,
        startDate: _startDate,
        endDate: _endDate,
        status: _selectedStatus,
        title: _titleController.text,
        description: _descriptionController.text,
        targetAudience: {},
        budget: double.parse(_budgetController.text),
        category: 'admin_created',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('advertisements')
          .doc(ad.id)
          .set(ad.toMap());

      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(
          content: Text('Рекламное объявление создано успешно')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _handleAdAction(String action, Advertisement ad) {
    switch (action) {
      case 'edit':
        _showEditAdDialog(ad);
        break;
      case 'approve':
        _updateAdStatus(ad, AdvertisementStatus.active);
        break;
      case 'reject':
        _updateAdStatus(ad, AdvertisementStatus.rejected);
        break;
      case 'pause':
        _updateAdStatus(ad, AdvertisementStatus.paused);
        break;
      case 'delete':
        _deleteAd(ad);
        break;
    }
  }

  void _showEditAdDialog(Advertisement ad) {
    _titleController.text = ad.title ?? '';
    _descriptionController.text = ad.description ?? '';
    _contentUrlController.text = ad.contentUrl;
    _budgetController.text = ad.budget.toString();
    _selectedType = ad.type;
    _selectedStatus = ad.status;
    _startDate = ad.startDate;
    _endDate = ad.endDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать рекламное объявление'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Заголовок',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL контента',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Бюджет (₽)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AdvertisementType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип объявления',
                  border: OutlineInputBorder(),
                ),
                items: AdvertisementType.values.map((type) {
                  return DropdownMenuItem(
                      value: type, child: Text(_getAdTypeName(type)));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AdvertisementStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  border: OutlineInputBorder(),
                ),
                items: AdvertisementStatus.values.map((status) {
                  return DropdownMenuItem(
                      value: status, child: Text(_getAdStatusName(status)));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Дата начала'),
                subtitle: Text(
                    '${_startDate.day}.${_startDate.month}.${_startDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
              ),
              ListTile(
                title: const Text('Дата окончания'),
                subtitle:
                    Text('${_endDate.day}.${_endDate.month}.${_endDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
              onPressed: () => _updateAd(ad), child: const Text('Сохранить')),
        ],
      ),
    );
  }

  Future<void> _updateAd(Advertisement ad) async {
    try {
      final updates = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'contentUrl': _contentUrlController.text,
        'budget': double.parse(_budgetController.text),
        'type': _selectedType.name,
        'status': _selectedStatus.name,
        'startDate': _startDate,
        'endDate': _endDate,
        'updatedAt': DateTime.now(),
      };

      await FirebaseFirestore.instance
          .collection('advertisements')
          .doc(ad.id)
          .update(updates);

      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(
          content: Text('Рекламное объявление обновлено успешно')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _updateAdStatus(
      Advertisement ad, AdvertisementStatus newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('advertisements')
          .doc(ad.id)
          .update({
        'status': newStatus.name,
        'updatedAt': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Статус объявления изменен на ${_getAdStatusName(newStatus)}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _deleteAd(Advertisement ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить рекламное объявление'),
        content:
            Text('Вы уверены, что хотите удалить объявление "${ad.title}"?'),
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
            .collection('advertisements')
            .doc(ad.id)
            .delete();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Рекламное объявление удалено')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  Color _getAdColor(AdvertisementStatus status) {
    switch (status) {
      case AdvertisementStatus.pending:
        return Colors.orange;
      case AdvertisementStatus.active:
        return Colors.green;
      case AdvertisementStatus.paused:
        return Colors.yellow;
      case AdvertisementStatus.rejected:
        return Colors.red;
      case AdvertisementStatus.completed:
        return Colors.blue;
      case AdvertisementStatus.expired:
        return Colors.grey;
    }
  }

  IconData _getAdIcon(AdvertisementType type) {
    switch (type) {
      case AdvertisementType.banner:
        return Icons.image;
      case AdvertisementType.video:
        return Icons.play_circle;
      case AdvertisementType.native:
        return Icons.article;
      case AdvertisementType.interstitial:
        return Icons.fullscreen;
    }
  }

  String _getAdTypeName(AdvertisementType type) {
    switch (type) {
      case AdvertisementType.banner:
        return 'Баннер';
      case AdvertisementType.video:
        return 'Видео';
      case AdvertisementType.native:
        return 'Нативная';
      case AdvertisementType.interstitial:
        return 'Интерстициальная';
    }
  }

  String _getAdStatusName(AdvertisementStatus status) {
    switch (status) {
      case AdvertisementStatus.pending:
        return 'На рассмотрении';
      case AdvertisementStatus.active:
        return 'Активна';
      case AdvertisementStatus.paused:
        return 'Приостановлена';
      case AdvertisementStatus.rejected:
        return 'Отклонена';
      case AdvertisementStatus.completed:
        return 'Завершена';
      case AdvertisementStatus.expired:
        return 'Истекла';
    }
  }
}
