import 'package:flutter/material.dart';
import '../../../services/reviews_service.dart';

class ReviewFiltersBottomSheet extends StatefulWidget {

  const ReviewFiltersBottomSheet({
    super.key,
    this.currentFilter,
    required this.onFilterChanged,
  });
  final ReviewFilter? currentFilter;
  final Function(ReviewFilter) onFilterChanged;

  @override
  State<ReviewFiltersBottomSheet> createState() => _ReviewFiltersBottomSheetState();
}

class _ReviewFiltersBottomSheetState extends State<ReviewFiltersBottomSheet> {
  double? _minRating;
  bool _hasPhotos = false;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    if (widget.currentFilter != null) {
      _minRating = widget.currentFilter!.minRating;
      _hasPhotos = widget.currentFilter!.hasPhotos;
      _fromDate = widget.currentFilter!.fromDate;
      _toDate = widget.currentFilter!.toDate;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Expanded(
                child: Text(
                  'Фильтры отзывов',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Фильтр по рейтингу
          _buildRatingFilter(),
          const SizedBox(height: 16),
          
          // Фильтр по фото
          _buildPhotosFilter(),
          const SizedBox(height: 16),
          
          // Фильтр по дате
          _buildDateFilter(),
          const SizedBox(height: 24),
          
          // Кнопки действий
          _buildActionButtons(),
        ],
      ),
    );

  Widget _buildRatingFilter() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Минимальный рейтинг',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildRatingChip('Все', null),
            _buildRatingChip('5★', 5),
            _buildRatingChip('4★+', 4),
            _buildRatingChip('3★+', 3),
            _buildRatingChip('2★+', 2),
            _buildRatingChip('1★+', 1),
          ],
        ),
      ],
    );

  Widget _buildRatingChip(String label, double? rating) {
    final isSelected = _minRating == rating;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _minRating = selected ? rating : null;
        });
      },
    );
  }

  Widget _buildPhotosFilter() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тип отзывов',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Только с фото'),
          subtitle: const Text('Показать отзывы с прикрепленными фотографиями'),
          value: _hasPhotos,
          onChanged: (value) {
            setState(() {
              _hasPhotos = value ?? false;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );

  Widget _buildDateFilter() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Период',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectFromDate,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _fromDate != null
                      ? '${_fromDate!.day}.${_fromDate!.month}.${_fromDate!.year}'
                      : 'С даты',
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('—'),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectToDate,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _toDate != null
                      ? '${_toDate!.day}.${_toDate!.month}.${_toDate!.year}'
                      : 'По дату',
                ),
              ),
            ),
          ],
        ),
        if (_fromDate != null || _toDate != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _fromDate = null;
                _toDate = null;
              });
            },
            child: const Text('Очистить даты'),
          ),
        ],
      ],
    );

  Widget _buildActionButtons() => Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearFilters,
            child: const Text('Очистить'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _applyFilters,
            child: const Text('Применить'),
          ),
        ),
      ],
    );

  Future<void> _selectFromDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _fromDate = date;
        // Если выбранная дата больше конечной, сбрасываем конечную
        if (_toDate != null && _fromDate!.isAfter(_toDate!)) {
          _toDate = null;
        }
      });
    }
  }

  Future<void> _selectToDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _toDate = date;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _minRating = null;
      _hasPhotos = false;
      _fromDate = null;
      _toDate = null;
    });
  }

  void _applyFilters() {
    final filter = ReviewFilter(
      minRating: _minRating,
      hasPhotos: _hasPhotos,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    
    widget.onFilterChanged(filter);
    Navigator.pop(context);
  }
}
