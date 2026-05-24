import 'chat_message.dart';
import 'chat_session.dart';

class ChatSessionDetail {
  const ChatSessionDetail({required this.session, required this.messages});

  final ChatSession session;
  final List<ChatMessage> messages;

  factory ChatSessionDetail.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];

    return ChatSessionDetail(
      session: ChatSession.fromJson(_object(json['session'])),
      messages: rawMessages is List
          ? rawMessages
                .whereType<Map>()
                .map((item) => ChatMessage.fromJson(item.cast<String, dynamic>()))
                .toList()
          : const [],
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
