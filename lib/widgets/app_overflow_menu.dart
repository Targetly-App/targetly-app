// app_overflow_menu.dart

import 'package:flutter/material.dart';

import 'list_section.dart';
import 'list_section_tile.dart';

class MenuAction {
  final String title;
  final IconData? icon;
  final Function() onTap;
  final bool isDestructive;
  final Widget? trailing;

  MenuAction({
    required this.title,
    this.icon,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
  });
}

class AppOverflowMenu extends StatelessWidget {
  final List<MenuAction> actions;

  const AppOverflowMenu({
    super.key,
    required this.actions,
  });

  double _calculateMenuWidth(BuildContext context) {
    final textStyle =
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    final padding = 16.0 * 2;
    final iconWidth = 16.0 + 16.0;

    double maxWidth = 0;

    for (final action in actions) {
      final textPainter = TextPainter(
        text: TextSpan(text: action.title, style: textStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);

      double itemWidth = textPainter.width + padding;
      if (action.icon != null) {
        itemWidth += iconWidth;
      }

      maxWidth = maxWidth > itemWidth ? maxWidth : itemWidth;
    }

    return maxWidth + 16.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<int>(
      icon: Icon(
        Icons.more_vert,
        color: theme.colorScheme.onSurface,
        size: 20,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      color: Colors.transparent,
      elevation: 0,
      position: PopupMenuPosition.under,
      constraints: BoxConstraints(
        minWidth: _calculateMenuWidth(context),
        maxWidth: _calculateMenuWidth(context),
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem<int>(
            padding: EdgeInsets.zero,
            child: ListSection(
              insetGrouped: true,
              margin: EdgeInsets.zero,
              children: actions.map((action) {
                return ListSectionTile(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  title: action.title,
                  leading: action.icon != null
                      ? Icon(
                          action.icon,
                          size: 16,
                          color: action.isDestructive
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                  trailing: const SizedBox(),
                  onTap: () {
                    Navigator.pop(context);
                    action.onTap();
                  },
                );
              }).toList(),
            ),
          ),
        ];
      },
    );
  }
}
