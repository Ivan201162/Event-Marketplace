import 'package:flutter/material.dart';

import '../services/calendar_service.dart';

/// Виджет для отображения доступных слотов времени
class AvailableTimeSlotsWidget extends StatelessWidget {
  const AvailableTimeSlotsWidget({
    super.key,
    required this.slots,
    required this.onSlotSelected,
  });

  final List<TimeSlot> slots;
  final Function(TimeSlot) onSlotSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Доступные слоты времени',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Список слотов
        Expanded(
          child: slots.isEmpty
              ? _buildEmptyState(context)
              : _buildSlotsList(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет доступных слотов',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Все время занято',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        return _buildSlotCard(context, slot);
      },
    );
  }

  Widget _buildSlotCard(BuildContext context, TimeSlot slot) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onSlotSelected(slot),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Иконка времени
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Информация о слоте
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTimeRange(slot.startTime, slot.endTime),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Длительность: ${_formatDuration(slot.duration)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Кнопка выбора
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Выбрать',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final startTime = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTime = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startTime - $endTime';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours} ч ${duration.inMinutes % 60} мин';
    } else {
      return '${duration.inMinutes} мин';
    }
  }
}

/// Виджет для отображения слотов времени в виде сетки
class TimeSlotsGridWidget extends StatelessWidget {
  const TimeSlotsGridWidget({
    super.key,
    required this.slots,
    required this.onSlotSelected,
    this.slotsPerRow = 3,
  });

  final List<TimeSlot> slots;
  final Function(TimeSlot) onSlotSelected;
  final int slotsPerRow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Выберите время',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Сетка слотов
        Expanded(
          child: slots.isEmpty
              ? _buildEmptyState(context)
              : _buildSlotsGrid(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет доступных слотов',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: slotsPerRow,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        return _buildSlotChip(context, slot);
      },
    );
  }

  Widget _buildSlotChip(BuildContext context, TimeSlot slot) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () => onSlotSelected(slot),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            _formatTime(slot.startTime),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Виджет для отображения временной шкалы
class TimeLineWidget extends StatelessWidget {
  const TimeLineWidget({
    super.key,
    required this.slots,
    required this.onSlotSelected,
    this.startHour = 9,
    this.endHour = 18,
  });

  final List<TimeSlot> slots;
  final Function(TimeSlot) onSlotSelected;
  final int startHour;
  final int endHour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Временная шкала',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Шкала времени
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildTimeLine(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeLine(BuildContext context) {
    final theme = Theme.of(context);
    final hours = List.generate(endHour - startHour, (index) => startHour + index);
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: hours.length,
      itemBuilder: (context, index) {
        final hour = hours[index];
        final hourSlots = slots.where((slot) => slot.startTime.hour == hour).toList();
        
        return Container(
          height: 60,
          margin: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              // Метка часа
              SizedBox(
                width: 40,
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Слоты времени
              Expanded(
                child: hourSlots.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text('Занято'),
                        ),
                      )
                    : Row(
                        children: hourSlots.map((slot) => 
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 2),
                              child: InkWell(
                                onTap: () => onSlotSelected(slot),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _formatTime(slot.startTime),
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
