import 'package:flutter/material.dart';
import '../models/contract.dart';
import '../services/contract_service.dart';

class ContractSigningWidget extends StatefulWidget {
  const ContractSigningWidget({
    super.key,
    required this.contract,
    required this.currentUserId,
    this.onSigned,
  });
  final Contract contract;
  final String currentUserId;
  final VoidCallback? onSigned;

  @override
  State<ContractSigningWidget> createState() => _ContractSigningWidgetState();
}

class _ContractSigningWidgetState extends State<ContractSigningWidget> {
  final ContractService _contractService = ContractService();
  bool _isSigning = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Подписание договора',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Статус подписей
              _buildSignaturesStatus(),
              const SizedBox(height: 16),

              // Ошибка
              if (_errorMessage != null) _buildErrorMessage(),
              if (_errorMessage != null) const SizedBox(height: 16),

              // Кнопка подписания
              if (_canSign())
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSigning ? null : _signContract,
                    icon: _isSigning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit),
                    label: Text(
                      _isSigning ? 'Подписание...' : 'Подписать договор',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildSignaturesStatus() => Column(
        children: [
          // Заказчик
          _buildSignatureRow(
            'Заказчик',
            widget.contract.signedByCustomer,
            widget.contract.customerId == widget.currentUserId,
          ),
          const SizedBox(height: 12),
          // Специалист
          _buildSignatureRow(
            'Специалист',
            widget.contract.signedBySpecialist,
            widget.contract.specialistId == widget.currentUserId,
          ),
        ],
      );

  Widget _buildSignatureRow(String label, bool isSigned, bool isCurrentUser) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSigned ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSigned ? Colors.green.shade300 : Colors.orange.shade300,
          ),
        ),
        child: Row(
          children: [
            // Чекбокс
            Checkbox(
              value: isSigned,
              onChanged: null, // Только для отображения
              activeColor: Colors.green,
              checkColor: Colors.white,
            ),
            const SizedBox(width: 12),
            // Иконка статуса
            Icon(
              isSigned ? Icons.check_circle : Icons.pending,
              color: isSigned ? Colors.green.shade700 : Colors.orange.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            // Текст
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    isSigned ? 'Подписан' : 'Ожидает подписи',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSigned
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                  ),
                  if (isCurrentUser && !isSigned)
                    Text(
                      'Вы можете подписать этот договор',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildErrorMessage() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade600),
              ),
            ),
          ],
        ),
      );

  bool _canSign() =>
      widget.contract.canSignBy(widget.currentUserId) &&
      (widget.contract.status == ContractStatus.pending ||
          widget.contract.status == ContractStatus.draft);

  Future<void> _signContract() async {
    setState(() {
      _isSigning = true;
      _errorMessage = null;
    });

    try {
      await _contractService.signContract(
        contractId: widget.contract.id,
        userId: widget.currentUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Договор успешно подписан'),
            backgroundColor: Colors.green,
          ),
        );

        // Вызываем callback для обновления UI
        widget.onSigned?.call();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при подписании договора: $e';
      });
    } finally {
      setState(() {
        _isSigning = false;
      });
    }
  }
}
