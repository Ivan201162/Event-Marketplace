import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contract.dart';
import '../models/work_act.dart';
import '../services/contract_service.dart';
import '../services/work_act_service.dart';
import '../services/signature_service.dart';

/// Экран управления договорами и актами
class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ContractService _contractService = ContractService();
  final WorkActService _workActService = WorkActService();

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
            Tab(icon: Icon(Icons.description), text: 'Договоры'),
            Tab(icon: Icon(Icons.assignment_turned_in), text: 'Акты'),
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
    return FutureBuilder<List<Contract>>(
      future: _contractService.getUserContracts('current_user_id'), // TODO: Получить реальный ID пользователя
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
                Text('Ошибка: ${snapshot.error}'),
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
                Text(
                  'У вас пока нет договоров',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
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

  Widget _buildWorkActsTab() {
    return FutureBuilder<List<WorkAct>>(
      future: _workActService.getUserWorkActs('current_user_id'), // TODO: Получить реальный ID пользователя
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
                Text('Ошибка: ${snapshot.error}'),
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
                Text(
                  'У вас пока нет актов выполненных работ',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
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
                        '№ ${contract.contractNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: contract.status.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: contract.status.statusColor),
                  ),
                  child: Text(
                    contract.status.statusText,
                    style: TextStyle(
                      color: contract.status.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (contract.totalAmount != null) ...[
              Text(
                'Сумма: ${contract.totalAmount!.toStringAsFixed(2)} ${contract.currency ?? 'RUB'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Создан: ${_formatDate(contract.createdAt)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (contract.expiresAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Действует до: ${_formatDate(contract.expiresAt!)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewContract(contract),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Просмотр'),
                  ),
                ),
                const SizedBox(width: 8),
                if (contract.status == ContractStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _signContract(contract),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Подписать'),
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

  Widget _buildWorkActCard(WorkAct workAct) {
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
                        workAct.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '№ ${workAct.actNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: workAct.status.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: workAct.status.statusColor),
                  ),
                  child: Text(
                    workAct.status.statusText,
                    style: TextStyle(
                      color: workAct.status.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Сумма: ${workAct.totalAmount.toStringAsFixed(2)} ${workAct.currency}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Период работ: ${_formatDate(workAct.workStartDate)} - ${_formatDate(workAct.workEndDate)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Создан: ${_formatDate(workAct.createdAt)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewWorkAct(workAct),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Просмотр'),
                  ),
                ),
                const SizedBox(width: 8),
                if (workAct.status == WorkActStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _signWorkAct(workAct),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Подписать'),
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
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _viewContract(Contract contract) {
    // TODO: Открыть экран просмотра договора
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Просмотр договора ${contract.contractNumber}')),
    );
  }

  void _signContract(Contract contract) {
    showDialog(
      context: context,
      builder: (context) => SignatureDialog(
        title: 'Подписание договора',
        documentId: contract.id,
        documentType: 'contract',
        onSigned: (signature) async {
          try {
            await _contractService.signContract(
              contractId: contract.id,
              userId: 'current_user_id', // TODO: Получить реальный ID пользователя
              signature: signature,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Договор успешно подписан')),
              );
              setState(() {});
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка подписания: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _viewWorkAct(WorkAct workAct) {
    // TODO: Открыть экран просмотра акта
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Просмотр акта ${workAct.actNumber}')),
    );
  }

  void _signWorkAct(WorkAct workAct) {
    showDialog(
      context: context,
      builder: (context) => SignatureDialog(
        title: 'Подписание акта выполненных работ',
        documentId: workAct.id,
        documentType: 'work_act',
        onSigned: (signature) async {
          try {
            await _workActService.signWorkAct(
              workActId: workAct.id,
              userId: 'current_user_id', // TODO: Получить реальный ID пользователя
              userName: 'Current User', // TODO: Получить реальное имя пользователя
              signature: signature,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Акт успешно подписан')),
              );
              setState(() {});
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка подписания: $e')),
              );
            }
          }
        },
      ),
    );
  }
}

/// Диалог для подписания документов
class SignatureDialog extends StatefulWidget {
  const SignatureDialog({
    super.key,
    required this.title,
    required this.documentId,
    required this.documentType,
    required this.onSigned,
  });

  final String title;
  final String documentId;
  final String documentType;
  final Function(String) onSigned;

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  final GlobalKey _signaturePadKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Поставьте подпись в поле ниже:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            SignaturePad(
              key: _signaturePadKey,
              width: double.infinity,
              height: 200,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _signaturePadKey.currentState?.clear();
                    },
                    child: const Text('Очистить'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_signaturePadKey.currentState?.hasSignature == true) {
                        try {
                          final signature = await SignatureService.captureSignature(
                            _signaturePadKey.currentState!.signatureKey,
                          );
                          widget.onSigned(signature);
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ошибка создания подписи: $e')),
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Пожалуйста, поставьте подпись')),
                        );
                      }
                    },
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
}