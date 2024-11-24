import 'dart:math';

import 'package:targetly/utils.dart';

import '../models/task.dart';
import '../screens/dashboard/planning/layers/decart_squire/decart_squire.dart';

class TaskAnalysis {
  final Task task;
  final double urgency;
  final QuadrantType quadrant;
  final String priority;

  TaskAnalysis({
    required this.task,
    required this.urgency,
    required this.quadrant,
    required this.priority,
  });
}

class EisenhowerMatrix {
  final List<TaskAnalysis> q1; // Urgent and important
  final List<TaskAnalysis> q2; // Important, but not urgent
  final List<TaskAnalysis> q3; // Urgent, but not important
  final List<TaskAnalysis> q4; // Not urgent nor important

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
    double importanceThreshold = 8.0,
    double urgencyThreshold = 8.0,
  })  : _importanceThreshold = importanceThreshold,
        _urgencyThreshold = urgencyThreshold;

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

    for (final list in [q1, q2, q3, q4]) {
      list.sort((a, b) {
        if (a.task.step != b.task.step) {
          return a.task.step.compareTo(b.task.step);
        }
        return b.urgency.compareTo(a.urgency);
      });
    }

    return EisenhowerMatrix(q1: q1, q2: q2, q3: q3, q4: q4);
  }

  List<TaskAnalysis> _analyzeTasks(List<Task> tasks, DateTime deadline) {
    final daysUntilDeadline = deadline.difference(DateTime.now()).inDays;
    List<int> steps = tasks.map((t) => t.step).toList();
    final totalSteps = steps.isEmpty ? 1 : steps.reduce(max);

    return tasks.map((task) {
      final urgency = _calculateUrgency(
        task: task,
        totalSteps: totalSteps,
        daysUntilDeadline: daysUntilDeadline,
        dependencies: _getDependentTasks(task, tasks),
      );

      return TaskAnalysis(
        task: task,
        urgency: urgency,
        quadrant: _determineQuadrant(
          importance: task.impact.toDouble(),
          urgency: urgency,
        ),
        priority: _calculatePriority(
          task: task,
          urgency: urgency,
          totalSteps: totalSteps,
        ),
      );
    }).toList();
  }

  double _calculateUrgency({
    required Task task,
    required int totalSteps,
    required int daysUntilDeadline,
    required List<Task> dependencies,
  }) {
    // Base weight of step
    final stepWeight = (totalSteps - task.step + 1) / totalSteps * 5;

    // Weight of duration
    final duration = parseDuration(task.duration) / 60;
    final durationWeight = (duration / 8) * 2;

    // Weight of deadline
    final deadlineWeight = max(0, 3 - (daysUntilDeadline / 30));

    // Weight of dependencies
    final dependencyWeight = dependencies.isEmpty
        ? 0
        : dependencies.map((d) => d.impact / 10).reduce((a, b) => a + b);

    // Weight of iterations
    final iterationWeight = task.repeats == 'once'
        ? 0
        : (task.iterations - task.currentIteration) / task.iterations;

    return min(
        10,
        stepWeight +
            durationWeight +
            deadlineWeight +
            dependencyWeight +
            iterationWeight);
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

  String _calculatePriority({
    required Task task,
    required double urgency,
    required int totalSteps,
  }) {
    if (task.step == 1 || task.dependencies.isEmpty) {
      return 'Critical';
    }

    final efficiency = task.impact / task.effort;
    final stepWeight = (totalSteps - task.step + 1) / totalSteps;
    final score = (urgency * 0.4) + (efficiency * 0.3) + (stepWeight * 0.3);

    if (score >= 8) return 'High';
    if (score >= 6) return 'Medium';
    return 'Low';
  }

  List<Task> _getDependentTasks(Task task, List<Task> allTasks) {
    return allTasks.where((t) => task.dependencies.contains(t.step)).toList();
  }
}
