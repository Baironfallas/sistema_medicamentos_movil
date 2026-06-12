import '../models/medication.dart';
import '../models/medication_intake.dart';

List<MedicationIntake> enrichIntakesWithMedicationDetails(
  List<MedicationIntake> intakes,
  List<Medication> medications,
) {
  final medicationById = <int, Medication>{
    for (final medication in medications) medication.id: medication,
  };
  final medicationByName = <String, Medication>{
    for (final medication in medications)
      _normalizeMedicationKey(medication.name): medication,
  };

  return intakes.map((intake) {
    final medication = intake.medicationId != null
        ? medicationById[intake.medicationId]
        : null;
    final fallbackMedication =
        medication ??
        medicationByName[_normalizeMedicationKey(intake.medicationName)];
    if (fallbackMedication == null) {
      return intake;
    }

    final scheduleCorrection = _resolveScheduleCorrection(
      intake,
      fallbackMedication.scheduleHours,
    );

    return intake.copyWith(
      dosage: intake.dosage ?? fallbackMedication.dose,
      quantityPerIntake:
          intake.quantityPerIntake ??
          fallbackMedication.quantityPerIntake.toInt(),
      timeLabel: scheduleCorrection?.timeLabel ?? intake.timeLabel,
      dateLabel: scheduleCorrection?.dateLabel ?? intake.dateLabel,
    );
  }).toList();
}

String _normalizeMedicationKey(String value) {
  return value.trim().toLowerCase();
}

_ScheduleCorrection? _resolveScheduleCorrection(
  MedicationIntake intake,
  List<String> scheduleHours,
) {
  if (scheduleHours.isEmpty) {
    return null;
  }

  final scheduledDateTime = _parseLocalDateTime(intake.scheduledAt);
  if (scheduledDateTime == null) {
    final onlySchedule = scheduleHours.length == 1
        ? _timeParts(scheduleHours.first)
        : null;
    if (onlySchedule == null) {
      return null;
    }

    return _ScheduleCorrection(
      timeLabel: onlySchedule.label,
      dateLabel: intake.dateLabel,
    );
  }

  final exactMatch = _firstMatchingTime(
    scheduleHours,
    (parts) =>
        parts.hour == scheduledDateTime.hour &&
        parts.minute == scheduledDateTime.minute,
  );
  if (exactMatch != null) {
    return null;
  }

  final shiftedMatch = _firstMatchingTime(
    scheduleHours,
    (parts) {
        final shifted = DateTime(
          scheduledDateTime.year,
          scheduledDateTime.month,
          scheduledDateTime.day,
          parts.hour,
          parts.minute,
        ).add(const Duration(hours: 6));

        return shifted.hour == scheduledDateTime.hour &&
            shifted.minute == scheduledDateTime.minute;
      },
  );

  final correctedSchedule = shiftedMatch ??
      (scheduleHours.length == 1 ? _timeParts(scheduleHours.first) : null);
  if (correctedSchedule == null) {
    return null;
  }

  final wrapsToNextDay =
      shiftedMatch != null && correctedSchedule.hour + 6 >= 24;
  final correctedDate = wrapsToNextDay
      ? scheduledDateTime.subtract(const Duration(days: 1))
      : scheduledDateTime;
  final correctedDateTime = DateTime(
    correctedDate.year,
    correctedDate.month,
    correctedDate.day,
    correctedSchedule.hour,
    correctedSchedule.minute,
  );

  return _ScheduleCorrection(
    timeLabel: correctedSchedule.label,
    dateLabel: _formatDate(correctedDateTime),
  );
}

_TimeParts? _firstMatchingTime(
  List<String> scheduleHours,
  bool Function(_TimeParts parts) test,
) {
  for (final scheduleHour in scheduleHours) {
    final parts = _timeParts(scheduleHour);
    if (parts != null && test(parts)) {
      return parts;
    }
  }

  return null;
}

DateTime? _parseLocalDateTime(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(text);
}

_TimeParts? _timeParts(String value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(
    value.trim(),
  );
  if (match == null) {
    return null;
  }

  final hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null || hour > 23 || minute > 59) {
    return null;
  }

  return _TimeParts(hour, minute);
}

String _formatDate(DateTime dateTime) {
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

class _TimeParts {
  const _TimeParts(this.hour, this.minute);

  final int hour;
  final int minute;

  String get label {
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}

class _ScheduleCorrection {
  const _ScheduleCorrection({required this.timeLabel, required this.dateLabel});

  final String timeLabel;
  final String? dateLabel;
}
