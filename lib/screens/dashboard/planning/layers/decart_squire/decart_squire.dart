import 'package:flutter/cupertino.dart';

enum QuadrantType {
  urgentImportant,
  notUrgentImportant,
  urgentNotImportant,
  notUrgentNotImportant,
}

extension QuadrantTypeExtension on QuadrantType {
  String get title {
    switch (this) {
      case QuadrantType.urgentImportant:
        return 'Urgent & Important';
      case QuadrantType.notUrgentImportant:
        return 'Not Urgent & Important';
      case QuadrantType.urgentNotImportant:
        return 'Urgent & Not Important';
      case QuadrantType.notUrgentNotImportant:
        return 'Not Urgent & Not Important';
    }
  }

  Color getColor(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final opacity = brightness == Brightness.dark ? 0.2 : 0.15;

    switch (this) {
      case QuadrantType.urgentImportant:
        return CupertinoColors.systemRed.withOpacity(opacity);
      case QuadrantType.notUrgentImportant:
        return CupertinoColors.systemBlue.withOpacity(opacity);
      case QuadrantType.urgentNotImportant:
        return CupertinoColors.systemOrange.withOpacity(opacity);
      case QuadrantType.notUrgentNotImportant:
        return CupertinoColors.systemGrey.withOpacity(opacity);
    }
  }
}

class DecartSquareWidget extends StatelessWidget {
  final Function(QuadrantType) onQuadrantTap;
  final Map<QuadrantType, int> taskCounts;

  const DecartSquareWidget({
    super.key,
    required this.onQuadrantTap,
    required this.taskCounts,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        final labelWidth = isSmallScreen ? 40.0 : 60.0;
        final fontSize = isSmallScreen ? 12.0 : 14.0;

        return CupertinoTheme(
          data: CupertinoThemeData(
            brightness: MediaQuery.platformBrightnessOf(context),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 12, bottom: 8, left: labelWidth),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildHorizontalLabel(
                                context, 'Urgent', fontSize),
                          ),
                          Expanded(
                            child: _buildHorizontalLabel(
                                context, 'Not Urgent', fontSize),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: labelWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildVerticalLabel(context, 'Important', fontSize),
                          _buildVerticalLabel(
                              context, 'Not Important', fontSize),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  _buildQuadrant(
                                    context,
                                    QuadrantType.urgentImportant,
                                    fontSize,
                                  ),
                                  _buildQuadrant(
                                    context,
                                    QuadrantType.notUrgentImportant,
                                    fontSize,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  _buildQuadrant(
                                    context,
                                    QuadrantType.urgentNotImportant,
                                    fontSize,
                                  ),
                                  _buildQuadrant(
                                    context,
                                    QuadrantType.notUrgentNotImportant,
                                    fontSize,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontalLabel(
      BuildContext context, String text, double fontSize) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
    );
  }

  Widget _buildVerticalLabel(
      BuildContext context, String text, double fontSize) {
    return RotatedBox(
      quarterTurns: -1,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
      ),
    );
  }

  Widget _buildQuadrant(
      BuildContext context, QuadrantType type, double fontSize) {
    final count = taskCounts[type] ?? 0;

    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => onQuadrantTap(type),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: type.getColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: CupertinoColors.systemGrey4.resolveFrom(context),
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: CupertinoTheme.of(context)
                      .barBackgroundColor
                      .withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CupertinoColors.systemGrey4.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '$count tasks',
                  style:
                      CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                          ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
