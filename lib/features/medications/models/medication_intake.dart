class MedicationIntake {
  MedicationIntake({
    required this.id,
    this.medicationId,
    required this.medicationName,
    required this.status,
    required this.isConfirmed,
    this.timeLabel,
    this.dateLabel,
    this.scheduledAt,
    this.respondedAt,
    this.quantityTaken,
    this.remainingPills,
    this.quantityPerIntake,
    this.dosage,
  });

  final int id;
  final int? medicationId;
  final String medicationName;
  final String status;
  final bool isConfirmed;
  final String? timeLabel;
  final String? dateLabel;
  final String? scheduledAt;
  final String? respondedAt;
  final int? quantityTaken;
  final int? remainingPills;
  final int? quantityPerIntake;
  final String? dosage;

  DateTime? get scheduledDateTime =>
      _dateTimeFromLabels(dateLabel, timeLabel) ??
      _parseMedicationDateTime(scheduledAt);

  String? get respondedTimeLabel => _formatMedicationTime(respondedAt);
  String? get respondedDateLabel => _formatMedicationDate(respondedAt);

  factory MedicationIntake.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['intakeId'] ?? json['id']);
    final medicationMap = _asMap(
      json['medication'] ?? json['medicine'] ?? json['medicationInfo'],
    );

    final name =
        _string(json['medicationName']) ??
        _string(json['name']) ??
        _string(medicationMap['name']) ??
        'Toma #$id';

    final statusText =
        _string(json['status']) ??
        _string(json['state']) ??
        _string(json['intakeStatus']) ??
        '';

    final confirmedFromBool =
        _bool(json['confirmed']) ??
        _bool(json['isConfirmed']) ??
        _bool(json['taken']);

    final statusLower = statusText.toLowerCase();
    final isConfirmed =
        confirmedFromBool ??
        statusLower == 'taken' ||
            statusLower == 'confirmed' ||
            statusLower == 'done';

    final scheduledAt =
        _string(json['scheduledAt']) ??
        _string(json['scheduledTime']) ??
        _string(json['time']) ??
        _string(json['intakeTime']);

    final respondedAt = _string(json['respondedAt']);

    final hour =
        _string(json['hour']) ??
        _string(json['scheduledHour']) ??
        _string(json['hourLabel']) ??
        _timeOnlyLabel(json['time']) ??
        _timeOnlyLabel(json['scheduledTime']) ??
        _timeOnlyLabel(json['intakeTime']);

    final date =
        _string(json['date']) ??
        _string(json['scheduledDate']) ??
        _string(json['day']);

    final timeLabel = _timeOnlyLabel(hour) ?? _formatMedicationTime(scheduledAt);
    final dateLabel = date ?? _formatMedicationDate(scheduledAt);

    final dosage =
        _string(json['dosage']) ??
        _string(json['dose']) ??
        _string(medicationMap['dosage']) ??
        _string(medicationMap['dose']);

    final quantityPerIntake =
        _toIntNullable(json['quantityPerIntake']) ??
        _toIntNullable(medicationMap['quantityPerIntake']);

    return MedicationIntake(
      id: id,
      medicationId: _toIntNullable(
        json['medicationId'] ??
            medicationMap['medicationId'] ??
            medicationMap['id'],
      ),
      medicationName: name.isEmpty ? 'Medicamento' : name,
      status: statusText.isEmpty
          ? (isConfirmed ? 'taken' : 'pending')
          : statusText,
      isConfirmed: isConfirmed,
      timeLabel: timeLabel,
      dateLabel: dateLabel,
      scheduledAt: scheduledAt,
      respondedAt: respondedAt,
      quantityTaken: _toIntNullable(json['quantityTaken']),
      remainingPills: _toIntNullable(json['remainingPills']),
      quantityPerIntake: quantityPerIntake,
      dosage: dosage,
    );
  }

  bool get canConfirm => !isConfirmed && status.toLowerCase() == 'pending';

  MedicationIntake copyWith({
    bool? isConfirmed,
    String? status,
    String? timeLabel,
    String? dateLabel,
    String? scheduledAt,
    String? respondedAt,
    int? quantityTaken,
    int? remainingPills,
    int? quantityPerIntake,
    String? dosage,
  }) {
    return MedicationIntake(
      id: id,
      medicationId: medicationId,
      medicationName: medicationName,
      status: status ?? this.status,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      timeLabel: timeLabel ?? this.timeLabel,
      dateLabel: dateLabel ?? this.dateLabel,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      respondedAt: respondedAt ?? this.respondedAt,
      quantityTaken: quantityTaken ?? this.quantityTaken,
      remainingPills: remainingPills ?? this.remainingPills,
      quantityPerIntake: quantityPerIntake ?? this.quantityPerIntake,
      dosage: dosage ?? this.dosage,
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return {};
}

int _toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toIntNullable(Object? value) {
  if (value == null) {
    return null;
  }
  final parsed = _toInt(value);
  return parsed == 0 ? null : parsed;
}

bool? _bool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final text = value?.toString().toLowerCase();
  if (text == 'true' || text == '1') {
    return true;
  }
  if (text == 'false' || text == '0') {
    return false;
  }
  return null;
}

