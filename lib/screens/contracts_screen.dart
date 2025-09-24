import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contract_models.dart';
import '../services/contract_service.dart';
import '../widgets/contract_card.dart';
import '../widgets/contract_details_dialog.dart';

/// Экран управления контрактами
class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen> {
  final ContractService _contractService = ContractService();
  List<Contract> _contracts = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Здесь должен быть получен ID текущего пользователя
      // Для демонстрации используем тестовый ID
      final contracts = await _contractService.getContractsByCustomer('test_customer_id');
      
      setState(() {
        _contracts = contracts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка загрузки контрактов: $e');
    }
  }

  List<Contract> get _filteredContracts {
    switch (_selectedFilter) {
      case 'draft':
        return _contracts.where((c) => c.isDraft).toList();
      case 'pending':
        return _contracts.where((c) => c.isPending).toList();
      case 'signed':
        return _contracts.where((c) => c.isSigned).toList();
      case 'completed':
        return _contracts.where((c) => c.isCompleted).toList();
      case 'cancelled':
        return _contracts.where((c) => c.isCancelled).toList();
      default:
        return _contracts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои контракты'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: _loadContracts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтры
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', 'Все'),
                const SizedBox(width: 8),
                _buildFilterChip('draft', 'Черновики'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Ожидают'),
                const SizedBox(width: 8),
                _buildFilterChip('signed', 'Подписаны'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Завершены'),
                const SizedBox(width: 8),
                _buildFilterChip('cancelled', 'Отменены'),
              ],
            ),
          ),
          
          // Список контрактов
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContracts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadContracts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredContracts.length,
                          itemBuilder: (context, index) {
                            final contract = _filteredContracts[index];
                            return ContractCard(
                              contract: contract,
                              onTap: () => _showContractDetails(contract),
                              onSign: () => _signContract(contract),
                              onDownload: () => _downloadContract(contract),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected 
            ? theme.colorScheme.primary 
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Контракты не найдены',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'У вас пока нет контрактов',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showContractDetails(Contract contract) {
    showDialog(
      context: context,
      builder: (context) => ContractDetailsDialog(
        contract: contract,
        onSign: () => _signContract(contract),
        onDownload: () => _downloadContract(contract),
      ),
    );
  }

  Future<void> _signContract(Contract contract) async {
    try {
      // Здесь должна быть логика подписания контракта
      // Для демонстрации показываем диалог
      final signature = await _showSignatureDialog();
      if (signature != null) {
        await _contractService.signContractByCustomer(
          contractId: contract.id,
          signature: signature,
        );
        
        _showSuccessSnackBar('Контракт подписан');
        _loadContracts();
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка подписания контракта: $e');
    }
  }

  Future<String?> _showSignatureDialog() async {
    // Здесь должна быть логика получения подписи
    // Для демонстрации возвращаем тестовую подпись
    return 'test_signature_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _downloadContract(Contract contract) async {
    try {
      if (contract.contractUrl != null) {
        // Здесь должна быть логика скачивания файла
        _showSuccessSnackBar('Контракт скачан');
      } else {
        _showErrorSnackBar('Файл контракта не найден');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка скачивания контракта: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}