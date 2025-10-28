import 'package:event_marketplace_app/models/contract.dart';
import 'package:event_marketplace_app/services/contract_service.dart';
import 'package:event_marketplace_app/widgets/contract_content_widget.dart';
import 'package:event_marketplace_app/widgets/signature_widget.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class ContractDetailsScreen extends StatefulWidget {
  const ContractDetailsScreen({required this.contract, super.key});
  final Contract contract;

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  final ContractService _contractService = ContractService();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    exportBackgroundColor: Colors.white,
  );

  bool _isSigning = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Договор ${widget.contract.contractNumber}'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          actions: [
            if (widget.contract.status == ContractStatus.signed)
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _downloadContract,
                tooltip: 'Скачать договор',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Статус договора
                    _buildStatusCard(),
                    const SizedBox(height: 16),

                    // Информация о договоре
                    _buildContractInfo(),
                    const SizedBox(height: 16),

                    // Содержимое договора
                    ContractContentWidget(contract: widget.contract),
                    const SizedBox(height: 16),

                    // Информация о сторонах
                    if (widget.contract.partiesInfo != null)
                      _buildPartiesInfo(),
                    const SizedBox(height: 16),

                    // Список услуг
                    if (widget.contract.servicesList != null)
                      _buildServicesList(),
                    const SizedBox(height: 16),

                    // Ошибка
                    if (_errorMessage != null) _buildErrorMessage(),

                    // Кнопки действий
                    _buildActionButtons(),
                  ],
                ),
              ),
      );

  Widget _buildStatusCard() => Card(
        color: widget.contract.status.statusColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(_getStatusIcon(),
                  color: widget.contract.status.statusColor, size: 32,),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статус договора',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                    Text(
                      widget.contract.status.statusText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: widget.contract.status.statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              if (widget.contract.signedAt != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Подписан',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                    Text(
                      _formatDate(widget.contract.signedAt!),
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              // Статус подписей
              if (widget.contract.status == ContractStatus.pending ||
                  widget.contract.status == ContractStatus.draft)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Статус подписей',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSignatureStatus(
                            'Заказчик', widget.contract.signedByCustomer,),
                        const SizedBox(width: 8),
                        _buildSignatureStatus(
                            'Специалист', widget.contract.signedBySpecialist,),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      );

  Widget _buildContractInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Информация о договоре',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Номер договора', widget.contract.contractNumber),
              _buildInfoRow('Тип договора', _getContractTypeName()),
              _buildInfoRow(
                  'Дата создания', _formatDate(widget.contract.createdAt),),
              _buildInfoRow(
                  'Действует до', _formatDate(widget.contract.expiresAt),),
              if (widget.contract.totalAmount != null)
                _buildInfoRow('Общая сумма',
                    '${widget.contract.totalAmount!.toStringAsFixed(2)} ₽',),
            ],
          ),
        ),
      );

  Widget _buildPartiesInfo() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Стороны договора',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...widget.contract.partiesInfo!.entries.map((entry) {
                final party = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        party.name,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        party.type,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                      if (party.inn != null) ...[
                        const SizedBox(height: 4),
                        Text('ИНН: ${party.inn}'),
                      ],
                      if (party.phone != null) ...[
                        const SizedBox(height: 4),
                        Text('Телефон: ${party.phone}'),
                      ],
                      if (party.email != null) ...[
                        const SizedBox(height: 4),
                        Text('Email: ${party.email}'),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );

  Widget _buildServicesList() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Перечень услуг',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...widget.contract.servicesList!.map(
                (service) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: Theme.of(
                                context,
                              )
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (service.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(service.description,
                                  style: Theme.of(context).textTheme.bodySmall,),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${service.quantity} ${service.unit ?? 'шт.'} × ${service.price.toStringAsFixed(2)} ₽',
                              style: Theme.of(
                                context,
                              )
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${service.total.toStringAsFixed(2)} ₽',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
              child: Text(_errorMessage!,
                  style: TextStyle(color: Colors.red.shade600),),
            ),
          ],
        ),
      );

  Widget _buildActionButtons() {
    // Получаем ID текущего пользователя (в реальном приложении из контекста аутентификации)
    const currentUserId = 'current_user_id';
    final canSign = widget.contract.canSignBy(currentUserId);

    return Column(
      children: [
        if (canSign &&
            (widget.contract.status == ContractStatus.pending ||
                widget.contract.status == ContractStatus.draft))
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSigning ? null : _showSignatureDialog,
              icon: _isSigning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.edit),
              label: Text(_isSigning ? 'Подписание...' : 'Подписать договор'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _downloadContract,
            icon: const Icon(Icons.download),
            label: const Text('Скачать договор'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ),
            Expanded(
                child:
                    Text(value, style: Theme.of(context).textTheme.bodyMedium),),
          ],
        ),
      );

  IconData _getStatusIcon() {
    switch (widget.contract.status) {
      case ContractStatus.draft:
        return Icons.edit;
      case ContractStatus.pending:
        return Icons.schedule;
      case ContractStatus.signed:
        return Icons.check_circle;
      case ContractStatus.active:
        return Icons.play_circle;
      case ContractStatus.completed:
        return Icons.done_all;
      case ContractStatus.cancelled:
        return Icons.cancel;
      case ContractStatus.expired:
        return Icons.access_time;
    }
  }

  String _getContractTypeName() {
    switch (widget.contract.type) {
      case ContractType.service:
        return 'Договор на оказание услуг';
      case ContractType.rental:
        return 'Договор аренды';
      case ContractType.supply:
        return 'Договор поставки';
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  Widget _buildSignatureStatus(String label, bool isSigned) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSigned ? Colors.green.shade100 : Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSigned ? Colors.green.shade300 : Colors.orange.shade300,),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSigned ? Icons.check_circle : Icons.pending,
              size: 16,
              color: isSigned ? Colors.green.shade700 : Colors.orange.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color:
                    isSigned ? Colors.green.shade700 : Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  void _showSignatureDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => SignatureWidget(
        signatureController: _signatureController,
        onSign: _signContract,
        onCancel: () {
          _signatureController.clear();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _signContract() async {
    if (_signatureController.isEmpty) {
      setState(() {
        _errorMessage = 'Необходимо поставить подпись';
      });
      return;
    }

    setState(() {
      _isSigning = true;
      _errorMessage = null;
    });

    try {
      // Конвертируем подпись в base64
      final signatureData = await _signatureController.toPngBytes();
      final signatureBase64 = signatureData != null
          ? 'data:image/png;base64,$signatureData'
          : '';

      // Подписываем договор
      await _contractService.signContract(
        contractId: widget.contract.id,
        userId: 'current_user_id', // Получить из контекста аутентификации
      );

      if (mounted) {
        Navigator.of(context).pop();
        _signatureController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Договор успешно подписан'),
              backgroundColor: Colors.green,),
        );

        // Обновляем экран
        setState(() {});
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

  Future<void> _downloadContract() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pdfPath =
          await _contractService.generateContractPDF(widget.contract.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Договор сохранен: $pdfPath'),
              backgroundColor: Colors.green,),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при скачивании договора: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }
}
