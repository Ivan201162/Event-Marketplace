import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/specialist.dart';

/// Widget for booking specialist services
class BookingWidget extends ConsumerStatefulWidget {
  final Specialist specialist;
  final Function(BookingData) onBookingConfirmed;

  const BookingWidget({super.key, required this.specialist, required this.onBookingConfirmed});

  @override
  ConsumerState<BookingWidget> createState() => _BookingWidgetState();
}

class _BookingWidgetState extends ConsumerState<BookingWidget> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedService;
  int _duration = 1;
  String _notes = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: widget.specialist.avatarUrl != null
                      ? NetworkImage(widget.specialist.avatarUrl!)
                      : null,
                  child: widget.specialist.avatarUrl == null
                      ? Text(widget.specialist.name.substring(0, 1))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.specialist.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.specialist.specialization,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Text(
                  'от ${widget.specialist.formattedPrice}/час',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service selection
                  _buildServiceSelection(),

                  const SizedBox(height: 24),

                  // Date selection
                  _buildDateSelection(),

                  const SizedBox(height: 24),

                  // Time selection
                  _buildTimeSelection(),

                  const SizedBox(height: 24),

                  // Duration selection
                  _buildDurationSelection(),

                  const SizedBox(height: 24),

                  // Notes
                  _buildNotesSection(),

                  const SizedBox(height: 24),

                  // Price calculation
                  _buildPriceCalculation(),
                ],
              ),
            ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Итого: ${_calculateTotalPrice()} ₽',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Длительность: $_duration час${_duration > 1 ? 'а' : ''}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _canBook() ? _confirmBooking : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Забронировать'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Выберите услугу', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (widget.specialist.services.isNotEmpty)
          ...widget.specialist.services.map(
            (service) => RadioListTile<String>(
              title: Text(service),
              value: service,
              groupValue: _selectedService,
              onChanged: (value) {
                setState(() {
                  _selectedService = value;
                });
              },
            ),
          )
        else
          const Card(
            child: Padding(padding: EdgeInsets.all(16), child: Text('Услуги не указаны')),
          ),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Выберите дату', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                        : 'Выберите дату',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Выберите время', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedTime != null
                        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                        : 'Выберите время',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedTime != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Длительность', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              onPressed: _duration > 1 ? () => setState(() => _duration--) : null,
              icon: const Icon(Icons.remove),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_duration час${_duration > 1 ? 'а' : ''}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              onPressed: _duration < 8 ? () => setState(() => _duration++) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Дополнительные пожелания',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => setState(() => _notes = value),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Опишите ваши пожелания...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCalculation() {
    final totalPrice = _calculateTotalPrice();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Расчет стоимости',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${widget.specialist.formattedPrice}/час'),
                Text('× $_duration час${_duration > 1 ? 'а' : ''}'),
                Text('$totalPrice ₽'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Итого:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '$totalPrice ₽',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  int _calculateTotalPrice() {
    return (widget.specialist.pricePerHour * _duration).round();
  }

  bool _canBook() {
    return _selectedDate != null && _selectedTime != null && _selectedService != null;
  }

  void _confirmBooking() {
    if (!_canBook()) return;

    final booking = BookingData(
      specialistId: widget.specialist.id,
      specialistName: widget.specialist.name,
      service: _selectedService!,
      date: _selectedDate!,
      time: _selectedTime!,
      duration: _duration,
      totalPrice: _calculateTotalPrice(),
      notes: _notes,
    );

    widget.onBookingConfirmed(booking);
    Navigator.of(context).pop();
  }
}

/// Data class for booking information
class BookingData {
  final String specialistId;
  final String specialistName;
  final String service;
  final DateTime date;
  final TimeOfDay time;
  final int duration;
  final int totalPrice;
  final String notes;

  BookingData({
    required this.specialistId,
    required this.specialistName,
    required this.service,
    required this.date,
    required this.time,
    required this.duration,
    required this.totalPrice,
    required this.notes,
  });
}
