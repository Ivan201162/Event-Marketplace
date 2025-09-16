import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../providers/auth_providers.dart';
import '../providers/booking_providers.dart';
import '../providers/event_providers.dart';

/// Экран создания бронирования
class CreateBookingScreen extends ConsumerStatefulWidget {
  final Event event;

  const CreateBookingScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Заполняем email текущего пользователя
    final currentUser = ref.read(currentUserProvider);
    currentUser.whenData((user) {
      if (user != null && user.email != null) {
        _emailController.text = user.email!;
        ref.read(createBookingProvider.notifier).updateUserEmail(user.email);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createBookingState = ref.watch(createBookingProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бронирование'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Пользователь не авторизован'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Информация о событии
                  _buildEventInfo(),

                  const SizedBox(height: 24),

                  // Количество участников
                  _buildParticipantsSection(),

                  const SizedBox(height: 24),

                  // Контактная информация
                  _buildContactInfoSection(),

                  const SizedBox(height: 24),

                  // Заметки
                  _buildNotesSection(),

                  const SizedBox(height: 24),

                  // Итоговая стоимость
                  _buildTotalPriceSection(),

                  const SizedBox(height: 24),

                  // Кнопка бронирования
                  _buildBookingButton(createBookingState),

                  // Ошибка
                  if (createBookingState.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              createBookingState.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка: $error'),
        ),
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
              'Информация о мероприятии',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  widget.event.categoryIcon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.event.categoryName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  widget.event.formattedDate,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  widget.event.formattedTime,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.event.location,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  widget.event.formattedPrice,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.people, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${widget.event.currentParticipants}/${widget.event.maxParticipants}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection() {
    final createBookingState = ref.watch(createBookingProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Количество участников',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  onPressed: createBookingState.participantsCount > 1
                      ? () {
                          ref
                              .read(createBookingProvider.notifier)
                              .updateParticipantsCount(
                                  createBookingState.participantsCount - 1);
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${createBookingState.participantsCount}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: createBookingState.participantsCount <
                          widget.event.availableSpots
                      ? () {
                          ref
                              .read(createBookingProvider.notifier)
                              .updateParticipantsCount(
                                  createBookingState.participantsCount + 1);
                        }
                      : null,
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                Text(
                  'Максимум: ${widget.event.availableSpots}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Контактная информация',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                ref.read(createBookingProvider.notifier).updateUserEmail(value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите email';
                }
                if (!value.contains('@')) {
                  return 'Введите корректный email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: '+7 (999) 123-45-67',
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                ref.read(createBookingProvider.notifier).updateUserPhone(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Дополнительные заметки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Заметки',
                border: OutlineInputBorder(),
                hintText: 'Дополнительная информация для организатора',
              ),
              maxLines: 3,
              onChanged: (value) {
                ref.read(createBookingProvider.notifier).updateNotes(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalPriceSection() {
    final createBookingState = ref.watch(createBookingProvider);
    final totalPrice =
        widget.event.price * createBookingState.participantsCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Итоговая стоимость',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${createBookingState.participantsCount} × ${widget.event.formattedPrice}'),
                Text(
                  totalPrice == 0
                      ? 'Бесплатно'
                      : '${totalPrice.toStringAsFixed(0)} ₽',
                  style: const TextStyle(
                    fontSize: 20,
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

  Widget _buildBookingButton(CreateBookingState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : _createBooking,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: state.isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Создание бронирования...'),
                ],
              )
            : const Text('Забронировать'),
      ),
    );
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    currentUser.whenData((user) async {
      if (user == null) return;

      final createBookingNotifier = ref.read(createBookingProvider.notifier);
      final bookingId = await createBookingNotifier.createBooking(
        eventId: widget.event.id,
        eventTitle: widget.event.title,
        userId: user.id,
        userName: user.displayNameOrEmail,
        eventDate: widget.event.date,
        eventPrice: widget.event.price,
        organizerId: widget.event.organizerId,
        organizerName: widget.event.organizerName,
      );

      if (bookingId != null && context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Бронирование создано успешно!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}
