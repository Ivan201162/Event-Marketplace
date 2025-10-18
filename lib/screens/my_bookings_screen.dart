import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import 'package:flutter/foundation.dart';
import '../services/booking_service.dart';
import 'package:flutter/foundation.dart';
import '../widgets/auth_gate.dart';
import 'package:flutter/foundation.dart';
import '../widgets/back_button_handler.dart';
import 'package:flutter/foundation.dart';
import '../widgets/booking_card.dart';
import 'package:flutter/foundation.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> with TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();

  List<Booking> _bookings = [];
  bool _isLoading = true;
  String _selectedFilter = 'Р’СЃРµ';

  late TabController _tabController;

  final List<String> _filters = [
    'Р’СЃРµ',
    'РћР¶РёРґР°СЋС‚ РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ',
    'РџРѕРґС‚РІРµСЂР¶РґРµРЅС‹',
    'Р’С‹РїРѕР»РЅРµРЅС‹',
    'РћС‚РјРµРЅРµРЅС‹',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // РџРѕР»СѓС‡Р°РµРј С‚РµРєСѓС‰РµРіРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
      final currentUserAsync = ref.read(currentUserProvider);
      final currentUser = currentUserAsync.value;

      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Р—Р°РіСЂСѓР¶Р°РµРј Р·Р°СЏРІРєРё РёР· Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final bookings = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return Booking.fromMap({...data, 'id': doc.id});
      }).toList();

      // Р•СЃР»Рё Р·Р°СЏРІРѕРє РЅРµС‚, СЃРѕР·РґР°РµРј С‚РµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ
      if (bookings.isEmpty) {
        await _createTestBookings(currentUser.uid);
        // РџРµСЂРµР·Р°РіСЂСѓР¶Р°РµРј РїРѕСЃР»Рµ СЃРѕР·РґР°РЅРёСЏ С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…
        final newQuerySnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('customerId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .get();

        final newBookings = newQuerySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return Booking.fromMap({...data, 'id': doc.id});
        }).toList();

        setState(() {
          _bookings = newBookings;
          _isLoading = false;
        });
      } else {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё Р·Р°СЏРІРѕРє: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createTestBookings(String uid) async {
    try {
      // РЎРѕР·РґР°РµРј С‚РµСЃС‚РѕРІС‹Рµ Р·Р°СЏРІРєРё
      await FirebaseFirestore.instance.collection('bookings').add({
        'customerId': uid,
        'specialistId': 'spec_test_1',
        'eventDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'status': 'pending',
        'details': 'РўРµСЃС‚РѕРІР°СЏ Р·Р°СЏРІРєР° РЅР° С„РѕС‚РѕСЃРµСЃСЃРёСЋ',
        'totalPrice': 15000.0,
        'createdAt': Timestamp.now(),
        'eventTitle': 'Р¤РѕС‚РѕСЃРµСЃСЃРёСЏ РЅР° РїСЂРёСЂРѕРґРµ',
        'customerName': 'РўРµСЃС‚РѕРІС‹Р№ РєР»РёРµРЅС‚',
        'customerPhone': '+7 (999) 123-45-67',
      });

      await FirebaseFirestore.instance.collection('bookings').add({
        'customerId': uid,
        'specialistId': 'spec_test_2',
        'eventDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
        'status': 'confirmed',
        'details': 'РўРµСЃС‚РѕРІР°СЏ Р·Р°СЏРІРєР° РЅР° РІРёРґРµРѕСЃСЉРµРјРєСѓ',
        'totalPrice': 25000.0,
        'createdAt': Timestamp.now(),
        'eventTitle': 'Р’РёРґРµРѕСЃСЉРµРјРєР° СЃРІР°РґСЊР±С‹',
        'customerName': 'РўРµСЃС‚РѕРІС‹Р№ РєР»РёРµРЅС‚',
        'customerPhone': '+7 (999) 123-45-67',
      });

      await FirebaseFirestore.instance.collection('bookings').add({
        'customerId': uid,
        'specialistId': 'spec_test_3',
        'eventDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 7)),
        ),
        'status': 'completed',
        'details': 'Р—Р°РІРµСЂС€РµРЅРЅР°СЏ С‚РµСЃС‚РѕРІР°СЏ Р·Р°СЏРІРєР°',
        'totalPrice': 10000.0,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 10)),
        ),
        'eventTitle': 'Р¤РѕС‚РѕСЃРµСЃСЃРёСЏ РІ СЃС‚СѓРґРёРё',
        'customerName': 'РўРµСЃС‚РѕРІС‹Р№ РєР»РёРµРЅС‚',
        'customerPhone': '+7 (999) 123-45-67',
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ С‚РµСЃС‚РѕРІС‹С… Р·Р°СЏРІРѕРє: $e');
    }
  }

  List<Booking> get _filteredBookings {
    if (_selectedFilter == 'Р’СЃРµ') {
      return _bookings;
    }

    BookingStatus? status;
    switch (_selectedFilter) {
      case 'РћР¶РёРґР°СЋС‚ РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ':
        status = BookingStatus.pending;
        break;
      case 'РџРѕРґС‚РІРµСЂР¶РґРµРЅС‹':
        status = BookingStatus.confirmed;
        break;
      case 'Р’С‹РїРѕР»РЅРµРЅС‹':
        status = BookingStatus.completed;
        break;
      case 'РћС‚РјРµРЅРµРЅС‹':
        status = BookingStatus.cancelled;
        break;
    }

    return _bookings.where((booking) => booking.status == status).toList();
  }

  Future<void> _cancelBooking(Booking booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('РћС‚РјРµРЅРёС‚СЊ Р·Р°СЏРІРєСѓ'),
        content: const Text('Р’С‹ СѓРІРµСЂРµРЅС‹, С‡С‚Рѕ С…РѕС‚РёС‚Рµ РѕС‚РјРµРЅРёС‚СЊ СЌС‚Сѓ Р·Р°СЏРІРєСѓ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('РќРµС‚'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Р”Р°, РѕС‚РјРµРЅРёС‚СЊ'),
          ),
        ],
      ),
    );

    if (result ?? false) {
      try {
        await _bookingService.cancelBooking(booking.id);
        await _loadBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Р—Р°СЏРІРєР° РѕС‚РјРµРЅРµРЅР°'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('РћС€РёР±РєР° РѕС‚РјРµРЅС‹ Р·Р°СЏРІРєРё: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showBookingDetails(Booking booking) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Р—Р°РіРѕР»РѕРІРѕРє
              Row(
                children: [
                  const Text(
                    'Р”РµС‚Р°Р»Рё Р·Р°СЏРІРєРё',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // РЎРѕРґРµСЂР¶РёРјРѕРµ
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        'РќР°Р·РІР°РЅРёРµ',
                        booking.eventTitle ?? 'РќРµ СѓРєР°Р·Р°РЅРѕ',
                      ),
                      _buildDetailRow('Р”Р°С‚Р°', _formatDate(booking.eventDate)),
                      _buildDetailRow('Р’СЂРµРјСЏ', _formatTime(booking.eventDate)),
                      _buildDetailRow('РђРґСЂРµСЃ', booking.address ?? 'РќРµ СѓРєР°Р·Р°РЅ'),
                      _buildDetailRow(
                        'РЈС‡Р°СЃС‚РЅРёРєРё',
                        '${booking.participantsCount} С‡РµР».',
                      ),
                      _buildDetailRow(
                        'РЎС‚РѕРёРјРѕСЃС‚СЊ',
                        '${booking.totalPrice.toInt() ?? 0}в‚Ѕ',
                      ),
                      _buildDetailRow('РЎС‚Р°С‚СѓСЃ', _getStatusText(booking.status)),
                      if (booking.description != null && booking.description!.isNotEmpty)
                        _buildDetailRow('РћРїРёСЃР°РЅРёРµ', booking.description!),
                      if (booking.comment != null && booking.comment!.isNotEmpty)
                        _buildDetailRow('РљРѕРјРјРµРЅС‚Р°СЂРёР№', booking.comment!),
                      if (booking.advancePaid == true)
                        _buildDetailRow(
                          'РђРІР°РЅСЃ',
                          '${booking.advanceAmount?.toInt() ?? 0}в‚Ѕ',
                        ),
                    ],
                  ),
                ),
              ),

              // РљРЅРѕРїРєРё РґРµР№СЃС‚РІРёР№
              if (booking.status == BookingStatus.pending ||
                  booking.status == BookingStatus.confirmed)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancelBooking(booking),
                        child: const Text('РћС‚РјРµРЅРёС‚СЊ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // TODO(developer): Р РµР°Р»РёР·РѕРІР°С‚СЊ С‡Р°С‚ СЃ СЃРїРµС†РёР°Р»РёСЃС‚РѕРј
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Р§Р°С‚ Р±СѓРґРµС‚ РґРѕСЃС‚СѓРїРµРЅ РїРѕСЃР»Рµ СЂРµР°Р»РёР·Р°С†РёРё',
                              ),
                            ),
                          );
                        },
                        child: const Text('РќР°РїРёСЃР°С‚СЊ'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  String _formatDate(DateTime? date) {
    if (date == null) return 'РќРµ СѓРєР°Р·Р°РЅР°';
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'РќРµ СѓРєР°Р·Р°РЅРѕ';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'РћР¶РёРґР°РµС‚ РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ';
      case BookingStatus.confirmed:
        return 'РџРѕРґС‚РІРµСЂР¶РґРµРЅР°';
      case BookingStatus.completed:
        return 'Р’С‹РїРѕР»РЅРµРЅР°';
      case BookingStatus.cancelled:
        return 'РћС‚РјРµРЅРµРЅР°';
      case BookingStatus.rejected:
        return 'РћС‚РєР»РѕРЅРµРЅР°';
    }
  }

  @override
  Widget build(BuildContext context) => BackButtonHandler(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('РњРѕРё Р·Р°СЏРІРєРё'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'РђРєС‚РёРІРЅС‹Рµ'),
                Tab(text: 'Р—Р°РІРµСЂС€РµРЅРЅС‹Рµ'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Р¤РёР»СЊС‚СЂС‹
              Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: _selectedFilter == filter,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

              // РЎРїРёСЃРѕРє Р·Р°СЏРІРѕРє
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsList(
                      _filteredBookings
                          .where(
                            (b) =>
                                b.status == BookingStatus.pending ||
                                b.status == BookingStatus.confirmed,
                          )
                          .toList(),
                    ),
                    _buildBookingsList(
                      _filteredBookings
                          .where(
                            (b) =>
                                b.status == BookingStatus.completed ||
                                b.status == BookingStatus.cancelled ||
                                b.status == BookingStatus.rejected,
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              context.push('/create_booking');
            },
            child: const Icon(Icons.add),
          ),
        ),
      );

  Widget _buildBookingsList(List<Booking> bookings) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Р—Р°СЏРІРєРё РЅРµ РЅР°Р№РґРµРЅС‹',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'РЎРѕР·РґР°Р№С‚Рµ РЅРѕРІСѓСЋ Р·Р°СЏРІРєСѓ, РЅР°Р№РґСЏ СЃРїРµС†РёР°Р»РёСЃС‚Р°',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/search'),
              child: const Text('РќР°Р№С‚Рё СЃРїРµС†РёР°Р»РёСЃС‚Р°'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BookingCard(
              booking: booking,
              onTap: () => _showBookingDetails(booking),
              onCancel: booking.status == BookingStatus.pending ||
                      booking.status == BookingStatus.confirmed
                  ? () => _cancelBooking(booking)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

