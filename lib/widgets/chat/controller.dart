import 'dart:async';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';
import 'package:targetly/services/app_service.dart';

import '../../models/account.dart';
import '../../models/chat_message.dart';
import '../../models/target.dart';
import '../../models/task.dart';
import '../../services/chats_service.dart';
import '../../services/snack_bar_service.dart';

class ChatWidgetController extends GetxController {
  RxBool isLoading = true.obs;

  RxList<types.Message> messages = <types.Message>[].obs;
  RxList<types.User> typingUsers = <types.User>[].obs;

  Target? target;
  Task? task;
  late final Account currentUser;
  late final bool isOnline;

  // Services
  final ChatsService _chatsService = Get.find();
  final AppService appService = Get.find();

  late final StreamSubscription _chatMessagesSubscription;
  ChatWidgetController(this.target, this.task);

  @override
  void onClose() {
    _chatMessagesSubscription.cancel();
    super.onClose();
  }

  @override
  void onInit() async {
    super.onInit();
    currentUser = appService.currentAccount()!;
    isOnline = appService.isOnline();

    _chatMessagesSubscription = _chatsService
        .listenMessages(target?.id, task?.id, null)
        .listen((chatMessages) {
      isLoading.value = true;
      final loadedMessages = chatMessages.map((e) => toChatMessage(e)).toList();

      if (!currentUser.isSubscribed) {
        loadedMessages.insert(
          0,
          types.SystemMessage(
            id: 'subscription',
            text: 'Please subscribe to chat with the AI assistant',
          ),
        );
      }
      messages.assignAll(loadedMessages.toList());
      isLoading.value = false;
    });
  }

  Future<void> sendMessage(types.PartialText message,
      {Target? target, Task? task}) async {
    try {
      // Create human message object
      ChatMessage chatMessage = ChatMessage(
        uid: appService.currentAccount()!.id,
        message: message.text,
        status: ChatMessageStatus.sent,
        sender: ChatMessageSender.human,
        type: ChatMessageType.text,
        createdAt: DateTime.now(),
        targetId: target?.id,
        taskId: task?.id,
      );

      // Save message to Firestore
      chatMessage = await _chatsService.saveMessage(chatMessage);

      // Show typing indicator
      typingUsers.value = [
        const types.User(id: 'assistant', firstName: 'Assistant')
      ];
      update();

      ChatMessage assistantChatMessage =
          await _chatsService.sendMessage(chatMessage);

      assistantChatMessage =
          await _chatsService.saveMessage(assistantChatMessage);

      // Hide typing indicator
      typingUsers.value = [];
    } catch (e) {
      SnackBarService.showError('Failed to send message');
      print(e);
    }
  }

  types.Message toChatMessage(ChatMessage message) {
    return types.Message.fromJson({
      'author': {
        'firstName': '',
        'id': message.sender == ChatMessageSender.human
            ? message.uid
            : 'assistant',
        'lastName': '',
      },
      'createdAt': message.createdAt.millisecondsSinceEpoch,
      'id': message.id,
      'text': message.message,
      'type': message.type.code,
    });
  }
}
