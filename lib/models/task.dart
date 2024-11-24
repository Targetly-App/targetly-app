import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskRepeats { once, hourly, daily, weekly, monthly, yearly }

enum TaskStatus {
  todo,
  planned,
  completed,
  archived,
}

extension TargetStatusExtension on TaskStatus {
  String get value {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.planned:
        return 'planned';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.archived:
        return 'archived';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.todo:
        return const Color.fromRGBO(255, 0, 0, 1);
      case TaskStatus.planned:
        return const Color.fromRGBO(255, 255, 0, 1);
      case TaskStatus.completed:
        return const Color.fromRGBO(0, 255, 0, 1);
      case TaskStatus.archived:
        return const Color.fromRGBO(0, 0, 0, 1);
    }
  }
}

TaskStatus taskStatusFromValue(String value) {
  switch (value) {
    case 'todo':
      return TaskStatus.todo;
    case 'planned':
      return TaskStatus.planned;
    case 'iteration_completed':
      return TaskStatus.completed;
    case 'completed':
      return TaskStatus.completed;
    case 'archived':
      return TaskStatus.archived;
    default:
      throw Exception('Unknown TaskStatus value');
  }
}

enum TaskRepeat {
  once,
  hourly,
  daily,
  weekly,
  monthly,
  yearly,
}

extension TaskRepeatExtension on TaskRepeat {
  int get seconds {
    switch (this) {
      case TaskRepeat.once:
        return 0;
      case TaskRepeat.hourly:
        return 3600; // 60 * 60
      case TaskRepeat.daily:
        return 86400; // 24 * 60 * 60
      case TaskRepeat.weekly:
        return 604800; // 7 * 24 * 60 * 60
      case TaskRepeat.monthly:
        return 2592000; // 30 * 24 * 60 * 60
      case TaskRepeat.yearly:
        return 31536000; // 365 * 24 * 60 * 60
    }
  }
}

TaskRepeat taskRepeatFromValue(String value) {
  switch (value) {
    case 'once':
      return TaskRepeat.once;
    case 'hourly':
      return TaskRepeat.hourly;
    case 'daily':
      return TaskRepeat.daily;
    case 'weekly':
      return TaskRepeat.weekly;
    case 'monthly':
      return TaskRepeat.monthly;
    case 'yearly':
      return TaskRepeat.yearly;
    default:
      throw Exception('Unknown TaskRepeat value');
  }
}

