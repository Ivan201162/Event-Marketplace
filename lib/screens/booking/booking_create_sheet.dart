import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:event_marketplace_app/constants/event_types.dart';
import 'package:event_marketplace_app/models/pricing.dart';
import 'package:event_marketplace_app/services/booking_service.dart';
import 'package:event_marketplace_app/services/pricing_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// BottomSheet для создания заявки (клиент)
class BookingCreateSheet extends StatefulWidget {
  const BookingCreateSheet({
    required this.specialistId,
    required this.selectedDate,
    super.key,
  });

  final String specialistId;
  final DateTime selectedDate;

  @override
  State<BookingCreateSheet> createState() => _BookingCreateSheetState();
}

class _BookingCreateSheetState extends State<BookingCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _customEventTypeController = TextEditingController();
  final _bookingService = BookingService();
  final _pricingService = PricingService();

  String? _selectedEventType;
  String _timeType = 'unknown';
  TimeOfDay? _timeFrom;
  TimeOfDay? _timeTo;
  bool _isSubmitting = false;
  
  int? _priceForDate;
  PriceRating? _priceRating;
  bool _isLoadingPrice = false;

  @override
  void initState() {
    super.initState();
    debugLog("SHEET_OPENED:booking_create");
  }

  Future<void> _loadPriceForDate() async {
    if (_selectedEventType == null || _selectedEventType!.isEmpty) {
      setState(() {
        _priceForDate = null;
        _priceRating = null;
      });
      return;
    }

    setState(() => _isLoadingPrice = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      final priceData = await _pricingService.getPriceForDate(
        widget.specialistId,
        dateStr,
        _selectedEventType == 'Другое'
            ? _customEventTypeController.text.trim()
            : _selectedEventType!,
      );

      if (priceData != null && mounted) {
        final priceFrom = priceData['priceFrom'] as num?;
        if (priceFrom != null) {
          setState(() {
            _priceForDate = priceFrom.toInt();
          });

          // Загружаем рейтинг цены
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.specialistId)
              .get();
          final userData = userDoc.data();
          final city = userData?['city'] as String?;

          // Получаем роль из прайса (если есть)
          String? roleId;
          if (priceData != null && priceData.containsKey('roleId')) {
            roleId = priceData['roleId'] as String?;
          }
          
          // Если роль не найдена, используем первую роль специалиста (временно)
          if (roleId == null) {
            final specialistDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.specialistId)
                .get();
            final roles = (specialistDoc.data()?['roles'] as List?)?.cast<Map<String, dynamic>>() ?? [];
            if (roles.isNotEmpty) {
              roleId = roles.first['id'] as String?;
            }
          }
          
          final ratingStr = roleId != null ? await _pricingService.calculatePriceRating(
            specialistId: widget.specialistId,
            roleId: roleId,
            price: _priceForDate!,
            city: city,
          ) : null;

          if (ratingStr != null && mounted) {
            setState(() {
              _priceRating = ratingStr == 'excellent'
                  ? PriceRating.excellent
                  : ratingStr == 'average'
                      ? PriceRating.average
                      : PriceRating.high;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading price: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPrice = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _customEventTypeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEventType == null || _selectedEventType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите тип мероприятия')),
      );
      return;
    }
    if (_selectedEventType == 'Другое' && _customEventTypeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название мероприятия')),
      );
      return;
    }
    if (_timeType == 'custom_time' && (_timeFrom == null || _timeTo == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите время начала и окончания')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final requestedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      String? timeFromStr;
      String? timeToStr;
      String? durationOption;

      if (_timeType == 'custom_time' && _timeFrom != null && _timeTo != null) {
        timeFromStr = '${_timeFrom!.hour.toString().padLeft(2, '0')}:${_timeFrom!.minute.toString().padLeft(2, '0')}';
        timeToStr = '${_timeTo!.hour.toString().padLeft(2, '0')}:${_timeTo!.minute.toString().padLeft(2, '0')}';
      }

      final eventType = _selectedEventType == '������' 
          ? _customEventTypeController.text.trim()
          : (_selectedEventType ?? '�����������');

      await _bookingService.createBooking(
        specialistId: widget.specialistId,
        clientId: currentUser.uid,
        requestedDate: requestedDate,
        timeFrom: timeFromStr,
        timeTo: timeToStr,
        durationOption: durationOption,
        eventType: eventType,
        message: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заявка отправлена')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error submitting booking: $e');
      debugLog("ERROR:submit_booking:$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Создать заявку на ${DateFormat('d MMMM yyyy', 'ru').format(widget.selectedDate)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Тип мероприятия
                        DropdownButtonFormField<String>(
                          value: _selectedEventType,
                          decoration: const InputDecoration(
                            labelText: 'Тип мероприятия *',
                            border: OutlineInputBorder(),
                          ),
                          items: EventTypes.allTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedEventType = value;
                              if (value != 'Другое') {
                                _customEventTypeController.clear();
                              }
                            });
                            // Загружаем цену при изменении типа мероприятия
                            if (value != null && value.isNotEmpty) {
                              _loadPriceForDate();
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Выберите тип мероприятия';
                            }
                            return null;
                          },
                        ),
                        if (_selectedEventType == 'Другое') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customEventTypeController,
                            decoration: const InputDecoration(
                              labelText: 'Название мероприятия *',
                              border: OutlineInputBorder(),
                              hintText: 'До 50 символов',
                            ),
                            maxLength: 50,
                            onChanged: (value) {
                              if (value.trim().isNotEmpty) {
                                _loadPriceForDate();
                              }
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Введите название мероприятия';
                              }
                              return null;
                            },
                          ),
                        ],
                        // Показ цены
                        if (_isLoadingPrice)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_priceForDate != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Ориентировочная цена: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      '${NumberFormat('#,###', 'ru').format(_priceForDate)} ₽',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    if (_priceRating != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        _priceRating!.emoji,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _priceRating!.label,
                                        style: TextStyle(
                                          color: _priceRating == PriceRating.excellent
                                              ? Colors.green
                                              : _priceRating == PriceRating.average
                                                  ? Colors.orange
                                                  : Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Цена ориентировочная',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Время
                        const Text(
                          'Время *',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<String>(
                          title: const Text('Весь день'),
                          value: 'full_day',
                          groupValue: _timeType,
                          onChanged: (value) {
                            setState(() => _timeType = value!);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Указать время'),
                          value: 'custom_time',
                          groupValue: _timeType,
                          onChanged: (value) {
                            setState(() => _timeType = value!);
                          },
                        ),
                        if (_timeType == 'custom_time') ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 32, top: 8, bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.access_time, size: 18),
                                    label: Text(_timeFrom != null
                                        ? _timeFrom!.format(context)
                                        : 'Время от'),
                                    onPressed: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: _timeFrom ?? TimeOfDay.now(),
                                      );
                                      if (time != null && mounted) {
                                        setState(() => _timeFrom = time);
                                      }
                                    },
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('—'),
                                ),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.access_time, size: 18),
                                    label: Text(_timeTo != null
                                        ? _timeTo!.format(context)
                                        : 'Время до'),
                                    onPressed: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: _timeTo ?? TimeOfDay.now(),
                                      );
                                      if (time != null && mounted) {
                                        setState(() => _timeTo = time);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        RadioListTile<String>(
                          title: const Text('Не знаю'),
                          value: 'unknown',
                          groupValue: _timeType,
                          onChanged: (value) {
                            setState(() => _timeType = value!);
                          },
                        ),
                        const SizedBox(height: 16),
                        // Комментарий
                        TextFormField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Комментарий (опционально)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        // Кнопка отправки
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Отправить заявку'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


