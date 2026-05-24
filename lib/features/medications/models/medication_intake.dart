import '../../../core/utils/server_date_time.dart';

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
  final String? dosage;

  DateTime? get scheduledDateTime =>
      parseServerDateTime(scheduledAt) ??
      _dateTimeFromLabels(dateLabel, timeLabel);

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

    final timeLabel = formatServerTime(scheduledAt) ?? hour;
    final dateLabel = formatServerDate(scheduledAt) ?? date;

    final dosage =
        _string(json['dosage']) ??
        _string(json['dose']) ??
        _string(medicationMap['dosage']) ??
        _string(medicationMap['dose']);

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
  final isoMatch = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})$',
  ).firstMatch(normalized);
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
