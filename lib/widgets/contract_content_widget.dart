import 'package:flutter/material.dart';

import '../models/contract.dart';

class ContractContentWidget extends StatelessWidget {
  const ContractContentWidget({super.key, required this.contract});
  final Contract contract;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Содержимое договора',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: () => _showFullContent(context),
                tooltip: 'Открыть полный текст',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SingleChildScrollView(
              child: Text(
                contract.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (contract.terms.isNotEmpty) _buildTermsSection(context),
        ],
      ),
    ),
  );

  Widget _buildTermsSection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Условия договора',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      ...contract.terms.entries.map(
        (entry) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTermTitle(entry.key),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTermValue(entry.value),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue.shade600),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  String _getTermTitle(String key) {
    switch (key) {
      case 'paymentTerms':
        return 'Условия оплаты';
      case 'cancellationPolicy':
        return 'Политика отмены';
      case 'liability':
        return 'Ответственность сторон';
      case 'forceMajeure':
        return 'Форс-мажор';
      default:
        return key;
    }
  }

  String _formatTermValue(value) {
    if (value is Map<String, dynamic>) {
      return value.entries.map((e) => '${_getTermTitle(e.key)}: ${e.value}').join('\n');
    } else if (value is List) {
      return value.join(', ');
    } else {
      return value.toString();
    }
  }

  void _showFullContent(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Договор ${contract.contractNumber}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    contract.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
