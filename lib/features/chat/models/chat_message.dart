enum ChatMessageSender {
  user,
  assistant,
  unknown;

  static ChatMessageSender fromValue(Object? value) {
    final text = value?.toString().toLowerCase().trim();
    if (text == 'user') {
      return ChatMessageSender.user;
    }
    if (text == 'assistant') {
      return ChatMessageSender.assistant;
    }
    return ChatMessageSender.unknown;
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.sentAt,
  });

  final int id;
  final ChatMessageSender sender;
  final String content;
  final String sentAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _toInt(json['messageId'] ?? json['id']),
      sender: ChatMessageSender.fromValue(json['sender']),
      content: _string(json['content']) ?? '',
      sentAt: _string(json['sentAt']) ?? '',
    );
  }

  bool get isUser => sender == ChatMessageSender.user;
  bool get isAssistant => sender == ChatMessageSender.assistant;

  String get timeLabel {
    final parsed = DateTime.tryParse(sentAt);
    if (parsed == null) {
      final match = RegExp(r'\d{2}:\d{2}').firstMatch(sentAt);
      return match?.group(0) ?? '';
    }

    final local = parsed.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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

String? _string(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}
