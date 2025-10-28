import 'package:event_marketplace_app/models/review.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/providers/review_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen for writing a review
class WriteReviewScreen extends ConsumerStatefulWidget {

  const WriteReviewScreen(
      {required this.specialist, super.key, this.bookingId,});
  final Specialist specialist;
  final String? bookingId;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  int _rating = 5;
  final List<String> _images = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Написать отзыв'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitReview,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Отправить'),
          ),
        ],
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
                child: Text('Войдите в аккаунт для написания отзыва'),);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Specialist info
                  _buildSpecialistInfo(),

                  const SizedBox(height: 24),

                  // Rating section
                  _buildRatingSection(),

                  const SizedBox(height: 24),

                  // Review text
                  _buildReviewTextSection(),

                  const SizedBox(height: 24),

                  // Images section
                  _buildImagesSection(),

                  const SizedBox(height: 24),

                  // Guidelines
                  _buildGuidelines(),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки',
                  style: TextStyle(fontSize: 18, color: Colors.red[700]),),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(currentUserProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialistInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: widget.specialist.avatarUrl != null
                  ? NetworkImage(widget.specialist.avatarUrl!)
                  : null,
              child: widget.specialist.avatarUrl == null
                  ? Text(widget.specialist.name.substring(0, 1))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.specialist.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold,),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.specialist.specialization,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.specialist.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${widget.specialist.completedEvents} отзывов)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Оцените работу специалиста',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _rating = index + 1;
                });
              },
              child: Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: Colors.orange,
                size: 40,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _getRatingText(_rating),
          style: TextStyle(
              color: _getRatingColor(_rating), fontWeight: FontWeight.w500,),
        ),
      ],
    );
  }

  Widget _buildReviewTextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Расскажите о вашем опыте',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _textController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Поделитесь подробностями о работе специалиста...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Пожалуйста, напишите отзыв';
            }
            if (value.trim().length < 10) {
              return 'Отзыв должен содержать минимум 10 символов';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          '${_textController.text.length}/500',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Добавить фото (необязательно)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_images.isEmpty)
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: _addImage,
              borderRadius: BorderRadius.circular(8),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Добавить фото', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length + 1,
              itemBuilder: (context, index) {
                if (index == _images.length) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: _addImage,
                      borderRadius: BorderRadius.circular(8),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 24, color: Colors.grey),
                          Text('Добавить',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),),
                        ],
                      ),
                    ),
                  );
                }

                return Container(
                  width: 100,
                  margin: EdgeInsets.only(
                      right: index < _images.length - 1 ? 8 : 0,),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _images[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _images.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16,),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildGuidelines() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Рекомендации',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Будьте честными и объективными\n'
              '• Опишите конкретные детали работы\n'
              '• Избегайте оскорблений и нецензурной лексики\n'
              '• Не указывайте личную информацию\n'
              '• Отзыв будет опубликован после модерации',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Отлично';
      case 4:
        return 'Хорошо';
      case 3:
        return 'Удовлетворительно';
      case 2:
        return 'Плохо';
      case 1:
        return 'Очень плохо';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  void _addImage() {
    // TODO: Implement image picker
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Добавление фото пока не реализовано')),);
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final review = Review(
        id: '', // Will be set by Firestore
        specialistId: widget.specialist.id,
        specialistName: widget.specialist.name,
        clientId: currentUser.uid,
        clientName: currentUser.name,
        clientAvatarUrl: currentUser.avatarUrl,
        rating: _rating,
        text: _textController.text.trim(),
        images: _images,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        bookingId: widget.bookingId,
      );

      final reviewService = ref.read(reviewServiceProvider);
      final reviewId = await reviewService.createReview(review);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          const SnackBar(content: Text('Отзыв отправлен на модерацию')),);
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
