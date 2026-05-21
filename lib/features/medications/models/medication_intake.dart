class MedicationIntake {
  MedicationIntake({
    required this.id,
    this.medicationId,
    required this.medicationName,
    required this.status,
    required this.isConfirmed,
    this.timeLabel,
    this.dateLabel,
  });

  final int id;
  final int? medicationId;
  final String medicationName;
  final String status;
  final bool isConfirmed;
  final String? timeLabel;
  final String? dateLabel;

  factory MedicationIntake.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['intakeId'] ?? json['id']);
    final medicationMap = _asMap(
      json['medication'] ?? json['medicine'] ?? json['medicationInfo'],
    );

    final name =
        _string(json['medicationName']) ??
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

    final hour =
        _string(json['hour']) ??
        _string(json['scheduledHour']) ??
        _string(json['hourLabel']);

    final date =
        _string(json['date']) ??
        _string(json['scheduledDate']) ??
        _string(json['day']);

    final timeLabel = hour ?? _timeFromIso(scheduledAt);
    final dateLabel = date ?? _dateFromIso(scheduledAt);

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
    );
  }

  bool get canConfirm => !isConfirmed && status.toLowerCase() == 'pending';

  MedicationIntake copyWith({
    bool? isConfirmed,
    String? status,
    String? timeLabel,
    String? dateLabel,
  }) {
    return MedicationIntake(
      id: id,
      medicationId: medicationId,
      medicationName: medicationName,
      status: status ?? this.status,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      timeLabel: timeLabel ?? this.timeLabel,
      dateLabel: dateLabel ?? this.dateLabel,
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

String? _timeFromIso(String? iso) {
  if (iso == null || iso.isEmpty) {
    return null;
  }
  final timePart = RegExp(r'\d{2}:\d{2}').firstMatch(iso)?.group(0);
  if (timePart != null) {
    return timePart;
  }
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) {
    return null;
  }
  final local = parsed.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String? _dateFromIso(String? iso) {
  if (iso == null || iso.isEmpty) {
    return null;
  }
  final datePart = RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(iso)?.group(0);
  if (datePart != null) {
    return datePart;
  }
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) {
    return null;
  }
  final local = parsed.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
