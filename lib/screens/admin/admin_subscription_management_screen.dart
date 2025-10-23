import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/subscription_plan.dart';
import '../../services/marketing_admin_service.dart';

class AdminSubscriptionManagementScreen extends StatefulWidget {
  const AdminSubscriptionManagementScreen({super.key});

  @override
  State<AdminSubscriptionManagementScreen> createState() =>
      _AdminSubscriptionManagementScreenState();
}

class _AdminSubscriptionManagementScreenState
    extends State<AdminSubscriptionManagementScreen> {
  final MarketingAdminService _marketingService = MarketingAdminService();
  final Uuid _uuid = const Uuid();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  SubscriptionPlanType _selectedType = SubscriptionPlanType.free;
  bool _isActive = true;
  Map<String, bool> _features = {};

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление тарифами'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreatePlanDialog()),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subscription_plans')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final plans = snapshot.data?.docs ?? [];
          if (plans.isEmpty) {
            return const Center(child: Text('Нет тарифных планов'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final planData = plans[index].data() as Map<String, dynamic>;
              final plan = SubscriptionPlan.fromMap(planData);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPlanColor(plan.type),
                    child: Icon(_getPlanIcon(plan.type), color: Colors.white),
                  ),
                  title: Text(plan.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Цена: ${plan.price}₽'),
                      Text('Длительность: ${plan.durationDays} дней'),
                      Text('Тип: ${_getPlanTypeName(plan.type)}'),
                      if (plan.features.isNotEmpty)
                        Text('Функции: ${plan.features.length}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handlePlanAction(value, plan),
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
                        value: 'toggle',
                        child: ListTile(
                          leading: Icon(Icons.toggle_on),
                          title: Text('Активировать/Деактивировать'),
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

  void _showCreatePlanDialog() {
    _nameController.clear();
    _priceController.clear();
    _durationController.clear();
    _descriptionController.clear();
    _selectedType = SubscriptionPlanType.free;
    _isActive = true;
    _features = {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать тарифный план'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Цена (₽)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Длительность (дни)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SubscriptionPlanType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип плана',
                  border: OutlineInputBorder(),
                ),
                items: SubscriptionPlanType.values.map((type) {
                  return DropdownMenuItem(
                      value: type, child: Text(_getPlanTypeName(type)));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Активен'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Функции:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ..._buildFeatureCheckboxes(),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(onPressed: _createPlan, child: const Text('Создать')),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureCheckboxes() {
    final commonFeatures = [
      'Базовый функционал',
      'Продвижение профиля',
      'Расширенная аналитика',
      'Приоритет в поиске',
      'Безлимитные посты',
      'Эксклюзивные функции',
      'Приоритетная поддержка',
      'Дополнительные медиа-загрузки',
    ];

    return commonFeatures.map((feature) {
      return CheckboxListTile(
        title: Text(feature),
        value: _features[feature] ?? false,
        onChanged: (value) {
          setState(() {
            _features[feature] = value ?? false;
          });
        },
        contentPadding: EdgeInsets.zero,
      );
    }).toList();
  }

  Future<void> _createPlan() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _durationController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          const SnackBar(content: Text('Заполните все обязательные поля')));
      return;
    }

    try {
      final plan = SubscriptionPlan(
        id: _uuid.v4(),
        name: _nameController.text,
        tier: _selectedType,
        price: double.parse(_priceController.text),
        durationDays: int.parse(_durationController.text),
        features: _features,
        isActive: _isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock admin data for testing
      const adminId = 'admin_123';
      const adminEmail = 'admin@example.com';

      final success = await _marketingService.createSubscriptionPlan(
        plan: plan,
        adminId: adminId,
        adminEmail: adminEmail,
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Тарифный план создан успешно')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Ошибка создания тарифного плана')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void _handlePlanAction(String action, SubscriptionPlan plan) {
    switch (action) {
      case 'edit':
        _showEditPlanDialog(plan);
        break;
      case 'toggle':
        _togglePlanStatus(plan);
        break;
      case 'delete':
        _deletePlan(plan);
        break;
    }
  }

  void _showEditPlanDialog(SubscriptionPlan plan) {
    _nameController.text = plan.name;
    _priceController.text = plan.price.toString();
    _durationController.text = plan.durationDays.toString();
    _selectedType = plan.type;
    _isActive = plan.isActive;
    _features = {for (final feature in plan.features) feature: true};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать тарифный план'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Цена (₽)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Длительность (дни)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SubscriptionPlanType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип плана',
                  border: OutlineInputBorder(),
                ),
                items: SubscriptionPlanType.values.map((type) {
                  return DropdownMenuItem(
                      value: type, child: Text(_getPlanTypeName(type)));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Активен'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Функции:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ..._buildFeatureCheckboxes(),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
              onPressed: () => _updatePlan(plan),
              child: const Text('Сохранить')),
        ],
      ),
    );
  }

  Future<void> _updatePlan(SubscriptionPlan plan) async {
    try {
      final updates = {
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'durationDays': int.parse(_durationController.text),
        'type': _selectedType.name,
        'isActive': _isActive,
        'features': _features,
        'updatedAt': DateTime.now(),
      };

      // Mock admin data for testing
      const adminId = 'admin_123';
      const adminEmail = 'admin@example.com';

      final success = await _marketingService.updateSubscriptionPlan(
        planId: plan.id,
        updates: updates,
        adminId: adminId,
        adminEmail: adminEmail,
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Тарифный план обновлен успешно')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Ошибка обновления тарифного плана')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _togglePlanStatus(SubscriptionPlan plan) async {
    try {
      final updates = {'isActive': !plan.isActive, 'updatedAt': DateTime.now()};

      // Mock admin data for testing
      const adminId = 'admin_123';
      const adminEmail = 'admin@example.com';

      final success = await _marketingService.updateSubscriptionPlan(
        planId: plan.id,
        updates: updates,
        adminId: adminId,
        adminEmail: adminEmail,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Статус плана изменен на ${!plan.isActive ? 'активен' : 'неактивен'}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text('Ошибка изменения статуса плана')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _deletePlan(SubscriptionPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тарифный план'),
        content: Text('Вы уверены, что хотите удалить план "${plan.name}"?'),
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
            .collection('subscription_plans')
            .doc(plan.id)
            .delete();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Тарифный план удален')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  Color _getPlanColor(SubscriptionPlanType type) {
    switch (type) {
      case SubscriptionPlanType.free:
        return Colors.grey;
      case SubscriptionPlanType.premium:
        return Colors.blue;
      case SubscriptionPlanType.pro:
        return Colors.purple;
    }
  }

  IconData _getPlanIcon(SubscriptionPlanType type) {
    switch (type) {
      case SubscriptionPlanType.free:
        return Icons.person;
      case SubscriptionPlanType.premium:
        return Icons.star;
      case SubscriptionPlanType.pro:
        return Icons.diamond;
    }
  }

  String _getPlanTypeName(SubscriptionPlanType type) {
    switch (type) {
      case SubscriptionPlanType.free:
        return 'Бесплатный';
      case SubscriptionPlanType.premium:
        return 'Премиум';
      case SubscriptionPlanType.pro:
        return 'PRO';
    }
  }
}
