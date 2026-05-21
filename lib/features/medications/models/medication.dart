class MedicationSchedule {
  MedicationSchedule({this.id, required this.hour});

  final int? id;
  final String hour;

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      id: _toIntNullable(json['scheduleId'] ?? json['id']),
      hour: _string(json['hour']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'hour': hour};
  }
}

class Medication {
  Medication({
    required this.id,
    required this.name,
    this.dose,
    this.description,
    required this.quantityPerIntake,
    required this.totalPills,
    required this.startDate,
    required this.schedules,
    this.endDate,
    this.pillsRemaining,
    this.daysRemaining,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? dose;
  final String? description;
  final num quantityPerIntake;
  final num totalPills;
  final String startDate;
  final List<MedicationSchedule> schedules;
  final String? endDate;
  final num? pillsRemaining;
  final int? daysRemaining;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  factory Medication.fromJson(Map<String, dynamic> json) {
    final schedules = <MedicationSchedule>[];
    final rawSchedules = json['schedules'];

    if (rawSchedules is List) {
      for (final item in rawSchedules) {
        if (item is Map) {
          schedules.add(
            MedicationSchedule.fromJson(item.cast<String, dynamic>()),
          );
        }
      }
    }

    return Medication(
      id: _toInt(json['medicationId'] ?? json['id']),
      name: _string(json['name']) ?? '',
      dose: _nullableString(json['dose']),
      description: _nullableString(json['description']),
      quantityPerIntake: _toNum(json['quantityPerIntake']),
      totalPills: _toNum(json['totalPills']),
      startDate: _string(json['startDate']) ?? '',
      schedules: schedules,
      endDate: _nullableString(json['endDate']),
      pillsRemaining: _toNumNullable(json['pillsRemaining']),
      daysRemaining: _toIntAllowZeroNullable(json['daysRemaining']),
      isActive: _boolNullable(json['isActive']),
      createdAt: _nullableString(json['createdAt']),
      updatedAt: _nullableString(json['updatedAt']),
    );
  }

  List<String> get scheduleHours =>
      schedules.map((schedule) => schedule.hour).where(_hasText).toList();
}

class MedicationDraft {
  MedicationDraft({
    required this.name,
    this.dose,
    this.description,
    required this.quantityPerIntake,
    required this.totalPills,
    required this.startDate,
    required this.schedules,
  });

  final String name;
  final String? dose;
  final String? description;
  final int quantityPerIntake;
  final int totalPills;
  final String startDate;
  final List<String> schedules;

  factory MedicationDraft.fromMedication(Medication medication) {
    return MedicationDraft(
      name: medication.name,
      dose: medication.dose,
      description: medication.description,
      quantityPerIntake: medication.quantityPerIntake.toInt(),
      totalPills: medication.totalPills.toInt(),
      startDate: medication.startDate,
      schedules: medication.scheduleHours,
    );
  }

  Map<String, dynamic> toJson() {
    return toCreateJson();
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name.trim(),
      if (_hasText(dose)) 'dose': dose!.trim(),
      if (_hasText(description)) 'description': description!.trim(),
      'quantityPerIntake': quantityPerIntake,
      'totalPills': totalPills,
      'startDate': startDate,
      'schedules': schedules.map((hour) => {'hour': hour}).toList(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name.trim(),
      'dose': _hasText(dose) ? dose!.trim() : null,
      'description': _hasText(description) ? description!.trim() : null,
    };
  }
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

int? _toIntAllowZeroNullable(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

num _toNum(Object? value) {
  if (value is num) {
    return value;
  }
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

num? _toNumNullable(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value;
  }
  return num.tryParse(value.toString());
}

String? _string(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

String? _nullableString(Object? value) {
  final text = _string(value);
  return text == null || text.trim().isEmpty ? null : text.trim();
}

bool? _boolNullable(Object? value) {
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

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
