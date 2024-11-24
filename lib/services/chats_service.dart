import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';
import 'package:targetly/services/app_service.dart';
import 'package:targetly/services/remote_functions_service.dart';

import '../models/account.dart';
import '../models/chat_message.dart';

class ChatsService extends GetxService {
  final Account _currentUser = Get.find<AppService>().currentAccount()!;
  final RemoteFunctionsService _remoteFunctionsService = Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _chatMessagesRef =>
      _firestore.collection('chatMessages');

  Stream<List> listenMessages(
    String? targetId,
    String? taskId,
    DocumentSnapshot? startAfter,
  ) {
    Query query = _chatMessagesRef.where(
      'uid',
      isEqualTo: _currentUser.id,
    );

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    if (targetId != null) {
      query = query.where('targetId', isEqualTo: targetId);
    }

    if (taskId != null) {
      query = query.where('taskId', isEqualTo: taskId);
    }

    query = query.orderBy('createdAt', descending: true);

    return query
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList())
        .startWith([]);
  }

  Future<ChatMessage> saveMessage(ChatMessage message) async {
    var docRef = await _chatMessagesRef.add(message.toFirestore());
    return ChatMessage.fromFirestore(await docRef.get());
  }

  Future<ChatMessage> sendMessage(ChatMessage message) async {
    dynamic response = await _remoteFunctionsService.call('chatMessageFlow', {
      'uid': message.uid,
      'message': message.message,
      'targetId': message.targetId,
      'taskId': message.taskId,
    });

    final assistantChatMessage = ChatMessage(
      uid: message.uid,
      message: response.toString().trim(),
      status: ChatMessageStatus.sent,
      sender: ChatMessageSender.assistant,
      type: ChatMessageType.text,
      createdAt: DateTime.now(),
      targetId: message.targetId,
      taskId: message.taskId,
    );

    return assistantChatMessage;
  }
}
