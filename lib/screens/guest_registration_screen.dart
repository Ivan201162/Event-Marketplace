import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guest.dart';
import '../services/guest_service.dart';

/// Экран регистрации гостей
class GuestRegistrationScreen extends ConsumerStatefulWidget {
  final String eventId;

  const GuestRegistrationScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<GuestRegistrationScreen> createState() => _GuestRegistrationScreenState();
}

class _GuestRegistrationScreenState extends ConsumerState<GuestRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final GuestService _guestService = GuestService();
  
  bool _isLoading = false;
  GuestEvent? _event;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация гостя'),
      ),
      body: _event == null
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Информация о событии
          _buildEventInfo(),
          
          const SizedBox(height: 24),
          
          // Форма регистрации
          _buildRegistrationForm(),
          
          const SizedBox(height: 24),
          
          // Кнопка регистрации
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _registerGuest,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Зарегистрировать гостя'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Информация о событии',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Название события
            Row(
              children: [
                const Icon(Icons.event, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _event!.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Дата и время
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_formatDate(_event!.startTime)} - ${_formatTime(_event!.endTime)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Место
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _event!.location,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Организатор
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Организатор: ${_event!.organizerName}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Свободные места
            Row(
              children: [
                const Icon(Icons.people, size: 20, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Свободных мест: ${_event!.availableSpots} из ${_event!.maxGuests}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Данные гостя',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Имя
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя *',
                  border: OutlineInputBorder(),
                  hintText: 'Введите имя гостя',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите имя';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  hintText: 'Введите email гостя',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Пожалуйста, введите email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Пожалуйста, введите корректный email';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Телефон
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  border: OutlineInputBorder(),
                  hintText: 'Введите телефон гостя',
                ),
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 16),
              
              // Информация о регистрации
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Информация о регистрации',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• После регистрации гость получит QR код для входа на мероприятие\n'
                      '• Гость сможет загружать поздравления и фото\n'
                      '• Вы сможете отслеживать статус гостя в реальном времени',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadEvent() async {
    try {
      final event = await _guestService.getGuestEvent(widget.eventId);
      if (event != null) {
        setState(() {
          _event = event;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Событие не найдено'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки события: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _registerGuest() async {
    if (!_formKey.currentState!.validate()) return;

    // Проверяем, есть ли свободные места
    if (!_event!.hasAvailableSpots) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет свободных мест на мероприятии'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final guestId = await _guestService.registerGuest(
        eventId: widget.eventId,
        guestName: _nameController.text.trim(),
        guestEmail: _emailController.text.trim(),
        guestPhone: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
      );

      if (guestId != null) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Гость успешно зарегистрирован'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка регистрации гостя'),
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
