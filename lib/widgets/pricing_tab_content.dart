import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/constants/event_types.dart';
import 'package:event_marketplace_app/constants/specialist_roles.dart';
import 'package:event_marketplace_app/models/app_user.dart';
import 'package:event_marketplace_app/services/pricing_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Контент вкладки прайсов в профиле специалиста
class PricingTabContent extends StatefulWidget {
  final AppUser user;
  final bool isOwnProfile;

  const PricingTabContent({
    required this.user,
    required this.isOwnProfile,
    super.key,
  });

  @override
  State<PricingTabContent> createState() => _PricingTabContentState();
}

class _PricingTabContentState extends State<PricingTabContent> {
  final PricingService _pricingService = PricingService();
  List<Map<String, dynamic>> _basePrices = [];
  List<Map<String, dynamic>> _specialDates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrices();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      debugLog("PRICING_TAB_OPENED:${currentUser.uid}");
    }
  }

  Future<void> _loadPrices() async {
    setState(() => _isLoading = true);
    try {
      final basePrices = await _pricingService.getBasePrices(widget.user.uid);
      final specialDates = await _pricingService.getSpecialDates(widget.user.uid);
      setState(() {
        _basePrices = basePrices;
        _specialDates = specialDates;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading prices: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddPriceDialog() async {
    final eventTypeController = TextEditingController();
    final priceController = TextEditingController();
    final hoursController = TextEditingController(text: '4');
    final descriptionController = TextEditingController();
    String? selectedEventType;
    String? selectedRoleId;
    
    // Получаем активные роли специалиста
    final userRoles = widget.user.roles.where((role) {
      final roleId = role['id'] as String?;
      return roleId != null;
    }).toList();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Добавить услугу'),
          content: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Выбор роли
                if (userRoles.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Роль *'),
                    items: userRoles.map((role) {
                      final roleId = role['id'] as String? ?? '';
                      final roleLabel = role['label'] as String? ?? '';
                      return DropdownMenuItem(
                        value: roleId,
                        child: Text('${SpecialistRoles.getIcon(roleId)} $roleLabel'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRoleId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Тип мероприятия'),
                  items: EventTypes.allTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedEventType = value;
                      if (value == 'Другое') {
                        eventTypeController.text = '';
                      } else {
                        eventTypeController.text = value ?? '';
                      }
                    });
                  },
                ),
                if (selectedEventType == 'Другое') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: eventTypeController,
                    decoration: const InputDecoration(labelText: 'Укажите тип'),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Цена "от" (₽)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hoursController,
                  decoration: const InputDecoration(labelText: 'Часы'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Описание (необязательно)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final eventType = selectedEventType == 'Другое'
                    ? eventTypeController.text.trim()
                    : selectedEventType;
                final price = int.tryParse(priceController.text);
                final hours = int.tryParse(hoursController.text) ?? 4;

                if (userRoles.isNotEmpty && (selectedRoleId == null || selectedRoleId?.isEmpty != false)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Выберите роль')),
                  );
                  return;
                }
                if (eventType == null || eventType.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Выберите тип мероприятия')),
                  );
                  return;
                }
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите корректную цену')),
                  );
                  return;
                }

                try {
                  final roleId = selectedRoleId ?? userRoles.firstOrNull?['id'] as String? ?? 'other';
                  final roleLabel = userRoles.firstWhere(
                    (r) => r['id'] == roleId,
                    orElse: () => {'label': 'Другое'},
                  )['label'] as String? ?? 'Другое';
                  
                  await _pricingService.addBasePrice(
                    specialistId: widget.user.uid,
                    roleId: roleId,
                    roleLabel: roleLabel,
                    eventType: eventType,
                    priceFrom: price,
                    hours: hours,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _loadPrices();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Услуга добавлена')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRating(String? rating) {
    if (rating == null) return const SizedBox.shrink();

    String emoji;
    String text;
    Color color;

    switch (rating) {
      case 'excellent':
        emoji = '🟢';
        text = 'отличная цена';
        color = Colors.green;
        break;
      case 'average':
        emoji = '🟡';
        text = 'средняя цена';
        color = Colors.orange;
        break;
      case 'high':
        emoji = '🔴';
        text = 'высокая цена';
        color = Colors.red;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentiles(Map<String, double> stats) {
    final p25 = stats['p25']?.toInt();
    final p50 = stats['median']?.toInt();
    final p75 = stats['p75']?.toInt();
    
    if (p25 == null || p50 == null || p75 == null) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            'По рынку: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'p25: $p25₽',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'p50: $p50₽',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'p75: $p75₽',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadPrices,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Базовые прайсы
          if (_basePrices.isEmpty && widget.isOwnProfile)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text('Услуги не добавлены'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить услугу'),
                      onPressed: _showAddPriceDialog,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._basePrices.map((price) => FutureBuilder<Map<String, dynamic>>(
                  future: widget.isOwnProfile
                      ? Future.value({})
                      : () async {
                          final roleId = price['roleId'] as String?;
                          if (roleId == null) return <String, dynamic>{};
                          
                          final priceValue = (price['priceFrom'] as num?)?.toInt() ?? 0;
                          final rating = await _pricingService.calculatePriceRating(
                            specialistId: widget.user.uid,
                            roleId: roleId,
                            price: priceValue,
                            city: widget.user.city,
                          );
                          
                          // Получаем статистику перцентилей
                          final stats = await _pricingService.calculatePriceStatsForCityRole(
                            widget.user.city ?? '',
                            roleId,
                          );
                          
                          return {
                            'rating': rating,
                            'stats': stats,
                          };
                        }(),
                  builder: (context, snapshot) {
                    final rating = snapshot.data?['rating'] as String?;
                    final stats = snapshot.data?['stats'] as Map<String, double>?;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.push_pin, color: Colors.blue),
                        title: Text(
                          price['eventType'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'от ${NumberFormat('#,###', 'ru').format(price['priceFrom'])} ₽',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (!widget.isOwnProfile && rating != null)
                                  _buildPriceRating(rating),
                              ],
                            ),
                            if (stats != null && stats.isNotEmpty)
                              _buildPercentiles(stats),
                            Text('${price['hours']} часов'),
                            if (price['description'] != null &&
                                (price['description'] as String).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  price['description'] as String,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                          ],
                        ),
                        trailing: widget.isOwnProfile
                            ? IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  // TODO: Редактирование
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ).toList(),

          // Кнопка добавления (только для специалиста)
          if (widget.isOwnProfile && _basePrices.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Добавить услугу'),
              onPressed: _showAddPriceDialog,
            ),
          ],

          // Спец-даты (для специалиста)
          if (widget.isOwnProfile && _specialDates.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Специальные даты',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._specialDates.map((specialDate) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.red),
                    title: Text(
                      DateFormat('d MMMM yyyy', 'ru')
                          .format(DateFormat('yyyy-MM-dd').parse(specialDate['date'] as String)),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (specialDate['eventType'] != null)
                          Text('${specialDate['eventType']}'),
                        Text(
                          'от ${NumberFormat('#,###', 'ru').format(specialDate['priceFrom'])} ₽',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('${specialDate['hours']} часов'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _pricingService.deleteSpecialDate(
                          widget.user.uid,
                          specialDate['date'] as String,
                        );
                        _loadPrices();
                      },
                    ),
                  ),
                ),
              ).toList(),
          ],
        ],
      ),
    );
  }
}
