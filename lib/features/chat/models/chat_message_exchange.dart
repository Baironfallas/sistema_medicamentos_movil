import 'chat_message.dart';

class ChatMessageExchange {
  const ChatMessageExchange({
    required this.userMessage,
    required this.assistantMessage,
  });

  final ChatMessage userMessage;
  final ChatMessage assistantMessage;

  factory ChatMessageExchange.fromJson(Map<String, dynamic> json) {
    return ChatMessageExchange(
      userMessage: ChatMessage.fromJson(_object(json['userMessage'])),
      assistantMessage: ChatMessage.fromJson(_object(json['assistantMessage'])),
    );
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return {};
}