String? _string(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? _timeOnlyLabel(Object? value) {
  final text = _string(value);
  if (text == null) {
    return null;
  }

  final timeMatch = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(
    text,
  );
  if (timeMatch == null) {
    return null;
  }

  final hour = int.tryParse(timeMatch.group(1) ?? '');
  final minute = int.tryParse(timeMatch.group(2) ?? '');
  if (hour == null || minute == null || hour > 23 || minute > 59) {
    return null;
  }

  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

DateTime? _parseMedicationDateTime(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    return null;
  }

  if (!_hasExplicitTimeZone(text)) {
    return parsed;
  }

  final costaRicaDateTime = parsed.toUtc().subtract(
    const Duration(hours: 6),
  );

  return DateTime(
    costaRicaDateTime.year,
    costaRicaDateTime.month,
    costaRicaDateTime.day,
    costaRicaDateTime.hour,
    costaRicaDateTime.minute,
    costaRicaDateTime.second,
    costaRicaDateTime.millisecond,
    costaRicaDateTime.microsecond,
  );
}

String? _formatMedicationTime(String? value) {
  final dateTime = _parseMedicationDateTime(value);
  if (dateTime == null) {
    return null;
  }

  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String? _formatMedicationDate(String? value) {
  final dateTime = _parseMedicationDateTime(value);
  if (dateTime == null) {
    return null;
  }

  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

bool _hasExplicitTimeZone(String value) {
  return RegExp(r'(Z|z|[+-]\d{2}:?\d{2})$').hasMatch(value);
}

DateTime? _dateTimeFromLabels(String? dateLabel, String? timeLabel) {
  final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeLabel ?? '');
  if (timeMatch == null) {
    return null;
  }

  final parsedDate = _datePartsFromLabel(dateLabel) ?? DateTime.now();
  final hour = int.tryParse(timeMatch.group(1) ?? '');
  final minute = int.tryParse(timeMatch.group(2) ?? '');
  if (hour == null || minute == null) {
    return null;
  }

  return DateTime(
    parsedDate.year,
    parsedDate.month,
    parsedDate.day,
    hour,
    minute,
  );
}

DateTime? _datePartsFromLabel(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final normalized = value.trim();
  final isoMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(normalized);
  if (isoMatch != null) {
    return DateTime(
      int.parse(isoMatch.group(1)!),
      int.parse(isoMatch.group(2)!),
      int.parse(isoMatch.group(3)!),
    );
  }

  final slashMatch = RegExp(
    r'^(\d{2})/(\d{2})/(\d{4})$',
  ).firstMatch(normalized);
  if (slashMatch != null) {
    return DateTime(
      int.parse(slashMatch.group(3)!),
      int.parse(slashMatch.group(2)!),
      int.parse(slashMatch.group(1)!),
    );
  }

  return null;
}
