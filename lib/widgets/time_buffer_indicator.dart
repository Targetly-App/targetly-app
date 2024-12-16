import 'package:flutter/material.dart';

class TimeDetails {
  final int availableHours;
  final int requiredHours;
  final double bufferRatio;
  final TimeStatus status;

  const TimeDetails({
    required this.availableHours,
    required this.requiredHours,
    required this.bufferRatio,
    required this.status,
  });

  /// Calculate time details based on deadline and task duration
  factory TimeDetails.calculate({
    required DateTime deadline,
    required Duration totalTasksDuration,
    required int maxHoursPerDay,
  }) {
    final now = DateTime.now();

    // Handle past deadlines
    if (deadline.isBefore(now)) {
      return TimeDetails(
        availableHours: 0,
        requiredHours: totalTasksDuration.inHours,
        bufferRatio: -1,
        status: TimeStatus.critical,
      );
    }

    // Calculate available working hours until deadline
    final totalDays = deadline.difference(now).inDays;
    final availableHours = totalDays * maxHoursPerDay;
    final requiredHours = totalTasksDuration.inHours;

    // Calculate buffer ratio (how much extra time we have)
    final ratio = availableHours / requiredHours - 1;

    // Determine status based on buffer ratio
    final status = _calculateStatus(ratio);

    return TimeDetails(
      availableHours: availableHours,
      requiredHours: requiredHours,
      bufferRatio: ratio,
      status: status,
    );
  }

  static TimeStatus _calculateStatus(double ratio) {
    if (ratio < -0.2) return TimeStatus.critical; // More than 20% deficit
    if (ratio < 0) return TimeStatus.warning; // Any deficit
    if (ratio < 0.2) return TimeStatus.tight; // Less than 20% buffer
    return TimeStatus.good; // 20% or more buffer
  }

  String get statusDescription {
    switch (status) {
      case TimeStatus.critical:
        return 'Critical: Significant time deficit';
      case TimeStatus.warning:
        return 'Warning: Not enough time';
      case TimeStatus.tight:
        return 'Tight: Limited buffer time';
      case TimeStatus.good:
        return 'Good: Sufficient buffer available';
    }
  }

  Color get statusColor {
    switch (status) {
      case TimeStatus.critical:
        return Colors.red;
      case TimeStatus.warning:
        return Colors.orange;
      case TimeStatus.tight:
        return Colors.yellow.shade700;
      case TimeStatus.good:
        return Colors.green;
    }
  }

  String get bufferPercentage {
    final percentage = (bufferRatio * 100).round();
    return bufferRatio >= 0 ? '+$percentage%' : '$percentage%';
  }
}

enum TimeStatus {
  critical,
  warning,
  tight,
  good,
}

class TimeBufferIndicator extends StatelessWidget {
  final TimeDetails details;
  final double height;

  const TimeBufferIndicator({
    Key? key,
    required this.details,
    this.height = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 400;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNarrow) ...[
              _buildTimeMetricsNarrow(),
              const SizedBox(height: 8),
              // _buildBufferBadge(),
            ] else
              _buildTimeMetricsWide(),
            const SizedBox(height: 8),
            _buildProgressBar(),
            const SizedBox(height: 8),
            _buildStatusIndicator(),
          ],
        );
      },
    );
  }

  Widget _buildTimeMetricsWide() {
    return Row(
      children: [
        Expanded(
          child: _buildTimeMetricsContent(),
        ),
        const SizedBox(width: 16),
        _buildBufferBadge(),
      ],
    );
  }

  Widget _buildTimeMetricsNarrow() {
    return _buildTimeMetricsContent();
  }

  Widget _buildTimeMetricsContent() {
    final daysNeeded = (details.requiredHours / 8).ceil();
    final daysAvailable = (details.availableHours / 8).floor();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${details.requiredHours}h needed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                '≈ $daysNeeded working days',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 30,
          color: Colors.white24,
          margin: const EdgeInsets.symmetric(horizontal: 12),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${details.availableHours}h available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                '≈ $daysAvailable working days',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBufferBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: details.statusColor.withOpacity(0.2),
        border: Border.all(color: details.statusColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            details.bufferPercentage,
            style: TextStyle(
              color: details.statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'buffer',
            style: TextStyle(
              color: details.statusColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return SizedBox(
      height: 8,
      child: CustomPaint(
        size: const Size.fromHeight(8),
        painter: _TimeAllocationPainter(details: details),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: details.statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            details.statusDescription,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TimeAllocationPainter extends CustomPainter {
  final TimeDetails details;

  _TimeAllocationPainter({required this.details});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final bgPaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.fill;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Draw progress
    final progress = details.availableHours / details.requiredHours;
    final progressWidth = size.width * (progress > 1 ? 1 : progress);

    final progressPaint = Paint()
      ..color = details.statusColor
      ..style = PaintingStyle.fill;

    final progressRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, progressWidth, size.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(progressRect, progressPaint);

    // Draw required marker if we have buffer
    if (progress > 1) {
      final markerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, size.height),
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimeAllocationPainter oldDelegate) =>
      oldDelegate.details != details;
}
