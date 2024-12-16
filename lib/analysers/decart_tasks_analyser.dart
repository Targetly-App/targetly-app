import 'dart:math';

import 'package:targetly/utils.dart';

import '../models/task.dart';
import '../screens/dashboard/planning/layers/decart_squire/decart_squire.dart';

class TaskAnalysis {
  final Task task;
  final double urgency;
  final QuadrantType quadrant;
  final String priority;
  final double totalHours; // Added to track total time needed

  TaskAnalysis({
    required this.task,
    required this.urgency,
    required this.quadrant,
    required this.priority,
    required this.totalHours,
  });
}

class EisenhowerMatrix {
  final List<TaskAnalysis> q1;
  final List<TaskAnalysis> q2;
  final List<TaskAnalysis> q3;
  final List<TaskAnalysis> q4;

  const EisenhowerMatrix({
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
  });

  List<TaskAnalysis> get allTasks => [...q1, ...q2, ...q3, ...q4];

  List<TaskAnalysis> getTasksByPriority(String priority) {
    return allTasks.where((analysis) => analysis.priority == priority).toList();
  }

  List<TaskAnalysis> getTasksByQuadrant(QuadrantType quadrant) {
    switch (quadrant) {
      case QuadrantType.urgentImportant:
        return q1;
      case QuadrantType.notUrgentImportant:
        return q2;
      case QuadrantType.urgentNotImportant:
        return q3;
      case QuadrantType.notUrgentNotImportant:
        return q4;
    }
  }
}

class TaskAnalyzer {
  final double _importanceThreshold;
  final double _urgencyThreshold;

  TaskAnalyzer({
    double importanceThreshold = 6.0,
    double urgencyThreshold = 6.0,
  })  : _importanceThreshold = importanceThreshold,
        _urgencyThreshold = urgencyThreshold;

  double _calculateTotalHours(Task task) {
    // Convert duration string to hours
    double hoursPerIteration = parseDuration(task.duration) / 60;

    // Calculate remaining iterations
    int remainingIterations =
        task.repeats == 'once' ? 1 : task.iterations - task.currentIteration;

    return hoursPerIteration * remainingIterations;
  }

  EisenhowerMatrix analyzeTasksWithDeadline(
      List<Task> tasks, DateTime deadline) {
    final analyzedTasks = _analyzeTasks(tasks, deadline);

    final q1 = <TaskAnalysis>[];
    final q2 = <TaskAnalysis>[];
    final q3 = <TaskAnalysis>[];
    final q4 = <TaskAnalysis>[];

    for (final analysis in analyzedTasks) {
      switch (analysis.quadrant) {
        case QuadrantType.urgentImportant:
          q1.add(analysis);
          break;
        case QuadrantType.notUrgentImportant:
          q2.add(analysis);
          break;
        case QuadrantType.urgentNotImportant:
          q3.add(analysis);
          break;
        case QuadrantType.notUrgentNotImportant:
          q4.add(analysis);
          break;
      }
    }

    // Sort by total time needed within each quadrant
    for (final list in [q1, q2, q3, q4]) {
      list.sort((a, b) => b.totalHours.compareTo(a.totalHours));
    }

    return EisenhowerMatrix(q1: q1, q2: q2, q3: q3, q4: q4);
  }

  List<TaskAnalysis> _analyzeTasks(List<Task> tasks, DateTime deadline) {
    final daysUntilDeadline = deadline.difference(DateTime.now()).inDays;

    return tasks.map((task) {
      final totalHours = _calculateTotalHours(task);
      final urgency = _calculateTimeBasedUrgency(
        task: task,
        totalHours: totalHours,
        daysUntilDeadline: daysUntilDeadline,
      );

      return TaskAnalysis(
        task: task,
        urgency: urgency,
        totalHours: totalHours,
        quadrant: _determineQuadrant(
          importance: task.impact.toDouble(),
          urgency: urgency,
        ),
        priority: _calculatePriority(task, totalHours, daysUntilDeadline),
      );
    }).toList();
  }

  double _calculateTimeBasedUrgency({
    required Task task,
    required double totalHours,
    required int daysUntilDeadline,
  }) {
    // Base score on how many working days the task needs
    // Assuming 8-hour working days
    double workingDaysNeeded = totalHours / 8;

    // Calculate time pressure: ratio of days needed to days available
    double timePressure = workingDaysNeeded / max(1, daysUntilDeadline);

    // Convert to 0-10 scale with exponential scaling
    double urgency = min(10, 10 * (1 - exp(-timePressure * 2)));

    // Add dependency factor
    if (task.dependencies.isNotEmpty) {
      urgency = min(10, urgency + 1);
    }

    return urgency;
  }

  QuadrantType _determineQuadrant({
    required double importance,
    required double urgency,
  }) {
    if (importance >= _importanceThreshold && urgency >= _urgencyThreshold) {
      return QuadrantType.urgentImportant;
    } else if (importance >= _importanceThreshold) {
      return QuadrantType.notUrgentImportant;
    } else if (urgency >= _urgencyThreshold) {
      return QuadrantType.urgentNotImportant;
    } else {
      return QuadrantType.notUrgentNotImportant;
    }
  }

  String _calculatePriority(
      Task task, double totalHours, int daysUntilDeadline) {
    // Calculate how much of the available time this task will consume
    double workingDaysNeeded = totalHours / 8;
    double timeConsumption = workingDaysNeeded / max(1, daysUntilDeadline);

    if (timeConsumption >= 0.5 && task.impact >= 8) return 'Critical';
    if (timeConsumption >= 0.3 || task.impact >= 7) return 'High';
    if (timeConsumption >= 0.2 || task.impact >= 5) return 'Medium';
    return 'Low';
  }
}
