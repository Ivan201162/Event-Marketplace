class SpecialistSchedule {
  final String specialistId;
  final List<DateTime> busyDates;

  SpecialistSchedule({
    required this.specialistId,
    required this.busyDates,
  });

  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'busyDates': busyDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  factory SpecialistSchedule.fromMap(Map<String, dynamic> map) {
    return SpecialistSchedule(
      specialistId: map['specialistId'],
      busyDates: (map['busyDates'] as List<dynamic>)
          .map((d) => DateTime.parse(d))
          .toList(),
    );
  }

  // Проверяет, занята ли дата
  bool isDateBusy(DateTime date) {
    return busyDates.any((busyDate) => 
      busyDate.year == date.year &&
      busyDate.month == date.month &&
      busyDate.day == date.day
    );
  }

  // Добавляет занятую дату
  SpecialistSchedule addBusyDate(DateTime date) {
    final newBusyDates = List<DateTime>.from(busyDates);
    if (!isDateBusy(date)) {
      newBusyDates.add(date);
    }
    return SpecialistSchedule(
      specialistId: specialistId,
      busyDates: newBusyDates,
    );
  }

  // Удаляет занятую дату
  SpecialistSchedule removeBusyDate(DateTime date) {
    final newBusyDates = busyDates.where((busyDate) => 
      !(busyDate.year == date.year &&
        busyDate.month == date.month &&
        busyDate.day == date.day)
    ).toList();
    return SpecialistSchedule(
      specialistId: specialistId,
      busyDates: newBusyDates,
    );
  }

  // Получает доступные даты в диапазоне
  List<DateTime> getAvailableDates(DateTime startDate, DateTime endDate) {
    final availableDates = <DateTime>[];
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      if (!isDateBusy(currentDate)) {
        availableDates.add(DateTime(currentDate.year, currentDate.month, currentDate.day));
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return availableDates;
  }

  // Копирует объект с новыми данными
  SpecialistSchedule copyWith({
    String? specialistId,
    List<DateTime>? busyDates,
  }) {
    return SpecialistSchedule(
      specialistId: specialistId ?? this.specialistId,
      busyDates: busyDates ?? this.busyDates,
    );
  }
}
