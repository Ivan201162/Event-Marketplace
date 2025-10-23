import 'package:flutter/material.dart';
import '../services/work_act_service.dart';

/// Виджет для создания и управления актами выполненных работ
class WorkActWidget extends StatefulWidget {
  const WorkActWidget({
    super.key,
    required this.bookingId,
    required this.specialistId,
    required this.customerId,
    this.workAct,
    this.onActCreated,
    this.onActSigned,
  });

  final String bookingId;
  final String specialistId;
  final String customerId;
  final WorkAct? workAct;
  final VoidCallback? onActCreated;
  final VoidCallback? onActSigned;

  @override
  State<WorkActWidget> createState() => _WorkActWidgetState();
}

class _WorkActWidgetState extends State<WorkActWidget> {
  final WorkActService _workActService = WorkActService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _eventLocationController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<ServiceItem> _services = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDateController.dispose();
    _eventLocationController.dispose();
    _notesController.dispose();
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
              _buildForm(),
              const SizedBox(height: 16),
              _buildServicesSection(),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      );

  Widget _buildHeader() => Row(
        children: [
          const Icon(Icons.description, color: Colors.blue),
          const SizedBox(width: 8),
          const Text(
            'Акт выполненных работ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (widget.workAct != null) _buildStatusChip(widget.workAct!.status),
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
      label:
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
              child:
                  Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            ),
            IconButton(
                onPressed: () => setState(() => _error = null),
                icon: const Icon(Icons.close)),
          ],
        ),
      );

  Widget _buildForm() => Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _eventNameController,
              decoration: const InputDecoration(
                labelText: 'Название мероприятия',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название мероприятия';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _eventDateController,
              decoration: const InputDecoration(
                labelText: 'Дата мероприятия',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите дату мероприятия';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _eventLocationController,
              decoration: const InputDecoration(
                labelText: 'Место проведения',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите место проведения';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Примечания',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      );

  Widget _buildServicesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Выполненные работы',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addService,
                icon: const Icon(Icons.add),
                label: const Text('Добавить'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_services.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Text('Добавьте выполненные работы',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...(_services.asMap().entries.map((entry) {
              final index = entry.key;
              final service = entry.value;
              return _buildServiceItem(service, index);
            })),
          const SizedBox(height: 16),
          _buildTotalAmount(),
        ],
      );

  Widget _buildServiceItem(ServiceItem service, int index) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          title: Text(service.name),
          subtitle: Text(
            'Количество: ${service.quantity}, Цена: ${service.price.toStringAsFixed(2)} ₽',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${service.totalPrice.toStringAsFixed(2)} ₽',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              IconButton(
                  onPressed: () => _editService(index),
                  icon: const Icon(Icons.edit)),
              IconButton(
                onPressed: () => _removeService(index),
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ),
      );

  Widget _buildTotalAmount() {
    final totalAmount =
        _services.fold<double>(0, (sum, service) => sum + service.totalPrice);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Итого:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            '${totalAmount.toStringAsFixed(2)} ₽',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() => Row(
        children: [
          if (widget.workAct == null) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createWorkAct,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Создать акт'),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateWorkAct,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Обновить акт'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generatePDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
              ),
            ),
          ],
        ],
      );

  // ========== МЕТОДЫ ==========

  void _initializeForm() {
    if (widget.workAct != null) {
      final act = widget.workAct!;
      _eventNameController.text = act.eventName;
      _eventDateController.text = act.eventDate;
      _eventLocationController.text = act.eventLocation;
      _notesController.text = act.notes ?? '';
      _services = List.from(act.services);
    }
  }

  void _addService() {
    showDialog<void>(
      context: context,
      builder: (context) => _ServiceDialog(
        onSave: (service) {
          setState(() {
            _services.add(service);
          });
        },
      ),
    );
  }

  void _editService(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => _ServiceDialog(
        service: _services[index],
        onSave: (service) {
          setState(() {
            _services[index] = service;
          });
        },
      ),
    );
  }

  void _removeService(int index) {
    setState(() {
      _services.removeAt(index);
    });
  }

  Future<void> _createWorkAct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_services.isEmpty) {
      setState(() => _error = 'Добавьте хотя бы одну выполненную работу');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final totalAmount =
          _services.fold<double>(0, (sum, service) => sum + service.totalPrice);

      await _workActService.createWorkAct(
        bookingId: widget.bookingId,
        specialistId: widget.specialistId,
        customerId: widget.customerId,
        eventName: _eventNameController.text.trim(),
        eventDate: _eventDateController.text.trim(),
        eventLocation: _eventLocationController.text.trim(),
        services: _services,
        totalAmount: totalAmount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (widget.onActCreated != null) {
        widget.onActCreated!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Акт выполненных работ создан'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      setState(() => _error = 'Ошибка создания акта: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateWorkAct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_services.isEmpty) {
      setState(() => _error = 'Добавьте хотя бы одну выполненную работу');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final totalAmount =
          _services.fold<double>(0, (sum, service) => sum + service.totalPrice);

      await _workActService.updateWorkAct(
        workActId: widget.workAct!.id,
        eventName: _eventNameController.text.trim(),
        eventDate: _eventDateController.text.trim(),
        eventLocation: _eventLocationController.text.trim(),
        services: _services,
        totalAmount: totalAmount,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Акт выполненных работ обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      setState(() => _error = 'Ошибка обновления акта: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generatePDF() async {
    if (widget.workAct == null) return;

    setState(() => _isLoading = true);

    try {
      await _workActService.generateWorkActPDF(widget.workAct!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('PDF создан успешно'),
              backgroundColor: Colors.green),
        );
      }
    } on Exception catch (e) {
      setState(() => _error = 'Ошибка создания PDF: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

/// Диалог для добавления/редактирования услуги
class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({this.service, required this.onSave});

  final ServiceItem? service;
  final void Function(ServiceItem) onSave;

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      final service = widget.service!;
      _nameController.text = service.name;
      _quantityController.text = service.quantity.toString();
      _priceController.text = service.price.toString();
      _descriptionController.text = service.description ?? '';
    } else {
      _quantityController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.service == null
            ? 'Добавить работу'
            : 'Редактировать работу'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название работы',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название работы';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Количество',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите количество';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'Введите корректное количество';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Цена (₽)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите цену';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Введите корректную цену';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Описание', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена')),
          ElevatedButton(
              onPressed: _saveService, child: const Text('Сохранить')),
        ],
      );

  void _saveService() {
    if (!_formKey.currentState!.validate()) return;

    final service = ServiceItem(
      name: _nameController.text.trim(),
      quantity: int.parse(_quantityController.text),
      price: double.parse(_priceController.text),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    widget.onSave(service);
    Navigator.of(context).pop();
  }
}
