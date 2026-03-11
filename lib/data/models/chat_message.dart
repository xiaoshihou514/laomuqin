import 'package:flutter/widgets.dart';

enum ChatMessageType { system, user, timer }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.inlineWidget,
    this.taskId,
  });

  final String id;
  final ChatMessageType type;
  final String content;
  final DateTime timestamp;

  /// Optional widget rendered below the message text (e.g. deadline action buttons, timer).
  final Widget? inlineWidget;

  /// For timer messages, the associated task id.
  final String? taskId;

  ChatMessage copyWith({
    String? id,
    ChatMessageType? type,
    String? content,
    DateTime? timestamp,
    Widget? inlineWidget,
    bool clearInlineWidget = false,
    String? taskId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      inlineWidget: clearInlineWidget ? null : inlineWidget ?? this.inlineWidget,
      taskId: taskId ?? this.taskId,
    );
  }
}
