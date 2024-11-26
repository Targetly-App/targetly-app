import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const SubBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      surfaceTintColor: Colors.transparent,
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
      elevation: 0,
      titleTextStyle: Get.textTheme.bodyLarge,
      title: Align(
        alignment: Alignment.centerLeft,
        child: Text(title),
      ),
      actions: actions,
    );
  }
}
