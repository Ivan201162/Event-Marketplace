import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/models/contract.dart';
import 'package:event_marketplace_app/services/contract_service.dart';
import 'package:event_marketplace_app/services/pdf_service.dart';
import 'package:event_marketplace_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Виджет вкладки договора в деталях бронирования
class ContractTabWidget extends ConsumerStatefulWidget {
  const ContractTabWidget({
    required this.booking, required this.contracts, required this.isLoading, required this.onRefresh, super.key,
    this.errorMessage,
  });

  final Booking booking;
  final List<Contract> contracts;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;

  @override
  ConsumerState<ContractTabWidget> createState() => _ContractTabWidgetState();
}

class _ContractTabWidgetState extends ConsumerState<ContractTabWidget> {
  final ContractService _contractService = ContractService();
  final PdfService _pdfService = PdfService();
  final StorageService _storageService = StorageService();

  bool _isGeneratingContract = false;
  bool _isDownloadingPdf = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.errorMessage != null) {
      return _buildErrorState();
    }

    if (widget.contracts.isEmpty) {
      return _buildEmptyState();
    }

    return _buildContractsList();
  }

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error,),
            const SizedBox(height: 16),
            Text('Ошибка загрузки договоров',
                style: Theme.of(context).textTheme.titleLarge,),
            const SizedBox(height: 8),
            Text(
              widget.errorMessage!,
              style: Theme.of(
                context,
              )
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('Договор не создан',
                style: Theme.of(context).textTheme.titleLarge,),
            const SizedBox(height: 8),
            Text(
              'Для данного бронирования договор еще не был сформирован',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_canGenerateContract())
              ElevatedButton.icon(
                onPressed: _isGeneratingContract ? null : _generateContract,
                icon: _isGeneratingContract
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(
                    _isGeneratingContract ? 'Создание...' : 'Создать договор',),
              ),
          ],
        ),
      );

  Widget _buildContractsList() => RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: widget.contracts.length,
          itemBuilder: (context, index) {
            final contract = widget.contracts[index];
            return _buildContractCard(contract);
          },
        ),
      );

  Widget _buildContractCard(Contract contract) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и статус
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.title,
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '№ ${contract.contractNumber}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: contract.status.statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: contract.status.statusColor),
                    ),
                    child: Text(
                      contract.status.statusText,
                      style: TextStyle(
                        color: contract.status.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Информация о договоре
              _buildContractInfo(contract),

              const SizedBox(height: 16),

              // Действия
              _buildContractActions(contract),
            ],
          ),
        ),
      );

  Widget _buildContractInfo(Contract contract) => Column(
        children: [
          _buildInfoRow('Дата создания', _formatDate(contract.createdAt)),
          if (contract.signedAt != null)
            _buildInfoRow('Дата подписания', _formatDate(contract.signedAt!)),
          _buildInfoRow('Срок действия', _formatDate(contract.expiresAt)),
          if (contract.totalAmount != null)
            _buildInfoRow(
                'Сумма', '${contract.totalAmount!.toStringAsFixed(0)} ₽',),
        ],
      );

  Widget _buildContractActions(Contract contract) => Row(
        children: [
          // Просмотр договора
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _viewContract(contract),
              icon: const Icon(Icons.visibility),
              label: const Text('Просмотр'),
            ),
          ),
          const SizedBox(width: 8),

          // Скачивание PDF
          if (contract.status == ContractStatus.signed)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isDownloadingPdf
                    ? null
                    : () => _downloadContractPdf(contract),
                icon: _isDownloadingPdf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(_isDownloadingPdf ? 'Скачивание...' : 'PDF'),
              ),
            ),

          // Подписание договора
          if (_canSignContract(contract))
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _signContract(contract),
                icon: const Icon(Icons.edit),
                label: const Text('Подписать'),
              ),
            ),
        ],
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  bool _canGenerateContract() =>
      widget.booking.status == BookingStatus.confirmed;

  bool _canSignContract(Contract contract) {
    // Здесь должна быть логика проверки прав пользователя на подписание
    // Пока возвращаем true для подписанных договоров
    return contract.status == ContractStatus.pending;
  }

  Future<void> _generateContract() async {
    try {
      setState(() {
        _isGeneratingContract = true;
      });

      await _contractService.generateContract(widget.booking.id);
      widget.onRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Договор успешно создан'),
              backgroundColor: Colors.green,),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка создания договора: $e'),
              backgroundColor: Colors.red,),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingContract = false;
        });
      }
    }
  }

  Future<void> _viewContract(Contract contract) async {
    // Навигация к экрану просмотра договора
    Navigator.pushNamed(context, '/contract-details', arguments: contract);
  }

  Future<void> _downloadContractPdf(Contract contract) async {
    try {
      setState(() {
        _isDownloadingPdf = true;
      });

      // Генерируем PDF
      final pdfBytes = await _pdfService.generateContractPdf(contract);

      // Сохраняем в Firebase Storage
      final downloadUrl =
          await _storageService.uploadContractPdf(contract.id, pdfBytes);

      // Скачиваем файл
      await _storageService.downloadFile(
          downloadUrl, 'contract_${contract.contractNumber}.pdf',);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Договор успешно скачан'),
              backgroundColor: Colors.green,),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка скачивания договора: $e'),
              backgroundColor: Colors.red,),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
      }
    }
  }

  Future<void> _signContract(Contract contract) async {
    // Навигация к экрану подписания договора
    Navigator.pushNamed(context, '/contract-sign', arguments: contract);
  }
}
