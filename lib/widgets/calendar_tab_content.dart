import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/models/calendar_day_aggregate.dart';
import 'package:event_marketplace_app/providers/calendar_providers.dart';
import 'package:event_marketplace_app/services/booking_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Контент вкладки календаря в профиле специалиста
class CalendarTabContent extends ConsumerStatefulWidget {
  final String? specialistId;
  
  const CalendarTabContent({this.specialistId, super.key});

  @override
  ConsumerState<CalendarTabContent> createState() => _CalendarTabContentState();
}

class _CalendarTabContentState extends ConsumerState<CalendarTabContent> {
  DateTime _currentMonth = DateTime.now();
  String? _calendarPolicy;

  @override
  void initState() {
    super.initState();
    final specialistId = widget.specialistId ?? FirebaseAuth.instance.currentUser?.uid;
    if (specialistId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugLog("CAL_OPENED:$specialistId");
        _loadCalendarPolicy(specialistId);
      });
    }
  }

  Future<void> _loadCalendarPolicy(String specialistId) async {
    final service = BookingService();
    final policy = await service.getCalendarPolicy(specialistId);
    if (mounted) {
      setState(() {
        _calendarPolicy = policy;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime.now();
    });
  }

  void _togglePolicy() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final newPolicy = _calendarPolicy == 'manual' ? 'auto' : 'manual';
    final service = BookingService();
    
    try {
      await service.setCalendarPolicy(currentUser.uid, newPolicy);
      if (mounted) {
        setState(() {
          _calendarPolicy = newPolicy;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _onDayTap(DateTime day, CalendarDayStatus? status, int pendingCount) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    debugLog("CAL_DAY_TAP:$dateStr:${status?.value ?? 'free'}:$pendingCount");
    
    _showDayBookings(day);
  }

  void _showDayBookings(DateTime day) {
    final specialistId = widget.specialistId ?? FirebaseAuth.instance.currentUser?.uid;
    if (specialistId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DayBookingsBottomSheet(
        specialistId: specialistId,
        date: day,
      ),
    );
  }

  String? _selectedTimeFilter; // 'morning', 'day', 'evening', null

  @override
  Widget build(BuildContext context) {
    final specialistId = widget.specialistId ?? FirebaseAuth.instance.currentUser?.uid;
    if (specialistId == null) {
      return const Center(child: Text('Необходима авторизация'));
    }

    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final weekDayOfFirst = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday - 1;

    return PopScope(
      canPop: true,
      child: Column(
      children: [
        // Переключатель политики
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Политика бронирования:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Switch(
                value: _calendarPolicy == 'auto',
                onChanged: (_) => _togglePolicy(),
              ),
              Text(
                _calendarPolicy == 'auto' ? 'Бронировать сразу' : 'Требуется подтверждение',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ),

        // Фильтр по времени
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Фильтр по времени:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTimeFilterChip('Утро', 'morning', Icons.wb_sunny),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip('День', 'day', Icons.wb_twilight),
                  const SizedBox(width: 8),
                  _buildTimeFilterChip('Вечер', 'evening', Icons.nightlight),
                  const Spacer(),
                  if (_selectedTimeFilter != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedTimeFilter = null;
                        });
                      },
                      child: const Text('Сбросить'),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Легенда
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(Colors.green, 'Свободно'),
              _buildLegendItem(Colors.orange, 'Кто-то интересуется'),
              _buildLegendItem(Colors.red, 'Занято'),
            ],
          ),
        ),

        // Навигация по месяцам
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
              ),
              Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: _goToToday,
                    child: const Text('Сегодня'),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),

        // Календарь
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('specialist_calendar')
                .doc(specialistId)
                .collection('days')
                .where('date', isGreaterThanOrEqualTo: '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-01')
                .where('date', isLessThan: '${_currentMonth.year}-${(_currentMonth.month + 1).toString().padLeft(2, '0')}-01')
                .snapshots(),
            builder: (context, snapshot) {
              final daysMap = <String, CalendarDayAggregate>{};
              if (snapshot.hasData) {
                for (final doc in snapshot.data!.docs) {
                  final aggregate = CalendarDayAggregate.fromFirestore(doc);
                  daysMap[aggregate.date] = aggregate;
                }
              }

              return Column(
                children: [
                  // Заголовки дней недели
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                          .map((day) => Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Сетка дней
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: daysInMonth + weekDayOfFirst,
                      itemBuilder: (context, index) {
                        if (index < weekDayOfFirst) {
                          return const SizedBox.shrink();
                        }

                        final day = index - weekDayOfFirst + 1;
                        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
                        final dateStr = DateFormat('yyyy-MM-dd').format(date);
                        final aggregate = daysMap[dateStr];
                        
                        // Определяем статус по acceptedBookingId и pendingCount
                        final hasAccepted = aggregate?.acceptedBookingId != null;
                        final pendingCount = aggregate?.pendingCount ?? 0;
                        final status = hasAccepted 
                            ? CalendarDayStatus.confirmed 
                            : (pendingCount > 0 ? CalendarDayStatus.pending : CalendarDayStatus.free);
                        
                        final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());

                        Color? backgroundColor;
                        if (status == CalendarDayStatus.confirmed) {
                          backgroundColor = Colors.red[300];
                        } else if (status == CalendarDayStatus.pending) {
                          backgroundColor = Colors.orange[300];
                        } else {
                          backgroundColor = Colors.green[300];
                        }

                        return GestureDetector(
                          onTap: () => _onDayTap(date, status, pendingCount),
                          child: Container(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: isToday
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    day.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                if (pendingCount > 0)
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '+$pendingCount',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildTimeFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedTimeFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTimeFilter = selected ? value : null;
        });
      },
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
  
  bool _matchesTimeFilter(String? timeFrom, String? timeTo) {
    if (_selectedTimeFilter == null) return true;
    if (timeFrom == null) return false;
    
    final hour = int.tryParse(timeFrom.split(':').first) ?? 0;
    
    switch (_selectedTimeFilter) {
      case 'morning':
        return hour >= 6 && hour < 12;
      case 'day':
        return hour >= 12 && hour < 18;
      case 'evening':
        return hour >= 18 || hour < 6;
      default:
        return true;
    }
  }
}

/// Bottom sheet с заявками на день
class _DayBookingsBottomSheet extends ConsumerWidget {
  const _DayBookingsBottomSheet({
    required this.specialistId,
    required this.date,
  });

  final String specialistId;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final bookingsAsync = ref.watch(
      bookingsByDayProvider(BookingsByDayParams(
        specialistId: specialistId,
        date: date,
      )),
    );

    return Container(
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
            'Заявки на ${DateFormat('d MMMM yyyy').format(date)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          bookingsAsync.when(
            data: (bookings) {
              if (bookings.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('Нет заявок на эту дату'),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return _BookingCard(
                    booking: booking,
                    onConfirm: () async {
                      final service = BookingService();
                      try {
                        await service.confirmBooking(booking.id);
                        debugLog("CAL_SHEET_OK:$dateStr");
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Бронирование подтверждено')),
                          );
                        }
                      } catch (e) {
                        debugLog("CAL_SHEET_ERR:$dateStr:$e");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: $e')),
                          );
                        }
                      }
                    },
                    onDecline: () async {
                      final service = BookingService();
                      try {
                        await service.declineBooking(booking.id);
                        debugLog("CAL_SHEET_OK:$dateStr");
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Бронирование отклонено')),
                          );
                        }
                      } catch (e) {
                        debugLog("CAL_SHEET_ERR:$dateStr:$e");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: $e')),
                          );
                        }
                      }
                    },
                    onOpenChat: () {
                      if (booking.chatId != null) {
                        context.push('/chat/${booking.chatId}');
                      }
                    },
                  );
                },
              );
            },
            loading: () => FutureBuilder(
              future: Future.delayed(const Duration(seconds: 6)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Column(
                    children: [
                      const Text('Загрузка занимает больше времени...'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(bookingsByDayProvider(BookingsByDayParams(
                            specialistId: specialistId,
                            date: date,
                          )));
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
            error: (error, stack) => Column(
              children: [
                Center(child: Text('Ошибка: $error')),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(bookingsByDayProvider(BookingsByDayParams(
                      specialistId: specialistId,
                      date: date,
                    )));
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Карточка заявки
class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onConfirm,
    required this.onDecline,
    required this.onOpenChat,
  });

  final Booking booking;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Клиент
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(booking.clientId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final firstName = userData?['firstName'] as String? ?? '';
                final lastName = userData?['lastName'] as String? ?? '';
                final photoUrl = userData?['photoURL'] as String?;
                
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$firstName $lastName'.trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            
            // Тип мероприятия
            Text(
              booking.eventType,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            
            // Время
            if (booking.timeFrom != null && booking.timeTo != null)
              Text(
                '${booking.timeFrom}–${booking.timeTo}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              )
            else if (booking.durationOption != null)
              Text(
                booking.durationOption == '4h' ? '4 часа' :
                booking.durationOption == '5h' ? '5 часов' :
                booking.durationOption == '6h' ? '6 часов' :
                'Длительность не указана',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              )
            else
              Text(
                'Время не указано',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            
            // Статус
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                label: Text(
                  booking.status == BookingStatus.pending
                      ? 'Ожидает подтверждения'
                      : booking.status == BookingStatus.accepted
                          ? 'Подтверждено'
                          : 'Отклонено',
                ),
                backgroundColor: booking.status == BookingStatus.pending
                    ? Colors.orange[100]
                    : booking.status == BookingStatus.accepted
                        ? Colors.green[100]
                        : Colors.red[100],
              ),
            ),
            
            
            const SizedBox(height: 12),
            
            // Кнопки действий
            if (booking.status == BookingStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Подтвердить'),
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Отклонить'),
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            
            if (booking.chatId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Открыть чат'),
                    onPressed: onOpenChat,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

