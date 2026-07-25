import 'message.dart';

class Conversation {
  final String id;
  final String title;
  final String model;
  final String personality;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.model,
    required this.personality,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    var messagesList = json['messages'] as List?;
    List<Message> parsedMessages = messagesList != null
        ? messagesList
            .map((m) => Message.fromJson(m as Map<String, dynamic>))
            .toList()
        : [];

    return Conversation(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      model: json['model'] as String? ?? '',
      personality: json['personality'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      messages: parsedMessages,
    );
  }

  Conversation copyWith({
    String? id,
    String? title,
    String? model,
    String? personality,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      model: model ?? this.model,
      personality: personality ?? this.personality,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}
