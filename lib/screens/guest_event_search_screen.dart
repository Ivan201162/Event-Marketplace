import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../services/guest_service.dart';
import '../services/event_service.dart';
import '../core/feature_flags.dart';

/// Экран поиска события по ссылке/QR для гостей
class GuestEventSearchScreen extends ConsumerStatefulWidget {
  const GuestEventSearchScreen({super.key});

  @override
  ConsumerState<GuestEventSearchScreen> createState() =>
      _GuestEventSearchScreenState();
}

class _GuestEventSearchScreenState
    extends ConsumerState<GuestEventSearchScreen> {
  final TextEditingController _accessCodeController = TextEditingController();
  final GuestService _guestService = GuestService();
  final EventService _eventService = EventService();
  Event? _foundEvent;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _accessCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.guestModeEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Гостевой доступ'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Гостевой режим временно недоступен',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступ к событию'),
        backgroundColor: Colors.blue[50],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildAccessCodeInput(),
            const SizedBox(height: 24),
            if (_isLoading) _buildLoadingIndicator(),
            if (_errorMessage != null) _buildErrorMessage(),
            if (_foundEvent != null) _buildEventCard(),
            const SizedBox(height: 24),
            _buildQRScannerButton(),
            const SizedBox(height: 24),
            _buildHelpSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_scanner, color: Colors.blue[600], size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Доступ к событию',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Введите код доступа или отсканируйте QR-код, чтобы получить доступ к событию',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessCodeInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Код доступа',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accessCodeController,
              decoration: InputDecoration(
                hintText: 'Введите код доступа',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchEvent,
                ),
              ),
              onSubmitted: (_) => _searchEvent(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _searchEvent,
                icon: const Icon(Icons.search),
                label: const Text('Найти событие'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Поиск события...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard() {
    if (_foundEvent == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Colors.green[600], size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _foundEvent!.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _foundEvent!.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildEventDetails(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _joinEvent,
                icon: const Icon(Icons.login),
                label: const Text('Присоединиться к событию'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetails() {
    return Column(
      children: [
        _buildDetailRow(
          Icons.calendar_today,
          'Дата',
          '${_foundEvent!.date.day}.${_foundEvent!.date.month}.${_foundEvent!.date.year}',
        ),
        _buildDetailRow(
          Icons.access_time,
          'Время',
          '${_foundEvent!.date.hour.toString().padLeft(2, '0')}:${_foundEvent!.date.minute.toString().padLeft(2, '0')}',
        ),
        _buildDetailRow(
          Icons.location_on,
          'Место',
          _foundEvent!.location,
        ),
        if (_foundEvent!.price > 0)
          _buildDetailRow(
            Icons.attach_money,
            'Цена',
            '${_foundEvent!.price.toStringAsFixed(0)} ₽',
          ),
        _buildDetailRow(
          Icons.people,
          'Участники',
          '${_foundEvent!.currentParticipants}/${_foundEvent!.maxParticipants}',
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScannerButton() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QR-код',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Отсканируйте QR-код для быстрого доступа к событию',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _scanQRCode,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Сканировать QR-код'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Помощь',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              Icons.info,
              'Что такое код доступа?',
              'Код доступа - это уникальный код, который позволяет гостям получить доступ к событию без регистрации.',
            ),
            _buildHelpItem(
              Icons.qr_code,
              'Как использовать QR-код?',
              'Нажмите "Сканировать QR-код" и наведите камеру на QR-код события.',
            ),
            _buildHelpItem(
              Icons.help,
              'Нет кода доступа?',
              'Обратитесь к организатору события за кодом доступа или QR-кодом.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchEvent() async {
    final accessCode = _accessCodeController.text.trim();
    if (accessCode.isEmpty) {
      setState(() {
        _errorMessage = 'Введите код доступа';
        _foundEvent = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foundEvent = null;
    });

    try {
      final event = await _guestService.getEventByAccessCode(accessCode);
      if (event != null) {
        setState(() {
          _foundEvent = event;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Событие не найдено или код доступа недействителен';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка поиска события: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _scanQRCode() async {
    // TODO: Реализовать сканирование QR-кода
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Функция сканирования QR-кода будет добавлена в следующих версиях'),
      ),
    );
  }

  Future<void> _joinEvent() async {
    if (_foundEvent == null) return;

    try {
      final accessCode = _accessCodeController.text.trim();
      final success = await _guestService.useAccessCode(accessCode);

      if (success) {
        // TODO: Перейти к экрану гостевого доступа к событию
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Добро пожаловать на событие "${_foundEvent!.title}"!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось получить доступ к событию'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
