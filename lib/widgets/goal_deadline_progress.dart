// deadline_progress.dart

import 'dart:math';

import 'package:flutter/material.dart';

class DeadlineProgress {
  final double tasksTimePercentage;
  final DeadlineUrgency urgency;

  const DeadlineProgress({
    required this.tasksTimePercentage,
    required this.urgency,
  });

  factory DeadlineProgress.calculate({
    required DateTime deadline,
    required Duration totalTasksDuration,
    required int maxHoursPerDay,
  }) {
    final now = DateTime.now();
    final totalDuration = deadline.difference(now);

    // Calculate total days and available working hours
    final totalDays = totalDuration.inDays;
    final availableHours = totalDays * maxHoursPerDay;

    // Calculate task requirements
    final taskHours = totalTasksDuration.inHours;
    final requiredFullDays = taskHours ~/ maxHoursPerDay;
    final hasPartialDay = taskHours % maxHoursPerDay > 0;

    // Calculate percentage of available time needed for tasks
    final tasksTimePercentage =
        availableHours <= 0 ? 1.0 : min(1.0, taskHours / availableHours);

    // Determine urgency
    final urgency = _calculateUrgency(
      totalDays: totalDays,
      requiredDays: requiredFullDays + (hasPartialDay ? 1 : 0),
      tasksTimePercentage: tasksTimePercentage,
    );

    return DeadlineProgress(
      tasksTimePercentage: tasksTimePercentage,
      urgency: urgency,
    );
  }

  static DeadlineUrgency _calculateUrgency({
    required int totalDays,
    required int requiredDays,
    required double tasksTimePercentage,
  }) {
    if (requiredDays > totalDays) return DeadlineUrgency.critical;
    if (tasksTimePercentage >= 0.9) return DeadlineUrgency.critical;
    if (tasksTimePercentage >= 0.7) return DeadlineUrgency.high;
    if (tasksTimePercentage >= 0.5) return DeadlineUrgency.medium;
    return DeadlineUrgency.low;
  }
}

enum DeadlineUrgency { low, medium, high, critical }

extension DeadlineUrgencyExtension on DeadlineUrgency {
  Color get color {
    switch (this) {
      case DeadlineUrgency.critical:
        return Colors.red;
      case DeadlineUrgency.high:
        return Colors.orange;
      case DeadlineUrgency.medium:
        return Colors.yellow.shade700;
      case DeadlineUrgency.low:
        return Colors.green;
    }
  }
}

class DeadlineProgressBar extends StatelessWidget {
  final DeadlineProgress progress;
  final double height;
  final double borderRadius;

  const DeadlineProgressBar({
    Key? key,
    required this.progress,
    this.height = 24,
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _DeadlineProgressPainter(
          progress: progress,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class _DeadlineProgressPainter extends CustomPainter {
  final DeadlineProgress progress;
  final double borderRadius;

  _DeadlineProgressPainter({
    required this.progress,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background (available time)
    final bgPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.fill;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Draw tasks portion
    final taskWidth = size.width * progress.tasksTimePercentage;
    final taskPaint = Paint()
      ..color = progress.urgency.color
      ..style = PaintingStyle.fill;

    final taskRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - taskWidth, 0, taskWidth, size.height),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(taskRect, taskPaint);

    // Draw divider line
    if (taskWidth > 0 && taskWidth < size.width) {
      final dividerPaint = Paint()
        ..color = Colors.grey.shade900
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(size.width - taskWidth, 0),
        Offset(size.width - taskWidth, size.height),
        dividerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
