DateTime? parseServerDateTime(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    return null;
  }

  if (parsed.isUtc || _hasExplicitTimeZone(text)) {
    return parsed.toLocal();
  }

  return parsed;
}

String? formatServerTime(String? value) {
  final dateTime = parseServerDateTime(value);
  if (dateTime == null) {
    return null;
  }

  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String? formatServerDateTime(String? value) {
  final dateTime = parseServerDateTime(value);
  if (dateTime == null) {
    return null;
  }

  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year.toString().padLeft(4, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

String? formatServerDate(String? value) {
  final dateTime = parseServerDateTime(value);
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
