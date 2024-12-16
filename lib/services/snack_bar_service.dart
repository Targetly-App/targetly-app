import 'dart:async';

import 'package:flutter/material.dart';

class SnackBarService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static OverlayEntry? _currentOverlay;
  static Timer? _timer;

  static void showSuccess(String message, {String? title}) {
    _showSnackBar(
      message,
      title: title,
      type: SnackBarType.success,
    );
  }

  static void showError(String message, {String? title}) {
    _showSnackBar(
      message,
      title: title,
      type: SnackBarType.error,
    );
  }

  static void showInfo(String message, {String? title}) {
    _showSnackBar(
      message,
      title: title,
      type: SnackBarType.info,
    );
  }

  static void _removeCurrentSnackBar() {
    _timer?.cancel();
    _timer = null;

    final overlayEntry = _currentOverlay;
    if (overlayEntry != null) {
      final context = navigatorKey.currentContext;
      if (context == null) {
        overlayEntry.remove();
        _currentOverlay = null;
        return;
      }

      AnimationController controller = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: Navigator.of(context) as TickerProvider,
      );

      controller.reverse(from: 1.0).then((_) {
        overlayEntry.remove();
        controller.dispose();
        _currentOverlay = null;
      });
    }
  }

  static void _showSnackBar(
    String message, {
    String? title,
    required SnackBarType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    _removeCurrentSnackBar();

    final theme = Theme.of(context);

    final (backgroundColor, iconData, textColor) = switch (type) {
      SnackBarType.success => (
          theme.colorScheme.primaryContainer,
          Icons.check_circle_rounded,
          theme.colorScheme.onPrimaryContainer,
        ),
      SnackBarType.error => (
          theme.colorScheme.errorContainer,
          Icons.error_rounded,
          theme.colorScheme.onErrorContainer,
        ),
      SnackBarType.info => (
          theme.colorScheme.secondaryContainer,
          Icons.info_rounded,
          theme.colorScheme.onSecondaryContainer,
        ),
    };

    final overlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.vertical,
              onDismissed: (_) => _removeCurrentSnackBar(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      iconData,
                      color: textColor,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: title != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: textColor,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: textColor,
                              ),
                            ),
                    ),
                    // IconButton(
                    //   onPressed: _removeCurrentSnackBar,
                    //   icon: Icon(
                    //     Icons.close,
                    //     color: textColor.withOpacity(0.7),
                    //     size: 20,
                    //   ),
                    //   padding: EdgeInsets.zero,
                    //   constraints: const BoxConstraints(),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _currentOverlay = overlay;

    try {
      final overlayState = Navigator.of(context).overlay;
      if (overlayState != null) {
        overlayState.insert(overlay);

        _timer = Timer(duration, _removeCurrentSnackBar);
      }
    } catch (e) {
      _currentOverlay = null;
      print('Error showing snackbar: $e');
    }
  }
}

enum SnackBarType {
  success,
  error,
  info,
}
