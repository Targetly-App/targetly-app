import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:get/get.dart';

import '../../models/chat_message.dart';
import '../../models/target.dart';
import '../../models/task.dart';
import 'chat_theme.dart';
import 'controller.dart';

@immutable
class ChatWidget extends GetWidget<ChatWidgetController> {
  final Target? target;
  final Task? task;

  const ChatWidget({super.key, this.target, this.task});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatWidgetController>(
      init: ChatWidgetController(target, task),
      assignId: true,
      builder: (controller) {
        return Obx(() {
          return controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : Chat(
                  typingIndicatorOptions: TypingIndicatorOptions(
                    typingMode: TypingIndicatorMode.name,
                    typingUsers: controller.typingUsers,
                    animationSpeed: const Duration(milliseconds: 800),
                  ),
                  theme: const TargetlyChatTheme(),
                  messages: controller.messages,
                  // onAttachmentPressed: _handleAttachmentPressed,
                  // onMessageTap: _handleMessageTap,
                  // onPreviewDataFetched: _handlePreviewDataFetched,
                  showUserAvatars: false,
                  showUserNames: false,
                  user: types.User(id: controller.currentUser.id),
                  onSendPressed: (types.PartialText message) async {
                    await controller.sendMessage(
                      message,
                      target: target,
                      task: task,
                    );
                    // remove focus from text field
                    FocusScope.of(context).unfocus();
                  },
                  bubbleBuilder: (
                    Widget child, {
                    required message,
                    required nextMessageInGroup,
                  }) =>
                      _buildBubbleWidget(
                    controller,
                    message,
                    nextMessageInGroup,
                    child,
                  ),
                  inputOptions: InputOptions(
                    enabled: controller.isOnline &&
                        controller.currentUser.isSubscribed,
                    sendButtonVisibilityMode: SendButtonVisibilityMode.editing,
                  ),
                );
        });
      },
    );
  }

  Widget _buildBubbleWidget(controller, types.Message message,
      bool nextMessageInGroup, Widget child) {
    bool isUser = controller.currentUser.id == message.author.id;
    bool isSystem = message.author.id == ChatMessageSender.system.name;

    return Bubble(
      padding: const BubbleEdges.all(0),
      color: !isUser
          ? (isSystem
              ? const Color.fromARGB(255, 111, 105, 150)
              : const Color.fromARGB(255, 26, 94, 161))
          : const Color(0xff6f61e8),
      // Use primary color
      margin: nextMessageInGroup
          ? const BubbleEdges.symmetric(horizontal: 6)
          : null,
      radius: const Radius.circular(12),
      nipRadius: 3.toDouble(),
      nip: nextMessageInGroup || isSystem
          ? BubbleNip.no
          : !isUser
              ? BubbleNip.leftBottom
              : BubbleNip.rightBottom,
      child: child,
    );
  }
}
