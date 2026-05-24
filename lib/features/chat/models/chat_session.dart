class ChatSession {
  const ChatSession({
    required this.id,
    this.title,
    required this.startedAt,
    required this.lastActivity,
  });

  final int id;
  final String? title;
  final String startedAt;
  final String lastActivity;

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: _toInt(json['sessionId'] ?? json['id']),
      title: _nullableString(json['title']),
      startedAt: _string(json['startedAt']) ?? '',
      lastActivity: _string(json['lastActivity']) ?? '',
    );
  }

  String get displayTitle {
    final value = title?.trim();
    if (value == null || value.isEmpty) {
      return 'Chat sin titulo';
    }
    return value;
  }

  String get lastActivityLabel => _readableDateTime(lastActivity);
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

String _readableDateTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  final local = parsed.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString().padLeft(4, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
