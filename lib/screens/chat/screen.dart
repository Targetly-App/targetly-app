import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/chat/widget.dart';
import 'controller.dart';

class ChatScreen extends GetView<ChatViewController> {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: ChatViewController(),
      builder: (controller) {
        return SafeArea(
            child: Scaffold(
          body: ChatWidget(),
        ));
      },
    );
  }
}
