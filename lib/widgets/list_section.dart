import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ListSection extends StatelessWidget {
  final List<Widget> children;
  final String? title;
  final bool insetGrouped;
  final EdgeInsets? margin;

  const ListSection(
      {super.key,
      required this.children,
      this.title,
      this.insetGrouped = true,
      this.margin});

  @override
  Widget build(BuildContext context) {
    return insetGrouped
        ? CupertinoListSection.insetGrouped(
            backgroundColor: Colors.transparent,
            topMargin: 0.0,
            additionalDividerMargin: 0.0,
            hasLeading: false,
            margin: margin ?? const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            header: title != null
                ? Text(
                    title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  )
                : null,
            separatorColor: Theme.of(context).dividerColor,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(50, 50, 62, 1),
            ),
            children: children,
          )
        : CupertinoListSection(
            topMargin: 0.0,
            additionalDividerMargin: 0.0,
            margin: EdgeInsets.zero,
            header: title != null
                ? Text(
                    title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                  )
                : null,
            separatorColor: Theme.of(context).dividerColor,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            decoration: BoxDecoration(
              color: Color.fromRGBO(50, 50, 62, 1),
            ),
            children: children,
          );
  }
}
