import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../services/work_act_service.dart';

/// Виджет для подписания актов выполненных работ
class WorkActSignatureWidget extends StatefulWidget {
  const WorkActSignatureWidget({
    super.key,
    required this.workAct,
    required this.userId,
    this.onActSigned,
    this.onActRejected,
  });

  final WorkAct workAct;
  final String userId;
  final VoidCallback? onActSigned;
  final VoidCallback? onActRejected;

  @override
  State<WorkActSignatureWidget> createState() => _WorkActSignatureWidgetState();
}

class _WorkActSignatureWidgetState extends State<WorkActSignatureWidget> {
  final WorkActService _workActService = WorkActService();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    exportBackgroundColor: Colors.white,
  );

  bool _isLoading = false;
  String? _error;
  String? _rejectionReason;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (_error != null) _buildError(),
              if (_error != null) const SizedBox(height: 16),
              _buildWorkActInfo(),
              const SizedBox(height: 16),
              _buildSignatureSection(),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      );

  Widget _buildHeader() => Row(
        children: [
          const Icon(Icons.edit, color: Colors.blue),
          const SizedBox(width: 8),
          const Text(
            'Подписание акта выполненных работ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildStatusChip(widget.workAct.status),
        ],
      );

  Widget _buildStatusChip(WorkActStatus status) {
    Color color;
    String text;

    switch (status) {
      case WorkActStatus.draft:
        color = Colors.orange;
        text = 'Черновик';
        break;
      case WorkActStatus.signed:
        color = Colors.green;
        text = 'Подписан';
        break;
      case WorkActStatus.rejected:
        color = Colors.red;
        text = 'Отклонен';
        break;
    }

    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildError() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _error = null),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      );

  Widget _buildWorkActInfo() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Информация об акте:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Мероприятие:', widget.workAct.eventName),
            _buildInfoRow('Дата:', widget.workAct.eventDate),
            _buildInfoRow('Место:', widget.workAct.eventLocation),
            _buildInfoRow(
              'Сумма:',
              '${widget.workAct.totalAmount.toStringAsFixed(2)} ₽',
            ),
            _buildInfoRow('Создан:', _formatDate(widget.workAct.createdAt)),
            if (widget.workAct.notes != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Примечания:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(widget.workAct.notes!),
            ],
          ],
        ),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(value),
            ),
          ],
        ),
      );

  Widget _buildSignatureSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Подпись:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Signature(
              controller: _signatureController,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _clearSignature,
                icon: const Icon(Icons.clear),
                label: const Text('Очистить'),
              ),
              const Spacer(),
              Text(
                'Подпишите в поле выше',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildActions() => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _rejectAct,
              icon: const Icon(Icons.close, color: Colors.red),
              label:
                  const Text('Отклонить', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _signAct,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Подписать'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );

  // ========== МЕТОДЫ ==========

  void _clearSignature() {
    _signatureController.clear();
  }

  Future<void> _signAct() async {
    if (_signatureController.isEmpty) {
      setState(() => _error = 'Необходимо поставить подпись');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final signatureData = await _signatureController.toPngBytes();
      final signature = signatureData != null
          ? 'data:image/png;base64,${signatureData.toString()}'
          : '';

      await _workActService.signWorkAct(
        workActId: widget.workAct.id,
        signedBy: widget.userId,
        signature: signature,
      );

      if (widget.onActSigned != null) {
        widget.onActSigned!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Акт выполненных работ подписан'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Ошибка подписания акта: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectAct() async {
    final reason = await _showRejectionDialog();
    if (reason == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _workActService.rejectWorkAct(
        workActId: widget.workAct.id,
        reason: reason,
      );

      if (widget.onActRejected != null) {
        widget.onActRejected!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Акт выполненных работ отклонен'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Ошибка отклонения акта: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _showRejectionDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонение акта'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Укажите причину отклонения акта:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Причина отклонения',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
