import 'package:event_marketplace_app/services/booking_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Экран настроек бронирований специалиста
class ProfileBookingSettingsScreen extends StatefulWidget {
  const ProfileBookingSettingsScreen({super.key});

  @override
  State<ProfileBookingSettingsScreen> createState() => _ProfileBookingSettingsScreenState();
}

class _ProfileBookingSettingsScreenState extends State<ProfileBookingSettingsScreen> {
  final _bookingService = BookingService();
  bool? _autoAcceptBookings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final value = await _bookingService.getAutoAcceptBookings(currentUser.uid);
      if (mounted) {
        setState(() {
          _autoAcceptBookings = value;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading booking settings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  Future<void> _toggleAutoAccept(bool value) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await _bookingService.setAutoAcceptBookings(currentUser.uid, value);
      if (mounted) {
        setState(() {
          _autoAcceptBookings = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Автоподтверждение включено' : 'Автоподтверждение выключено'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error setting autoAcceptBookings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Настройки бронирований'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Автоподтверждение заявок',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _autoAcceptBookings == true
                                          ? 'Новые заявки будут автоматически подтверждаться'
                                          : 'Новые заявки требуют вашего подтверждения',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _autoAcceptBookings ?? false,
                                onChanged: _toggleAutoAccept,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Информация',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'При включенном автоподтверждении заявки клиентов будут автоматически приниматься. При выключенном - вам нужно вручную подтверждать каждую заявку в календаре.',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}


