import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/specialist_categories_list.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Экран редактирования прайсов специалиста
class SpecialistPriceEditor extends StatefulWidget {
  const SpecialistPriceEditor({super.key});

  @override
  State<SpecialistPriceEditor> createState() => _SpecialistPriceEditorState();
}

class _SpecialistPriceEditorState extends State<SpecialistPriceEditor> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Необходима авторизация')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Прайсы услуг'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('prices')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final prices = snapshot.data?.docs ?? [];

          if (prices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.attach_money, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'У вас пока нет прайсов',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Добавьте первую услугу',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prices.length,
            itemBuilder: (context, index) {
              final priceDoc = prices[index];
              final priceData = priceDoc.data() as Map<String, dynamic>;
              
              return _buildPriceCard(priceDoc.id, priceData);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPriceDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Добавить услугу'),
      ),
    );
  }

  Widget _buildPriceCard(String priceId, Map<String, dynamic> priceData) {
    final eventType = priceData['type'] as String? ?? 'Не указано';
    final customType = priceData['customType'] as String?;
    final priceFrom = priceData['priceFrom'] as num? ?? 0;
    final hours = priceData['hours'] as num? ?? 0;
    final fixed = priceData['fixed'] as bool? ?? false;
    final note = priceData['note'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    customType ?? eventType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showEditPriceDialog(context, priceId, priceData),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _confirmDeletePrice(context, priceId),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  fixed ? '$priceFrom ₽' : 'от $priceFrom ₽',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                if (hours > 0) ...[
                  const SizedBox(width: 16),
                  Text(
                    '$hours ${_hoursText(hours.toInt())}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Комментарий: $note',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _hoursText(int hours) {
    if (hours == 1) return 'час';
    if (hours >= 2 && hours <= 4) return 'часа';
    return 'часов';
  }

  void _showAddPriceDialog(BuildContext context) {
    _showPriceDialog(context, null, null);
  }

  void _showEditPriceDialog(BuildContext context, String priceId, Map<String, dynamic> priceData) {
    _showPriceDialog(context, priceId, priceData);
  }

  void _showPriceDialog(BuildContext context, String? priceId, Map<String, dynamic>? priceData) {
    final formKey = GlobalKey<FormState>();
    final eventTypeController = TextEditingController(
      text: priceData?['type'] as String? ?? '',
    );
    final customTypeController = TextEditingController(
      text: priceData?['customType'] as String? ?? '',
    );
    final priceFromController = TextEditingController(
      text: priceData?['priceFrom']?.toString() ?? '',
    );
    final hoursController = TextEditingController(
      text: priceData?['hours']?.toString() ?? '',
    );
    final noteController = TextEditingController(
      text: priceData?['note'] as String? ?? '',
    );
    
    String? selectedEventType = priceData?['type'] as String?;
    bool isCustomType = selectedEventType == 'Другое';
    bool fixed = priceData?['fixed'] as bool? ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    priceId == null ? 'Добавить услугу' : 'Редактировать услугу',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Тип события
                  DropdownButtonFormField<String>(
                    value: selectedEventType,
                    decoration: const InputDecoration(
                      labelText: 'Тип события *',
                      border: OutlineInputBorder(),
                    ),
                    items: EventTypesList.types.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedEventType = value;
                        isCustomType = value == 'Другое';
                        if (!isCustomType) {
                          customTypeController.clear();
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Выберите тип события';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Кастомный тип
                  if (isCustomType)
                    TextFormField(
                      controller: customTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Укажите тип события *',
                        border: OutlineInputBorder(),
                        hintText: 'Например: День рождения ребенка',
                      ),
                      validator: (value) {
                        if (isCustomType && (value == null || value.trim().isEmpty)) {
                          return 'Укажите тип события';
                        }
                        return null;
                      },
                    ),
                  if (isCustomType) const SizedBox(height: 16),
                  
                  // Цена от
                  TextFormField(
                    controller: priceFromController,
                    decoration: const InputDecoration(
                      labelText: 'Цена от (₽) *',
                      border: OutlineInputBorder(),
                      hintText: '25000',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Укажите цену';
                      }
                      final price = int.tryParse(value.trim());
                      if (price == null || price < 0) {
                        return 'Введите корректную цену';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Длительность
                  TextFormField(
                    controller: hoursController,
                    decoration: const InputDecoration(
                      labelText: 'Длительность (часы)',
                      border: OutlineInputBorder(),
                      hintText: '5',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final hours = int.tryParse(value.trim());
                        if (hours != null && hours < 0) {
                          return 'Введите корректное число';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Фиксированная цена
                  SwitchListTile(
                    title: const Text('Фиксированная цена'),
                    subtitle: const Text('Цена не меняется от количества часов'),
                    value: fixed,
                    onChanged: (value) {
                      setModalState(() {
                        fixed = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Комментарий
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Комментарий (опционально)',
                      border: OutlineInputBorder(),
                      hintText: 'Работаю с ассистентом. Звук включён.',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  
                  // Кнопки
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            
                            final currentUser = FirebaseAuth.instance.currentUser;
                            if (currentUser == null) return;
                            
                            try {
                              final priceData = {
                                'type': selectedEventType,
                                'customType': isCustomType ? customTypeController.text.trim() : null,
                                'priceFrom': int.parse(priceFromController.text.trim()),
                                'hours': hoursController.text.trim().isNotEmpty
                                    ? int.parse(hoursController.text.trim())
                                    : 0,
                                'fixed': fixed,
                                'note': noteController.text.trim().isNotEmpty
                                    ? noteController.text.trim()
                                    : null,
                                'updatedAt': FieldValue.serverTimestamp(),
                              };
                              
                              if (priceId == null) {
                                priceData['createdAt'] = FieldValue.serverTimestamp();
                                final docRef = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser.uid)
                                    .collection('prices')
                                    .add(priceData);
                                debugLog("PRICE_ADDED:${docRef.id}");
                              } else {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser.uid)
                                    .collection('prices')
                                    .doc(priceId)
                                    .update(priceData);
                                debugLog("PRICE_UPDATED:$priceId");
                              }
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(priceId == null ? 'Услуга добавлена' : 'Услуга обновлена'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка: $e')),
                                );
                              }
                            }
                          },
                          child: Text(priceId == null ? 'Добавить' : 'Сохранить'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeletePrice(BuildContext context, String priceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить услугу?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) return;
              
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('prices')
                    .doc(priceId)
                    .delete();
                
                debugLog("PRICE_DELETED:$priceId");
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Услуга удалена')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}


