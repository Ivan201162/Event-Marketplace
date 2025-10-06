import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/payment_integration_service.dart';
import '../widgets/contract_card.dart';
import '../widgets/contract_details_dialog.dart';

class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({
    super.key,
    required this.userId,
    this.isSpecialist = false,
  });
  final String userId;
  final bool isSpecialist;

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen> {
  final PaymentIntegrationService _paymentIntegrationService =
      PaymentIntegrationService();
  ContractStatus? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSpecialist ? 'Мои контракты' : 'Контракты'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          _buildStatisticsCard(),

          // Contracts List
          Expanded(
            child: _buildContractsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final theme = Theme.of(context);

    return FutureBuilder<ContractStatistics>(
      future: _getContractStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            margin: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 120,
            margin: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Ошибка загрузки статистики',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          );
        }

        final stats = snapshot.data!;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Статистика контрактов',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      theme,
                      'Всего',
                      '${stats.totalContracts}',
                      Icons.description,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      theme,
                      'Активных',
                      '${stats.activeContracts}',
                      Icons.check_circle,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      theme,
                      'Завершенных',
                      '${stats.completedContracts}',
                      Icons.done_all,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) =>
      Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      );

  Widget _buildContractsList() => StreamBuilder<List<Contract>>(
        stream: _getContractsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки контрактов',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final contracts = snapshot.data ?? [];
          final filteredContracts = _filterContracts(contracts);

          if (filteredContracts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет контрактов',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Здесь будут отображаться ваши контракты',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredContracts.length,
            itemBuilder: (context, index) {
              final contract = filteredContracts[index];
              return ContractCard(
                contract: contract,
                onTap: () => _showContractDetails(contract),
                onStatusUpdate: (status) =>
                    _updateContractStatus(contract.id, status),
              );
            },
          );
        },
      );

  Stream<List<Contract>> _getContractsStream() {
    // This would typically stream from Firestore
    // For now, return an empty stream
    return Stream.value([]);
  }

  Future<ContractStatistics> _getContractStatistics() async {
    // This would typically fetch from Firestore
    // For now, return mock data
    return ContractStatistics(
      totalContracts: 0,
      activeContracts: 0,
      completedContracts: 0,
      cancelledContracts: 0,
    );
  }

  List<Contract> _filterContracts(List<Contract> contracts) =>
      contracts.where((contract) {
        if (_selectedStatus != null && contract.status != _selectedStatus) {
          return false;
        }
        if (_startDate != null && contract.createdAt.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && contract.createdAt.isAfter(_endDate!)) {
          return false;
        }
        return true;
      }).toList();

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ContractFiltersSheet(
        selectedStatus: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        onApplyFilters: (status, startDate, endDate) {
          setState(() {
            _selectedStatus = status;
            _startDate = startDate;
            _endDate = endDate;
          });
          Navigator.pop(context);
        },
        onClearFilters: () {
          setState(() {
            _selectedStatus = null;
            _startDate = null;
            _endDate = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showContractDetails(Contract contract) {
    showDialog<void>(
      context: context,
      builder: (context) => ContractDetailsDialog(
        contract: contract,
        onStatusUpdate: (status) => _updateContractStatus(contract.id, status),
      ),
    );
  }

  Future<void> _updateContractStatus(
    String contractId,
    ContractStatus status,
  ) async {
    try {
      await _paymentIntegrationService.updateContractStatus(contractId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Статус контракта обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления статуса: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class ContractFiltersSheet extends StatefulWidget {
  const ContractFiltersSheet({
    super.key,
    required this.selectedStatus,
    required this.startDate,
    required this.endDate,
    required this.onApplyFilters,
    required this.onClearFilters,
  });
  final ContractStatus? selectedStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(ContractStatus?, DateTime?, DateTime?) onApplyFilters;
  final VoidCallback onClearFilters;

  @override
  State<ContractFiltersSheet> createState() => _ContractFiltersSheetState();
}

class _ContractFiltersSheetState extends State<ContractFiltersSheet> {
  ContractStatus? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Фильтры контрактов',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Status filter
          Text(
            'Статус',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                'Все',
                _selectedStatus == null,
                () => setState(() => _selectedStatus = null),
              ),
              ...ContractStatus.values.map(
                (status) => _buildFilterChip(
                  _getStatusDisplayName(status),
                  _selectedStatus == status,
                  () => setState(() => _selectedStatus = status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date range
          Text(
            'Период',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(true),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _startDate != null
                        ? DateFormat('dd.MM.yyyy').format(_startDate!)
                        : 'С даты',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(false),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _endDate != null
                        ? DateFormat('dd.MM.yyyy').format(_endDate!)
                        : 'По дату',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClearFilters,
                  child: const Text('Сбросить'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onApplyFilters(
                    _selectedStatus,
                    _startDate,
                    _endDate,
                  ),
                  child: const Text('Применить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startDate ?? DateTime.now()
          : _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  String _getStatusDisplayName(ContractStatus status) {
    switch (status) {
      case ContractStatus.draft:
        return 'Черновик';
      case ContractStatus.active:
        return 'Активный';
      case ContractStatus.completed:
        return 'Завершен';
      case ContractStatus.cancelled:
        return 'Отменен';
    }
  }
}

class ContractStatistics {
  ContractStatistics({
    required this.totalContracts,
    required this.activeContracts,
    required this.completedContracts,
    required this.cancelledContracts,
  });
  final int totalContracts;
  final int activeContracts;
  final int completedContracts;
  final int cancelledContracts;
}
