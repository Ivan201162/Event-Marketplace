import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist_profile_extended.dart';
import '../services/specialist_profile_extended_service.dart';

/// Виджет редактора FAQ
class FAQEditorWidget extends ConsumerStatefulWidget {
  final String specialistId;
  final FAQItem? existingFAQ;
  final VoidCallback onFAQSaved;

  const FAQEditorWidget({
    super.key,
    required this.specialistId,
    this.existingFAQ,
    required this.onFAQSaved,
  });

  @override
  ConsumerState<FAQEditorWidget> createState() => _FAQEditorWidgetState();
}

class _FAQEditorWidgetState extends ConsumerState<FAQEditorWidget> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  String _selectedCategory = 'general';
  bool _isPublished = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingFAQ != null) {
      _questionController.text = widget.existingFAQ!.question;
      _answerController.text = widget.existingFAQ!.answer;
      _orderController.text = widget.existingFAQ!.order.toString();
      _selectedCategory = widget.existingFAQ!.category;
      _isPublished = widget.existingFAQ!.isPublished;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            AppBar(
              title: Text(widget.existingFAQ == null ? 'Новый вопрос' : 'Редактировать вопрос'),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : _saveFAQ,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Вопрос
                    TextField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        labelText: 'Вопрос *',
                        border: OutlineInputBorder(),
                        hintText: 'Введите часто задаваемый вопрос',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    
                    // Ответ
                    TextField(
                      controller: _answerController,
                      decoration: const InputDecoration(
                        labelText: 'Ответ *',
                        border: OutlineInputBorder(),
                        hintText: 'Введите подробный ответ на вопрос',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    
                    // Категория и порядок
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Категория',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'general', child: Text('Общие вопросы')),
                              DropdownMenuItem(value: 'pricing', child: Text('Цены и оплата')),
                              DropdownMenuItem(value: 'booking', child: Text('Бронирование')),
                              DropdownMenuItem(value: 'services', child: Text('Услуги')),
                              DropdownMenuItem(value: 'equipment', child: Text('Оборудование')),
                              DropdownMenuItem(value: 'cancellation', child: Text('Отмена и возврат')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _orderController,
                            decoration: const InputDecoration(
                              labelText: 'Порядок',
                              border: OutlineInputBorder(),
                              hintText: '0',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Настройки
                    _buildSettingsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Настройки',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        SwitchListTile(
          title: const Text('Опубликовать вопрос'),
          subtitle: const Text('Клиенты смогут видеть этот вопрос'),
          value: _isPublished,
          onChanged: (value) {
            setState(() {
              _isPublished = value;
            });
          },
        ),
      ],
    );
  }

  void _saveFAQ() async {
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();
    final orderText = _orderController.text.trim();
    
    if (question.isEmpty || answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните вопрос и ответ')),
      );
      return;
    }

    final order = int.tryParse(orderText) ?? 0;

    setState(() {
      _isSaving = true;
    });

    try {
      final service = ref.read(specialistProfileExtendedServiceProvider);
      
      if (widget.existingFAQ != null) {
        // Обновляем существующий FAQ
        final updatedFAQ = widget.existingFAQ!.copyWith(
          question: question,
          answer: answer,
          category: _selectedCategory,
          order: order,
          isPublished: _isPublished,
        );
        
        await service.updateFAQItem(widget.specialistId, updatedFAQ);
      } else {
        // Создаём новый FAQ
        await service.addFAQItem(
          specialistId: widget.specialistId,
          question: question,
          answer: answer,
          category: _selectedCategory,
          order: order,
          isPublished: _isPublished,
        );
      }

      Navigator.pop(context);
      widget.onFAQSaved();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingFAQ == null 
                ? 'Вопрос добавлен' 
                : 'Вопрос обновлён'
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
