import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guest.dart';
import '../services/guest_service.dart';
import '../widgets/guest_widget.dart';
import 'create_guest_event_screen.dart';
import 'guest_registration_screen.dart';

/// Экран управления гостями
class GuestManagementScreen extends ConsumerStatefulWidget {
  final String organizerId;

  const GuestManagementScreen({
    super.key,
    required this.organizerId,
  });

  @override
  ConsumerState<GuestManagementScreen> createState() =>
      _GuestManagementScreenState();
}

class _GuestManagementScreenState extends ConsumerState<GuestManagementScreen> {
  final GuestService _guestService = GuestService();

  String _selectedEventId = '';
  GuestFilter _filter = const GuestFilter();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление гостями'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _showQRScanner,
          ),
        ],
      ),
      body: Column(
        children: [
          // Выбор события
          _buildEventSelector(),

          // Статистика
          if (_selectedEventId.isNotEmpty) _buildStatsSection(),

          // Список гостей
          Expanded(
            child: _selectedEventId.isEmpty
                ? _buildEmptyState()
                : _buildGuestsList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_guest',
            onPressed: _selectedEventId.isNotEmpty ? _addGuest : null,
            child: const Icon(Icons.person_add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'create_event',
            onPressed: _createEvent,
            child: const Icon(Icons.event),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSelector() {
    return StreamBuilder<List<GuestEvent>>(
      stream: _guestService.getOrganizerEvents(widget.organizerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'У вас пока нет событий для гостей',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выберите событие:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedEventId.isEmpty ? null : _selectedEventId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Выберите событие',
                ),
                items: events.map((event) {
                  return DropdownMenuItem(
                    value: event.id,
                    child: Text(event.title),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEventId = value ?? '';
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<GuestStats>(
      future: _guestService.getGuestStats(_selectedEventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data ?? GuestStats.empty();
        if (stats.totalGuests == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Общая статистика
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Всего гостей',
                          stats.totalGuests.toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Подтверждено',
                          stats.confirmedGuests.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'На мероприятии',
                          stats.checkedInGuests.toString(),
                          Icons.event_available,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Процентные показатели
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Посещаемость',
                          '${(stats.attendanceRate * 100).toInt()}%',
                          Icons.trending_up,
                          Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Подтверждения',
                          '${(stats.confirmationRate * 100).toInt()}%',
                          Icons.thumb_up,
                          Colors.teal,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Поздравления',
                          stats.totalGreetings.toString(),
                          Icons.celebration,
                          Colors.pink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Выберите событие',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Выберите событие из списка выше, чтобы управлять гостями',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _createEvent,
            icon: const Icon(Icons.add),
            label: const Text('Создать событие'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestsList() {
    return StreamBuilder<List<Guest>>(
      stream: _guestService.getEventGuests(_selectedEventId, _filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final guests = snapshot.data ?? [];
        final filteredGuests = _filterGuests(guests);

        if (filteredGuests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Нет гостей',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Добавьте гостей для этого события',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addGuest,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Добавить гостя'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: filteredGuests.length,
          itemBuilder: (context, index) {
            final guest = filteredGuests[index];
            return GuestWidget(
              guest: guest,
              onTap: () => _showGuestDetails(guest),
              onCheckIn: () => _checkInGuest(guest),
              onCheckOut: () => _checkOutGuest(guest),
              onCancel: () => _cancelGuest(guest),
              onShare: () => _shareGuestInfo(guest),
            );
          },
        );
      },
    );
  }

  List<Guest> _filterGuests(List<Guest> guests) {
    if (_searchQuery.isEmpty) return guests;

    final query = _searchQuery.toLowerCase();
    return guests.where((guest) {
      return guest.guestName.toLowerCase().contains(query) ||
          guest.guestEmail.toLowerCase().contains(query);
    }).toList();
  }

  void _createEvent() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CreateGuestEventScreen(
          organizerId: widget.organizerId,
        ),
      ),
    )
        .then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _addGuest() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => GuestRegistrationScreen(
          eventId: _selectedEventId,
        ),
      ),
    )
        .then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showGuestDetails(Guest guest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(guest.guestName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${guest.guestEmail}'),
            if (guest.guestPhone != null) Text('Телефон: ${guest.guestPhone}'),
            Text('Статус: ${guest.statusText}'),
            if (guest.registeredAt != null)
              Text('Зарегистрирован: ${_formatDate(guest.registeredAt!)}'),
            if (guest.confirmedAt != null)
              Text('Подтвержден: ${_formatDate(guest.confirmedAt!)}'),
            if (guest.checkedInAt != null)
              Text('На мероприятии: ${_formatDate(guest.checkedInAt!)}'),
            if (guest.checkedOutAt != null)
              Text('Покинул: ${_formatDate(guest.checkedOutAt!)}'),
            if (guest.greetingsCount > 0)
              Text('Поздравлений: ${guest.greetingsCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          if (guest.status == GuestStatus.registered)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _checkInGuest(guest);
              },
              child: const Text('Регистрация'),
            ),
        ],
      ),
    );
  }

  void _checkInGuest(Guest guest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Регистрация гостя'),
        content:
            Text('Подтвердить регистрацию ${guest.guestName} на мероприятие?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _guestService.checkInGuest(guest.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Гость зарегистрирован')),
                );
                setState(() {});
              }
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  void _checkOutGuest(Guest guest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход гостя'),
        content: Text('Подтвердить выход ${guest.guestName} с мероприятия?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _guestService.checkOutGuest(guest.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Гость покинул мероприятие')),
                );
                setState(() {});
              }
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  void _cancelGuest(Guest guest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отмена участия'),
        content: Text('Отменить участие ${guest.guestName} в мероприятии?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _guestService.cancelGuest(guest.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Участие отменено')),
                );
                setState(() {});
              }
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  void _shareGuestInfo(Guest guest) {
    // TODO: Реализовать шаринг информации о госте
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Информация о госте скопирована')),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск гостей'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Введите имя или email гостя...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Поиск'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        filter: _filter,
        onFilterChanged: (newFilter) {
          setState(() {
            _filter = newFilter;
          });
        },
      ),
    );
  }

  void _showQRScanner() {
    // TODO: Реализовать QR сканер для регистрации гостей
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR сканер')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Диалог фильтра гостей
class _FilterDialog extends StatefulWidget {
  final GuestFilter filter;
  final Function(GuestFilter) onFilterChanged;

  const _FilterDialog({
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late GuestFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Фильтр гостей'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Статусы
          const Text('Статус:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...GuestStatus.values.map((status) {
            return CheckboxListTile(
              title: Text(_getStatusText(status)),
              value: _filter.statuses?.contains(status) ?? false,
              onChanged: (value) {
                setState(() {
                  final statuses = _filter.statuses ?? [];
                  if (value == true) {
                    _filter = _filter.copyWith(statuses: [...statuses, status]);
                  } else {
                    _filter = _filter.copyWith(
                        statuses: statuses.where((s) => s != status).toList());
                  }
                });
              },
            );
          }),

          const SizedBox(height: 16),

          // Дополнительные фильтры
          CheckboxListTile(
            title: const Text('С поздравлениями'),
            value: _filter.hasGreetings ?? false,
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(hasGreetings: value);
              });
            },
          ),

          CheckboxListTile(
            title: const Text('На мероприятии'),
            value: _filter.isCheckedIn ?? false,
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(isCheckedIn: value);
              });
            },
          ),

          CheckboxListTile(
            title: const Text('Покинули мероприятие'),
            value: _filter.isCheckedOut ?? false,
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(isCheckedOut: value);
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onFilterChanged(_filter);
            Navigator.pop(context);
          },
          child: const Text('Применить'),
        ),
      ],
    );
  }

  String _getStatusText(GuestStatus status) {
    switch (status) {
      case GuestStatus.invited:
        return 'Приглашен';
      case GuestStatus.registered:
        return 'Зарегистрирован';
      case GuestStatus.confirmed:
        return 'Подтвержден';
      case GuestStatus.checkedIn:
        return 'На мероприятии';
      case GuestStatus.checkedOut:
        return 'Покинул мероприятие';
      case GuestStatus.cancelled:
        return 'Отменил участие';
    }
  }
}