class Task {
  final String? id;
  final String uid;
  final String status;
  final String title;
  final String description;
  final int impact;
  final int effort;
  final String duration;
  final String repeats;
  final int iterations;
  final int currentIteration;
  final int step;
  final List<int> dependencies;
  final String? targetId;
  final bool? isCompleted;
  final bool? isPlanned;
  final DateTime? plannedAt;
  final DateTime? completedAt;
  final DateTime? notifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    this.id,
    required this.uid,
    this.status = 'todo',
    required this.title,
    required this.description,
    this.impact = 0,
    this.effort = 0,
    required this.duration,
    required this.repeats,
    required this.iterations,
    this.currentIteration = 0,
    required this.step,
    this.dependencies = const [],
    this.targetId,
    this.isCompleted = false,
    this.isPlanned = false,
    this.plannedAt,
    this.completedAt,
    this.notifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      uid: json['uid'] ?? '',
      status: json['status'] ?? 'todo',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      impact: json['impact'] ?? 0,
      effort: json['effort'] ?? 0,
      duration: json['duration'] ?? '',
      repeats: json['repeats'] ?? '',
      iterations: json['iterations'] ?? 0,
      currentIteration: json['currentIteration'] ?? 0,
      step: json['step'] ?? 0,
      dependencies: json['dependencies'] != null
          ? List<int>.from(json['dependencies'])
          : [],
      targetId: json['targetId'],
      plannedAt:
          json['plannedAt'] != null ? DateTime.parse(json['plannedAt']) : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      notifiedAt: json['notifiedAt'] != null
          ? DateTime.parse(json['notifiedAt'])
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Create a Task from a Firestore document
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      uid: data['uid'] ?? '',
      status: data['status'] ?? 'todo',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      impact: data['impact'] ?? 0,
      effort: data['effort'] ?? 0,
      duration: data['duration'] ?? '',
      repeats: data['repeats'] ?? '',
      iterations: data['iterations'] ?? 0,
      currentIteration: data['currentIteration'] ?? 0,
      step: data['step'] ?? 0,
      dependencies: data['dependencies'] != null
          ? List<int>.from(data['dependencies'])
          : [],
      targetId: data['targetId'],
      plannedAt: data['plannedAt'] != null
          ? (data['plannedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      notifiedAt: data['notifiedAt'] != null
          ? (data['notifiedAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert Task to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'status': status,
      'title': title,
      'description': description,
      'impact': impact,
      'effort': effort,
      'duration': duration,
      'repeats': repeats,
      'iterations': iterations,
      'currentIteration': currentIteration,
      'step': step,
      'dependencies': dependencies,
      'targetId': targetId,
      'plannedAt': plannedAt != null ? Timestamp.fromDate(plannedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notifiedAt': notifiedAt != null ? Timestamp.fromDate(notifiedAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': Timestamp.now(),
    };
  }

  // Create a copy of Task with updated fields
  Task copyWith({
    String? id,
    String? uid,
    String? status,
    String? title,
    String? description,
    int? impact,
    int? effort,
    String? duration,
    String? repeats,
    int? iterations,
    int? currentIteration,
    int? step,
    List<int>? dependencies,
    String? targetId,
    DateTime? plannedAt,
    DateTime? completedAt,
    DateTime? notifiedAt,
  }) {
    return Task(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      impact: impact ?? this.impact,
      effort: effort ?? this.effort,
      duration: duration ?? this.duration,
      repeats: repeats ?? this.repeats,
      iterations: iterations ?? this.iterations,
      currentIteration: currentIteration ?? this.currentIteration,
      step: step ?? this.step,
      dependencies: dependencies ?? this.dependencies,
      targetId: targetId ?? this.targetId,
      plannedAt: plannedAt ?? this.plannedAt,
      completedAt: completedAt ?? this.completedAt,
      notifiedAt: notifiedAt ?? this.notifiedAt,
    );
  }

  Task copyWithNull({
    bool? targetId = false,
    bool? isCompleted = false,
    bool? isPlanned = false,
    bool? plannedAt = false,
    bool? completedAt = false,
    bool? notifiedAt = false,
  }) {
    return Task(
      id: id,
      uid: uid,
      status: status,
      title: title,
      description: description,
      impact: impact,
      effort: effort,
      duration: duration,
      repeats: repeats,
      iterations: iterations,
      currentIteration: currentIteration,
      step: step,
      targetId: targetId == true ? null : this.targetId,
      isCompleted: isCompleted == true ? null : this.isCompleted,
      isPlanned: isPlanned == true ? null : this.isPlanned,
      plannedAt: plannedAt == true ? null : this.plannedAt,
      completedAt: completedAt == true ? null : this.completedAt,
      notifiedAt: notifiedAt == true ? null : this.notifiedAt,
    );
  }
}

enum TaskUrgency {
  critical, // Task needs immediate attention
  low // Normal isImportant task
}

extension TaskUrgencyExtension on Task {
  TaskUrgency calculateUrgency() {
    // If task is completed or archived, always low urgency
    if (status == TaskStatus.completed.value ||
        status == TaskStatus.archived.value ||
        completedAt != null) {
      return TaskUrgency.low;
    }

    final now = DateTime.now();

    // If no planned date, check repeat pattern
    if (plannedAt == null) {
      final taskRepeat = taskRepeatFromValue(repeats);
      return taskRepeat == TaskRepeat.hourly
          ? TaskUrgency.critical
          : TaskUrgency.low;
    }

    // Get the task's repeat type
    final taskRepeat = taskRepeatFromValue(repeats);

    // Calculate the next due date
    DateTime nextDue = _calculateNextDueDate(taskRepeat);

    // Calculate days until (or since) next due date
    final daysUntilDue = nextDue.difference(now).inDays;

    // Critical cases:
    // 1. Task is overdue and it's a one-time task
    // 2. Task is overdue by more than one repeat cycle
    // 3. Task is due today
    if (daysUntilDue <= 0) {
      if (taskRepeat == TaskRepeat.once ||
          daysUntilDue.abs() > (taskRepeat.seconds ~/ 86400)) {
        return TaskUrgency.critical;
      }
    }

    return TaskUrgency.low;
  }

  DateTime _calculateNextDueDate(TaskRepeat repeat) {
    if (plannedAt == null) return DateTime.now();

    final now = DateTime.now();
    DateTime nextDue = plannedAt!;

    // If it's not a repeating task or already future date, return planned date
    if (repeat == TaskRepeat.once || nextDue.isAfter(now)) {
      return nextDue;
    }

    // Calculate next occurrence based on repeat pattern
    while (nextDue.isBefore(now)) {
      switch (repeat) {
        case TaskRepeat.hourly:
          nextDue = nextDue.add(const Duration(hours: 1));
          break;
        case TaskRepeat.daily:
          nextDue = nextDue.add(const Duration(days: 1));
          break;
        case TaskRepeat.weekly:
          nextDue = nextDue.add(const Duration(days: 7));
          break;
        case TaskRepeat.monthly:
          nextDue = DateTime(nextDue.year, nextDue.month + 1, nextDue.day);
          break;
        case TaskRepeat.yearly:
          nextDue = DateTime(nextDue.year + 1, nextDue.month, nextDue.day);
          break;
        case TaskRepeat.once:
          return nextDue;
      }
    }

    return nextDue;
  }

  String getUrgencyMessage() {
    if (calculateUrgency() == TaskUrgency.critical) {
      if (plannedAt != null) {
        final daysOverdue = DateTime.now().difference(plannedAt!).inDays;
        return 'Task is overdue by $daysOverdue days!';
      }
      return 'Task needs immediate attention!';
    }
    return 'Normal isImportant task';
  }
}
