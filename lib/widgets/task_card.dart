import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:targetly/widgets/task_item.dart';

import '../models/task.dart';

class TaskCardWidget extends StatelessWidget {
  final Task task;
  final bool isPlanned;
  final bool isCompleted;
  final double progress;
  final Function()? onTap;
  final Function()? toggleFn;

  const TaskCardWidget(this.task,
      {super.key,
      this.onTap,
      this.isPlanned = false,
      this.isCompleted = false,
      this.progress = 0.0,
      required this.toggleFn});

  @override
  Widget build(BuildContext context) {
    bool isAchieved = isCompleted &&
        task.status == TaskStatus.completed.value &&
        task.currentIteration == task.iterations;
    return TaskItem(
      onTap: onTap,
      task: task,
      progress: isAchieved ? 1.0 : progress,
      isPlanned: [TaskStatus.planned.value, TaskStatus.completed.value]
          .contains(task.status),
      isCompleted: isCompleted,
      isAwaited: isAchieved,
      onTaskStatusChanged: (bool value) {
        toggleFn!();
      },
      toggleFn: toggleFn!,
    );
  }
}
