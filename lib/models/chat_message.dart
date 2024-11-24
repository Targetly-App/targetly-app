import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageStatus {
  sent('sent', 'Sent'),
  delivered('delivered', 'Delivered'),
  read('read', 'Read');

  const ChatMessageStatus(this.code, this.displayName);
  final String code;
  final String displayName;

  static ChatMessageStatus fromCode(String code) {
    return ChatMessageStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => ChatMessageStatus.sent,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'displayName': displayName,
      };
}

enum ChatMessageSender {
  human('user', 'Human'),
  assistant('model', 'Assistant'),
  system('system', 'System');

  const ChatMessageSender(this.code, this.displayName);
  final String code;
  final String displayName;

  static ChatMessageSender fromCode(String code) {
    return ChatMessageSender.values.firstWhere(
      (sender) => sender.code == code,
      orElse: () => ChatMessageSender.human,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'displayName': displayName,
      };
}

enum ChatMessageType {
  text('text', 'Text Message');

  const ChatMessageType(this.code, this.displayName);
  final String code;
  final String displayName;

  static ChatMessageType fromCode(String code) {
    return ChatMessageType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => ChatMessageType.text,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'displayName': displayName,
      };
}

class ChatMessage {
  final String? id;
  final String uid;
  final String message;
  final ChatMessageStatus status;
  final ChatMessageSender sender;
  final ChatMessageType type;
  final String? targetId;
  final String? taskId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatMessage({
    this.id,
    required this.uid,
    required this.message,
    this.status = ChatMessageStatus.sent,
    this.sender = ChatMessageSender.human,
    this.type = ChatMessageType.text,
    this.targetId,
    this.taskId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Create a ChatMessage from a Firestore document
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      uid: data['uid'] ?? '',
      message: data['message'] ?? '',
      status: ChatMessageStatus.fromCode(data['status'] ?? 'sent'),
      sender: ChatMessageSender.fromCode(data['sender'] ?? 'human'),
      type: ChatMessageType.fromCode(data['type'] ?? 'text'),
      targetId: data['targetId'],
      taskId: data['taskId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert ChatMessage to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'message': message,
      'status': status.code,
      'sender': sender.code,
      'type': type.code,
      'targetId': targetId,
      'taskId': taskId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy of ChatMessage with updated fields
  ChatMessage copyWith({
    String? id,
    String? uid,
    String? message,
    ChatMessageStatus? status,
    ChatMessageSender? sender,
    ChatMessageType? type,
    String? targetId,
    String? taskId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      message: message ?? this.message,
      status: status ?? this.status,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      taskId: taskId ?? this.taskId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
