import 'package:flutter/material.dart';
import '../models/contract.dart';
import '../services/contract_service.dart';
import '../widgets/contract_signing_widget.dart';

class ContractScreen extends StatefulWidget {
  const ContractScreen({super.key, required this.contractId, required this.currentUserId});
  final String contractId;
  final String currentUserId;

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  final ContractService _contractService = ContractService();
  Contract? _contract;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContract();
  }

  Future<void> _loadContract() async {
    try {
      final contract = await _contractService.getContract(widget.contractId);
      setState(() {
        _contract = contract;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки договора: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Договор'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _contract == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Договор не найден',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadContract, child: const Text('Повторить')),
              ],
            ),
          )
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
                _buildContractContent(),
                const SizedBox(height: 16),

                // Виджет подписания
                ContractSigningWidget(
                  contract: _contract!,
                  currentUserId: widget.currentUserId,
                  onSigned: _loadContract,
                ),
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
    color: _contract!.status.statusColor.withValues(alpha: 0.1),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(_getStatusIcon(), color: _contract!.status.statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Статус договора',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                Text(
                  _contract!.status.statusText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _contract!.status.statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_contract!.signedAt != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Подписан',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                Text(
                  _formatDate(_contract!.signedAt!),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Номер договора', _contract!.contractNumber),
          _buildInfoRow('Тип договора', _getContractTypeName()),
          _buildInfoRow('Дата создания', _formatDate(_contract!.createdAt)),
          _buildInfoRow('Действует до', _formatDate(_contract!.expiresAt)),
          if (_contract!.totalAmount != null)
            _buildInfoRow('Общая сумма', '${_contract!.totalAmount!.toStringAsFixed(2)} ₽'),
        ],
      ),
    ),
  );

  Widget _buildContractContent() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Содержимое договора',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(_contract!.content, style: Theme.of(context).textTheme.bodyMedium),
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
          child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade600)),
        ),
      ],
    ),
  );

  Widget _buildActionButtons() => Column(
    children: [
      SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _downloadContract,
          icon: const Icon(Icons.download),
          label: const Text('Скачать договор'),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    ],
  );

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    ),
  );

  IconData _getStatusIcon() {
    switch (_contract!.status) {
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
    switch (_contract!.type) {
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

  Future<void> _downloadContract() async {
    try {
      final pdfPath = await _contractService.generateContractPDF(_contract!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Договор сохранен: $pdfPath'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при скачивании договора: $e';
      });
    }
  }
}
