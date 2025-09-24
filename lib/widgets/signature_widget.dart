import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureWidget extends StatelessWidget {
  final SignatureController signatureController;
  final VoidCallback onSign;
  final VoidCallback onCancel;

  const SignatureWidget({
    super.key,
    required this.signatureController,
    required this.onSign,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Заголовок
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Электронная подпись',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                  ),
                ],
              ),
              const Divider(),

              // Инструкция
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Поставьте свою подпись в поле ниже. Подпись будет прикреплена к договору.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Поле для подписи
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Signature(
                    controller: signatureController,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        signatureController.clear();
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Очистить'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: signatureController.isEmpty ? null : onSign,
                      icon: const Icon(Icons.check),
                      label: const Text('Подписать'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
