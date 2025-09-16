import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contract.dart';
import '../services/contract_service.dart';
import '../core/feature_flags.dart';

/// Экран управления договорами
class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ContractService _contractService = ContractService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.contractsEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Договоры'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Автоматическое формирование договоров временно недоступно',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Договоры'),
        backgroundColor: Colors.indigo[50],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Мои договоры', icon: Icon(Icons.folder)),
            Tab(text: 'Ожидают подписи', icon: Icon(Icons.edit)),
            Tab(text: 'Активные', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyContractsTab(),
          _buildPendingContractsTab(),
          _buildActiveContractsTab(),
        ],
      ),
    );
  }

  Widget _buildMyContractsTab() {
    return StreamBuilder<List<Contract>>(
      stream: _contractService
          .getUserContracts('current_user_id'), // TODO: Получить реальный ID
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка загрузки: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final contracts = snapshot.data ?? [];
        if (contracts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'У вас пока нет договоров',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Договоры будут создаваться автоматически при бронировании',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contract = contracts[index];
            return _buildContractCard(contract);
          },
        );
      },
    );
  }

  Widget _buildPendingContractsTab() {
    return StreamBuilder<List<Contract>>(
      stream: _contractService
          .getUserContracts('current_user_id'), // TODO: Получить реальный ID
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allContracts = snapshot.data ?? [];
        final pendingContracts = allContracts
            .where((contract) => contract.status == ContractStatus.pending)
            .toList();

        if (pendingContracts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Нет договоров, ожидающих подписи',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingContracts.length,
          itemBuilder: (context, index) {
            final contract = pendingContracts[index];
            return _buildContractCard(contract);
          },
        );
      },
    );
  }

  Widget _buildActiveContractsTab() {
    return StreamBuilder<List<Contract>>(
      stream: _contractService
          .getUserContracts('current_user_id'), // TODO: Получить реальный ID
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allContracts = snapshot.data ?? [];
        final activeContracts = allContracts
            .where((contract) =>
                contract.status == ContractStatus.signed ||
                contract.status == ContractStatus.active)
            .toList();

        if (activeContracts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Нет активных договоров',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeContracts.length,
          itemBuilder: (context, index) {
            final contract = activeContracts[index];
            return _buildContractCard(contract);
          },
        );
      },
    );
  }

  Widget _buildContractCard(Contract contract) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Специалист: ${contract.specialistName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: contract.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: contract.statusColor),
                  ),
                  child: Text(
                    contract.statusText,
                    style: TextStyle(
                      color: contract.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(contract.startDate)} - ${_formatDate(contract.endDate)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${contract.totalAmount} ${contract.currency}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            if (contract.signedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Подписан ${_formatDate(contract.signedAt!)}',
                    style: TextStyle(color: Colors.green[600], fontSize: 14),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewContract(contract),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Просмотр'),
                  ),
                ),
                const SizedBox(width: 12),
                if (contract.status == ContractStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _signContract(contract),
                      icon: const Icon(Icons.edit),
                      label: const Text('Подписать'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadContract(contract),
                      icon: const Icon(Icons.download),
                      label: const Text('Скачать'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _viewContract(Contract contract) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contract.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Статус: ${contract.statusText}',
                style: TextStyle(
                  color: contract.statusColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    contract.content,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signContract(Contract contract) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подписать договор'),
        content: const Text(
          'Вы уверены, что хотите подписать этот договор? '
          'После подписания договор вступит в силу.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Подписать'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _contractService.signContract(
          contract.id,
          'current_user_id', // TODO: Получить реальный ID
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Договор успешно подписан!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка подписания: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadContract(Contract contract) async {
    try {
      final pdfBytes = await _contractService.generateContractPDF(contract.id);

      // TODO: Реализовать сохранение файла
      // Можно использовать пакет file_picker или path_provider

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF договора готов к скачиванию'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка генерации PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
