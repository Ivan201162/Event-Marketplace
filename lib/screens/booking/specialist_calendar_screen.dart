import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/constants/event_types.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/models/calendar_day_aggregate.dart';
import 'package:event_marketplace_app/screens/booking/booking_create_sheet.dart';
import 'package:event_marketplace_app/screens/booking/booking_pending_list_sheet.dart';
import 'package:event_marketplace_app/services/booking_service.dart';
import 'package:event_marketplace_app/services/chat_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Экран календаря специалиста для бронирования
class SpecialistCalendarScreen extends StatefulWidget {
  const SpecialistCalendarScreen({
    required this.specialistId,
    required this.specialistName,
    super.key,
  });

  final String specialistId;
  final String specialistName;

  @override
  State<SpecialistCalendarScreen> createState() => _SpecialistCalendarScreenState();
}

class _SpecialistCalendarScreenState extends State<SpecialistCalendarScreen> {
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("CAL_OPENED:${widget.specialistId}");
    });
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


  void _onDaySelected(int day, Map<String, CalendarDayAggregate> daysMap) async {
    final selectedDate = DateTime(_currentMonth.year, _currentMonth.month, day);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    
    // Проверяем статус дня через агрегат из daysMap
    final aggregate = daysMap[dateStr];
    final status = aggregate?.status ?? CalendarDayStatus.free;
    
    debugLog("CAL_DAY_TAP:$dateStr:${status.value}:${aggregate?.pendingCount ?? 0}");

    // Policy B: если дата занята (confirmed), показываем диалог
    if (status == CalendarDayStatus.confirmed) {
      _showAlreadyBookedDialog(selectedDate);
      return;
    }

    // Если свободна или pending - показываем форму заказа
    if (status == CalendarDayStatus.free || status == CalendarDayStatus.pending) {
      _showOrderForm(selectedDate);
    }
  }

  void _showAlreadyBookedDialog(DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Дата занята'),
        content: const Text('Эта дата уже занята. Хотите выбрать другую?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Выбрать другую'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Найти или создать чат
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) return;

              final chatService = ChatService();
              try {
                final chatId = await chatService.getOrCreatePrivateChat(currentUser.uid, widget.specialistId);
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                final message = 'Здравствуйте! Вижу, что $dateStr занята. Возможны ли альтернативы?';
                
                // Добавить сообщение в чат
                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .add({
                  'senderId': currentUser.uid,
                  'text': message,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  context.push('/chat/$chatId');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Написать специалисту'),
          ),
        ],
      ),
    );
  }

  void _showOrderForm(DateTime selectedDate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingCreateSheet(
        specialistId: widget.specialistId,
        selectedDate: selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // weekday: 1 = понедельник, 7 = воскресенье
    // Преобразуем для сетки: 0 = понедельник, ..., 6 = воскресенье
    final weekDayOfFirst = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday - 1;

    return PopScope(
      canPop: true,
      child: Scaffold(
      appBar: AppBar(
        title: Text('Заказать: ${widget.specialistName}'),
      ),
      body: Column(
        children: [
          // Легенда
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                  .doc(widget.specialistId)
                  .collection('days')
                  .where('date', isGreaterThanOrEqualTo: '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-01')
                  .where('date', isLessThan: '${_currentMonth.year}-${(_currentMonth.month + 1).toString().padLeft(2, '0')}-01')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

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
                            // Пустые ячейки в начале месяца
                            return const SizedBox.shrink();
                          }

                          final day = index - weekDayOfFirst + 1;
                          final date = DateTime(_currentMonth.year, _currentMonth.month, day);
                          final dateStr = DateFormat('yyyy-MM-dd').format(date);
                          final aggregate = daysMap[dateStr];
                          final status = aggregate?.status ?? CalendarDayStatus.free;
                          final isSelectable = status == CalendarDayStatus.free || status == CalendarDayStatus.pending;
                          final isToday = day == DateTime.now().day &&
                              _currentMonth.month == DateTime.now().month &&
                              _currentMonth.year == DateTime.now().year;

                          Color? backgroundColor;
                          if (status == CalendarDayStatus.confirmed) {
                            backgroundColor = Colors.red[300];
                          } else if (status == CalendarDayStatus.pending) {
                            backgroundColor = Colors.orange[300];
                          } else {
                            backgroundColor = Colors.green[300];
                          }

                          final pendingCount = aggregate?.pendingCount ?? 0;

                          return GestureDetector(
                            onTap: () => _onDaySelected(day, daysMap),
                            child: Container(
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                border: isToday
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : null,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    day.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                      color: isSelectable ? Colors.black : Colors.white,
                                    ),
                                  ),
                                  if (pendingCount > 0 && status == CalendarDayStatus.pending)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          '+$pendingCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.center,
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
      ),
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
}
