import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/admin_models.dart';
import '../../services/marketing_admin_service.dart';

class AdminPromotionsManagementScreen extends StatefulWidget {
  const AdminPromotionsManagementScreen({super.key});

  @override
  State<AdminPromotionsManagementScreen> createState() => _AdminPromotionsManagementScreenState();
}

class _AdminPromotionsManagementScreen extends State<AdminPromotionsManagementScreen> {
  final MarketingAdminService _marketingService = MarketingAdminService();
  final Uuid _uuid = const Uuid();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  MarketingCampaignType _selectedType = MarketingCampaignType.promotion;
  MarketingCampaignStatus _selectedStatus = MarketingCampaignStatus.draft;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление акциями'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreatePromotionDialog()),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('marketing_campaigns')
            .where('type', isEqualTo: 'promotion')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final campaigns = snapshot.data?.docs ?? [];
          if (campaigns.isEmpty) {
            return const Center(child: Text('Нет промо-кампаний'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaignData = campaigns[index].data() as Map<String, dynamic>;
              final campaign = MarketingCampaign.fromMap(campaignData);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCampaignColor(campaign.status),
                    child: Icon(_getCampaignIcon(campaign.type), color: Colors.white),
                  ),
                  title: Text(campaign.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Тип: ${_getCampaignTypeName(campaign.type)}'),
                      Text('Статус: ${_getCampaignStatusName(campaign.status)}'),
                      if (campaign.budget != null) Text('Бюджет: ${campaign.budget}₽'),
                      Text('Начало: ${_formatDate(campaign.startDate)}'),
                      Text('Окончание: ${_formatDate(campaign.endDate)}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handleCampaignAction(value, campaign),
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
                        value: 'activate',
                        child: ListTile(
                          leading: Icon(Icons.play_arrow, color: Colors.green),
                          title: Text('Активировать', style: TextStyle(color: Colors.green)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'pause',
                        child: ListTile(
                          leading: Icon(Icons.pause, color: Colors.orange),
                          title: Text('Приостановить', style: TextStyle(color: Colors.orange)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Удалить', style: TextStyle(color: Colors.red)),
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

  void _showCreatePromotionDialog() {
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _selectedType = MarketingCampaignType.promotion;
    _selectedStatus = MarketingCampaignStatus.draft;
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать промо-кампанию'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название кампании',
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
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Бюджет (₽)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MarketingCampaignType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип кампании',
                  border: OutlineInputBorder(),
                ),
                items: MarketingCampaignType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(_getCampaignTypeName(type)));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MarketingCampaignStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  border: OutlineInputBorder(),
                ),
                items: MarketingCampaignStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_getCampaignStatusName(status)),
                  );
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
                subtitle: Text('${_startDate.day}.${_startDate.month}.${_startDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
              ),
              ListTile(
                title: const Text('Дата окончания'),
                subtitle: Text('${_endDate.day}.${_endDate.month}.${_endDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(onPressed: _createPromotion, child: const Text('Создать')),
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

  Future<void> _createPromotion() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заполните название кампании')));
      return;
    }

    try {
      final campaign = MarketingCampaign(
        id: _uuid.v4(),
        name: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        budget: _priceController.text.isNotEmpty ? double.parse(_priceController.text) : null,
        createdBy: 'admin_123', // Mock admin user
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock admin data for testing
      const adminId = 'admin_123';
      const adminEmail = 'admin@example.com';

      final success = await _marketingService.createMarketingCampaign(
        campaign: campaign,
        adminId: adminId,
        adminEmail: adminEmail,
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Промо-кампания создана успешно')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка создания промо-кампании')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _handleCampaignAction(String action, MarketingCampaign campaign) {
    switch (action) {
      case 'edit':
        _showEditCampaignDialog(campaign);
        break;
      case 'activate':
        _toggleCampaignStatus(campaign, MarketingCampaignStatus.active);
        break;
      case 'pause':
        _toggleCampaignStatus(campaign, MarketingCampaignStatus.paused);
        break;
      case 'delete':
        _deleteCampaign(campaign);
        break;
    }
  }

  void _showEditCampaignDialog(MarketingCampaign campaign) {
    _titleController.text = campaign.name;
    _descriptionController.text = campaign.description;
    _priceController.text = campaign.budget?.toString() ?? '';
    _selectedType = campaign.type;
    _selectedStatus = campaign.status;
    _startDate = campaign.startDate;
    _endDate = campaign.endDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать промо-кампанию'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название кампании',
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
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Бюджет (₽)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MarketingCampaignType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип кампании',
                  border: OutlineInputBorder(),
                ),
                items: MarketingCampaignType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(_getCampaignTypeName(type)));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MarketingCampaignStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  border: OutlineInputBorder(),
                ),
                items: MarketingCampaignStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_getCampaignStatusName(status)),
                  );
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
                subtitle: Text('${_startDate.day}.${_startDate.month}.${_startDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
              ),
              ListTile(
                title: const Text('Дата окончания'),
                subtitle: Text('${_endDate.day}.${_endDate.month}.${_endDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => _updateCampaign(campaign),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCampaign(MarketingCampaign campaign) async {
    try {
      final updates = {
        'name': _titleController.text,
        'description': _descriptionController.text,
        'type': _selectedType.name,
        'status': _selectedStatus.name,
        'startDate': _startDate,
        'endDate': _endDate,
        'budget': _priceController.text.isNotEmpty ? double.parse(_priceController.text) : null,
        'updatedAt': DateTime.now(),
      };

      // Mock admin data for testing
      const adminId = 'admin_123';
      const adminEmail = 'admin@example.com';

      final success = await _marketingService.updateMarketingCampaign(
        campaignId: campaign.id,
        updates: updates,
        adminId: adminId,
        adminEmail: adminEmail,
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Промо-кампания обновлена успешно')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка обновления промо-кампании')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _toggleCampaignStatus(
    MarketingCampaign campaign,
    MarketingCampaignStatus newStatus,
  ) async {
    try {
      // Mock admin data for testing
      const adminId = 'admin_123';
      const adminEmail = 'admin@example.com';

      final success = await _marketingService.toggleCampaignStatus(
        campaignId: campaign.id,
        newStatus: newStatus,
        adminId: adminId,
        adminEmail: adminEmail,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Статус кампании изменен на ${_getCampaignStatusName(newStatus)}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка изменения статуса кампании')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _deleteCampaign(MarketingCampaign campaign) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить промо-кампанию'),
        content: Text('Вы уверены, что хотите удалить кампанию "${campaign.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
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
            .collection('marketing_campaigns')
            .doc(campaign.id)
            .delete();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Промо-кампания удалена')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  Color _getCampaignColor(MarketingCampaignStatus status) {
    switch (status) {
      case MarketingCampaignStatus.draft:
        return Colors.grey;
      case MarketingCampaignStatus.scheduled:
        return Colors.blue;
      case MarketingCampaignStatus.active:
        return Colors.green;
      case MarketingCampaignStatus.paused:
        return Colors.orange;
      case MarketingCampaignStatus.completed:
        return Colors.purple;
      case MarketingCampaignStatus.cancelled:
        return Colors.red;
      case MarketingCampaignStatus.expired:
        return Colors.brown;
    }
  }

  IconData _getCampaignIcon(MarketingCampaignType type) {
    switch (type) {
      case MarketingCampaignType.promotion:
        return Icons.local_offer;
      case MarketingCampaignType.advertisement:
        return Icons.campaign;
      case MarketingCampaignType.referral:
        return Icons.group_add;
      case MarketingCampaignType.subscription:
        return Icons.subscriptions;
      case MarketingCampaignType.notification:
        return Icons.notifications;
      case MarketingCampaignType.email:
        return Icons.email;
      case MarketingCampaignType.push:
        return Icons.push_pin;
      case MarketingCampaignType.seasonal:
        return Icons.seasonal;
      case MarketingCampaignType.abTest:
        return Icons.science;
    }
  }

  String _getCampaignTypeName(MarketingCampaignType type) {
    switch (type) {
      case MarketingCampaignType.promotion:
        return 'Продвижение';
      case MarketingCampaignType.advertisement:
        return 'Реклама';
      case MarketingCampaignType.referral:
        return 'Реферальная';
      case MarketingCampaignType.subscription:
        return 'Подписка';
      case MarketingCampaignType.notification:
        return 'Уведомления';
      case MarketingCampaignType.email:
        return 'Email';
      case MarketingCampaignType.push:
        return 'Push';
      case MarketingCampaignType.seasonal:
        return 'Сезонная';
      case MarketingCampaignType.abTest:
        return 'A/B тест';
    }
  }

  String _getCampaignStatusName(MarketingCampaignStatus status) {
    switch (status) {
      case MarketingCampaignStatus.draft:
        return 'Черновик';
      case MarketingCampaignStatus.scheduled:
        return 'Запланирована';
      case MarketingCampaignStatus.active:
        return 'Активна';
      case MarketingCampaignStatus.paused:
        return 'Приостановлена';
      case MarketingCampaignStatus.completed:
        return 'Завершена';
      case MarketingCampaignStatus.cancelled:
        return 'Отменена';
      case MarketingCampaignStatus.expired:
        return 'Истекла';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
