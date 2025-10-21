import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/review_service.dart';

/// Экран ответа специалиста на отзыв
class RespondToReviewScreen extends StatefulWidget {
  const RespondToReviewScreen({super.key, required this.review});
  final Review review;

  @override
  State<RespondToReviewScreen> createState() => _RespondToReviewScreenState();
}

class _RespondToReviewScreenState extends State<RespondToReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _responseController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.review.response != null) {
      _responseController.text = widget.review.response!;
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _reviewService.addSpecialistResponse(
        reviewId: widget.review.id,
        response: _responseController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ответ добавлен')));

      Navigator.pop(context, true); // Возвращаем true для обновления
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.review.hasResponse;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать ответ' : 'Ответить на отзыв'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информация об отзыве
              _buildReviewInfo(),

              const SizedBox(height: 24),

              // Поле для ответа
              _buildResponseField(),

              const SizedBox(height: 32),

              // Кнопка отправки
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewInfo() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.review.customerAvatar != null
                    ? NetworkImage(widget.review.customerAvatar!)
                    : null,
                child: widget.review.customerAvatar == null
                    ? Text(
                        widget.review.customerName.isNotEmpty
                            ? widget.review.customerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.review.customerName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.review.formattedCreatedAt,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Рейтинг
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < widget.review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (widget.review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(widget.review.comment, style: const TextStyle(fontSize: 16)),
          ],
          if (widget.review.eventTitle != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    widget.review.eventTitle!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _buildResponseField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Ваш ответ',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _responseController,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: 'Поблагодарите за отзыв или ответьте на вопросы...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Введите ответ';
          }
          if (value.trim().length > 1000) {
            return 'Ответ не должен превышать 1000 символов';
          }
          return null;
        },
      ),
      const SizedBox(height: 8),
      Text(
        '${_responseController.text.length}/1000',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      ),
    ],
  );

  Widget _buildSubmitButton() {
    final isEditing = widget.review.hasResponse;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitResponse,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                isEditing ? 'Обновить ответ' : 'Отправить ответ',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
