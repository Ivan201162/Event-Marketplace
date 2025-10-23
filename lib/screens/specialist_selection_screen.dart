import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/specialist.dart';
import '../services/proposal_service.dart';
import '../services/specialist_service.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';

class SpecialistSelectionScreen extends StatefulWidget {
  const SpecialistSelectionScreen({
    super.key,
    required this.customerId,
    required this.eventId,
    this.message,
  });
  final String customerId;
  final String eventId;
  final String? message;

  @override
  State<SpecialistSelectionScreen> createState() =>
      _SpecialistSelectionScreenState();
}

class _SpecialistSelectionScreenState extends State<SpecialistSelectionScreen> {
  final List<String> _selectedSpecialistIds = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.message != null) {
      _messageController.text = widget.message!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Выбор специалистов'),
          actions: [
            if (_selectedSpecialistIds.isNotEmpty)
              TextButton(
                onPressed: _isLoading ? null : _sendProposal,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Отправить'),
              ),
          ],
        ),
        body: Column(
          children: [
            // Информация о заказчике и событии
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Предложение для заказчика',
                    style: Theme.of(
                      context,
                    )
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Событие: ${widget.eventId}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  if (_selectedSpecialistIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Выбрано специалистов: ${_selectedSpecialistIds.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ],
              ),
            ),

            // Поле для сообщения
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Сообщение (необязательно)',
                  hintText: 'Добавьте комментарий к предложению...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
                maxLines: 3,
              ),
            ),

            // Список специалистов
            Expanded(child: _buildSpecialistsList()),
          ],
        ),
        floatingActionButton: _selectedSpecialistIds.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _isLoading ? null : _sendProposal,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
                label:
                    Text(_isLoading ? 'Отправка...' : 'Отправить предложение'),
                backgroundColor: Colors.blue,
              )
            : null,
      );

  Widget _buildSpecialistsList() => StreamBuilder<List<Specialist>>(
        stream: SpecialistService.getAllSpecialists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return CustomErrorWidget(
                message: snapshot.error.toString(),
                onRetry: () => setState(() {}));
          }

          final specialists = snapshot.data ?? [];

          if (specialists.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет доступных специалистов',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: specialists.length,
            itemBuilder: (context, index) {
              final specialist = specialists[index];
              final isSelected = _selectedSpecialistIds.contains(specialist.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _selectedSpecialistIds.add(specialist.id);
                      } else {
                        _selectedSpecialistIds.remove(specialist.id);
                      }
                    });
                  },
                  title: Text(
                    specialist.name,
                    style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(specialist.specialization),
                      if (specialist.rating > 0)
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(specialist.rating.toStringAsFixed(1)),
                          ],
                        ),
                    ],
                  ),
                  secondary: CircleAvatar(
                    backgroundImage: specialist.photoUrl != null
                        ? NetworkImage(specialist.photoUrl!)
                        : null,
                    child: specialist.photoUrl == null
                        ? Text(specialist.name.isNotEmpty
                            ? specialist.name[0]
                            : '?')
                        : null,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            },
          );
        },
      );

  Future<void> _sendProposal() async {
    if (_selectedSpecialistIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы одного специалиста'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final proposalId = await ProposalService.createProposal(
        customerId: widget.customerId,
        eventId: widget.eventId,
        specialistIds: _selectedSpecialistIds,
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
        metadata: {
          'organizerName': FirebaseAuth.instance.currentUser?.displayName,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Предложение успешно отправлено!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, proposalId);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка отправки предложения: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
