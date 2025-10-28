import 'package:event_marketplace_app/services/specialist_price_management_service.dart';
import 'package:flutter/material.dart';

/// Виджет для управления ценами специалиста
class SpecialistPriceManagementWidget extends StatefulWidget {
  const SpecialistPriceManagementWidget({
    required this.specialistId, super.key,
    this.onPriceAdded,
    this.onPriceUpdated,
    this.onPriceDeleted,
  });

  final String specialistId;
  final void Function(ServicePrice)? onPriceAdded;
  final void Function(ServicePrice)? onPriceUpdated;
  final void Function(String)? onPriceDeleted;

  @override
  State<SpecialistPriceManagementWidget> createState() =>
      _SpecialistPriceManagementWidgetState();
}

class _SpecialistPriceManagementWidgetState
    extends State<SpecialistPriceManagementWidget> {
  final SpecialistPriceManagementService _service =
      SpecialistPriceManagementService();
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  List<ServicePrice> _prices = [];
  bool _isLoading = false;
  String? _error;
  bool _showAddForm = false;
  ServicePrice? _editingPrice;

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadPrices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prices = await _service.getSpecialistPrices(widget.specialistId);
      setState(() {
        _prices = prices;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addPrice() async {
    if (_serviceNameController.text.isEmpty || _priceController.text.isEmpty) {
      _showErrorSnackBar('Заполните все обязательные поля');
      return;
    }

    try {
      final price = double.tryParse(_priceController.text);
      if (price == null || price <= 0) {
        _showErrorSnackBar('Введите корректную цену');
        return;
      }

      final priceId = await _service.addServicePrice(
        specialistId: widget.specialistId,
        serviceName: _serviceNameController.text,
        price: price,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        duration: _durationController.text.isNotEmpty
            ? _durationController.text
            : null,
      );

      final newPrice = ServicePrice(
        id: priceId,
        specialistId: widget.specialistId,
        serviceName: _serviceNameController.text,
        price: price,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        duration: _durationController.text.isNotEmpty
            ? _durationController.text
            : null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() {
        _prices.insert(0, newPrice);
        _showAddForm = false;
      });

      _clearForm();
      widget.onPriceAdded?.call(newPrice);
      _showSuccessSnackBar('Цена добавлена');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка добавления цены: $e');
    }
  }

  Future<void> _updatePrice() async {
    if (_editingPrice == null) {
      return;
    }
    if (_serviceNameController.text.isEmpty || _priceController.text.isEmpty) {
      _showErrorSnackBar('Заполните все обязательные поля');
      return;
    }

    try {
      final price = double.tryParse(_priceController.text);
      if (price == null || price <= 0) {
        _showErrorSnackBar('Введите корректную цену');
        return;
      }

      await _service.updateServicePrice(
        priceId: _editingPrice!.id,
        serviceName: _serviceNameController.text,
        price: price,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        duration: _durationController.text.isNotEmpty
            ? _durationController.text
            : null,
      );

      final updatedPrice = ServicePrice(
        id: _editingPrice!.id,
        specialistId: _editingPrice!.specialistId,
        serviceName: _serviceNameController.text,
        price: price,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        duration: _durationController.text.isNotEmpty
            ? _durationController.text
            : null,
        includedServices: _editingPrice!.includedServices,
        isActive: _editingPrice!.isActive,
        createdAt: _editingPrice!.createdAt,
        updatedAt: DateTime.now(),
      );

      setState(() {
        final index = _prices.indexWhere((p) => p.id == _editingPrice!.id);
        if (index != -1) {
          _prices[index] = updatedPrice;
        }
        _editingPrice = null;
        _showAddForm = false;
      });

      _clearForm();
      widget.onPriceUpdated?.call(updatedPrice);
      _showSuccessSnackBar('Цена обновлена');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка обновления цены: $e');
    }
  }

  Future<void> _deletePrice(ServicePrice price) async {
    final confirmed = await _showDeleteConfirmation(price.serviceName);
    if (!confirmed) {
      return;
    }

    try {
      await _service.deleteServicePrice(price.id);
      setState(() {
        _prices.removeWhere((p) => p.id == price.id);
      });
      widget.onPriceDeleted?.call(price.id);
      _showSuccessSnackBar('Цена удалена');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка удаления цены: $e');
    }
  }

  Future<void> _togglePriceStatus(ServicePrice price) async {
    try {
      await _service.toggleServicePriceStatus(price.id, !price.isActive);
      setState(() {
        final index = _prices.indexWhere((p) => p.id == price.id);
        if (index != -1) {
          _prices[index] = ServicePrice(
            id: price.id,
            specialistId: price.specialistId,
            serviceName: price.serviceName,
            price: price.price,
            description: price.description,
            duration: price.duration,
            includedServices: price.includedServices,
            isActive: !price.isActive,
            createdAt: price.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      });
      _showSuccessSnackBar('Статус цены изменен');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка изменения статуса: $e');
    }
  }

  void _startEditing(ServicePrice price) {
    setState(() {
      _editingPrice = price;
      _showAddForm = true;
    });

    _serviceNameController.text = price.serviceName;
    _priceController.text = price.price.toString();
    _descriptionController.text = price.description ?? '';
    _durationController.text = price.duration ?? '';
  }

  void _clearForm() {
    _serviceNameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _durationController.clear();
    _editingPrice = null;
  }

  void _showAddPriceForm() {
    setState(() {
      _showAddForm = true;
      _editingPrice = null;
    });
    _clearForm();
  }

  void _hideAddForm() {
    setState(() {
      _showAddForm = false;
      _editingPrice = null;
    });
    _clearForm();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_isLoading) const _LoadingWidget(),
          if (_error != null)
            _ErrorWidget(error: _error!, onRetry: _loadPrices),
          if (!_isLoading && _error == null) ...[
            if (_showAddForm) _buildAddForm(),
            _buildPricesList(),
          ],
        ],
      );

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.price_check, color: Colors.green),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Управление ценами',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (!_showAddForm)
              ElevatedButton.icon(
                onPressed: _showAddPriceForm,
                icon: const Icon(Icons.add),
                label: const Text('Добавить цену'),
              ),
          ],
        ),
      );

  Widget _buildAddForm() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingPrice == null
                      ? 'Добавить цену'
                      : 'Редактировать цену',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold,),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _serviceNameController,
                  decoration: const InputDecoration(
                    labelText: 'Название услуги *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Цена (₽) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание услуги',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Продолжительность',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed:
                          _editingPrice == null ? _addPrice : _updatePrice,
                      child:
                          Text(_editingPrice == null ? 'Добавить' : 'Обновить'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                        onPressed: _hideAddForm, child: const Text('Отмена'),),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildPricesList() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: _prices
              .map(
                (price) => _PriceCard(
                  price: price,
                  onEdit: () => _startEditing(price),
                  onDelete: () => _deletePrice(price),
                  onToggleStatus: () => _togglePriceStatus(price),
                ),
              )
              .toList(),
        ),
      );

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),);
  }

  Future<bool> _showDeleteConfirmation(String serviceName) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удалить цену'),
          content: Text(
              'Вы уверены, что хотите удалить цену для услуги "$serviceName"?',),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Удалить'),
            ),
          ],
        ),
      ) ??
      false;
}

/// Виджет загрузки
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),),
            SizedBox(width: 12),
            Text('Загружаем цены...'),
          ],
        ),
      );
}

/// Виджет ошибки
class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ошибка загрузки цен',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      );
}

/// Карточка цены
class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.price,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  final ServicePrice price;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Card(
          elevation: 2,
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
                            price.serviceName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold,),
                          ),
                          if (price.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              price.description!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey,),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4,),
                      decoration: BoxDecoration(
                        color: price.isActive ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        price.isActive ? 'Активна' : 'Неактивна',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${price.price.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (price.duration != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${price.duration}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Редактировать',
                    ),
                    IconButton(
                      onPressed: onToggleStatus,
                      icon: Icon(
                          price.isActive ? Icons.pause : Icons.play_arrow,
                          size: 20,),
                      tooltip:
                          price.isActive ? 'Деактивировать' : 'Активировать',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon:
                          const Icon(Icons.delete, size: 20, color: Colors.red),
                      tooltip: 'Удалить',
                    ),
                    const Spacer(),
                    Text(
                      'Обновлено: ${_formatDate(price.updatedAt)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

/// Форматирование даты
String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
