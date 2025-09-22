import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contract.dart' as contract_model;
import '../services/contract_service.dart';

/// Экран для просмотра договоров и актов
class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ContractService _contractService = ContractService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Договоры и акты'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Договоры', icon: Icon(Icons.description)),
            Tab(text: 'Акты', icon: Icon(Icons.assignment_turned_in)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContractsTab(),
          _buildWorkActsTab(),
        ],
      ),
    );
  }

  Widget _buildContractsTab() {
    return FutureBuilder<List<contract_model.Contract>>(
      future: _contractService.getUserContracts('current_user_id'), // TODO: Получить реальный ID
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
                Text('Ошибка загрузки договоров: ${snapshot.error}'),
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
                Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('У вас пока нет договоров'),
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

  Widget _buildWorkActsTab() {
    return FutureBuilder<List<contract_model.WorkAct>>(
      future: _contractService.getUserWorkActs('current_user_id'), // TODO: Получить реальный ID
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
                Text('Ошибка загрузки актов: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final workActs = snapshot.data ?? [];

        if (workActs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('У вас пока нет актов выполненных работ'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workActs.length,
          itemBuilder: (context, index) {
            final workAct = workActs[index];
            return _buildWorkActCard(workAct);
          },
        );
      },
    );
  }

  Widget _buildContractCard(contract_model.Contract contract) {
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
                  child: Text(
                    'Договор №${contract.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(contract.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Исполнитель: ${contract.specialistName}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Дата мероприятия: ${_formatDate(contract.eventDate)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Сумма: ${contract.totalAmount} ${contract.currency}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewContract(contract),
                    child: const Text('Просмотреть'),
                  ),
                ),
                const SizedBox(width: 8),
                if (contract.status == ContractStatus.pending)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _signContract(contract),
                      child: const Text('Подписать'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkActCard(contract_model.WorkAct workAct) {
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
                  child: Text(
                    'Акт №${workAct.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildWorkActStatusChip(workAct.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Исполнитель: ${workAct.specialistName}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Дата мероприятия: ${_formatDate(workAct.eventDate)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Сумма: ${workAct.totalAmount} ${workAct.currency}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewWorkAct(workAct),
                    child: const Text('Просмотреть'),
                  ),
                ),
                const SizedBox(width: 8),
                if (workAct.status == WorkActStatus.pending)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _signWorkAct(workAct),
                      child: const Text('Подписать'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(contract_model.ContractStatus status) {
    Color color;
    String text;

    switch (status) {
      case contract_model.ContractStatus.draft:
        color = Colors.grey;
        text = 'Черновик';
        break;
      case contract_model.ContractStatus.pending:
        color = Colors.orange;
        text = 'Ожидает подписания';
        break;
      case contract_model.ContractStatus.signed:
        color = Colors.green;
        text = 'Подписан';
        break;
      case contract_model.ContractStatus.active:
        color = Colors.blue;
        text = 'Активен';
        break;
      case contract_model.ContractStatus.completed:
        color = Colors.purple;
        text = 'Завершен';
        break;
      case contract_model.ContractStatus.canceled:
        color = Colors.red;
        text = 'Отменен';
        break;
    }

    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }

  Widget _buildWorkActStatusChip(contract_model.WorkActStatus status) {
    Color color;
    String text;

    switch (status) {
      case contract_model.WorkActStatus.draft:
        color = Colors.grey;
        text = 'Черновик';
        break;
      case contract_model.WorkActStatus.pending:
        color = Colors.orange;
        text = 'Ожидает подписания';
        break;
      case contract_model.WorkActStatus.signed:
        color = Colors.green;
        text = 'Подписан';
        break;
      case contract_model.WorkActStatus.completed:
        color = Colors.purple;
        text = 'Завершен';
        break;
    }

    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }

  void _viewContract(contract_model.Contract contract) {
    // TODO: Реализовать просмотр договора
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Просмотр договора ${contract.id}')),
    );
  }

  void _signContract(contract_model.Contract contract) {
    // TODO: Реализовать подписание договора
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Подписание договора ${contract.id}')),
    );
  }

  void _viewWorkAct(contract_model.WorkAct workAct) {
    // TODO: Реализовать просмотр акта
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Просмотр акта ${workAct.id}')),
    );
  }

  void _signWorkAct(contract_model.WorkAct workAct) {
    // TODO: Реализовать подписание акта
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Подписание акта ${workAct.id}')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}