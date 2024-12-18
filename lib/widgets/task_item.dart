import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:targetly/helpers.dart';

import '../models/task.dart';
import 'color_checkbox.dart';
import 'list_section_tile.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final Function(bool) onTaskStatusChanged;
  final bool isPlanned;
  final bool isCompleted;
  final bool isNeedAttention;
  final bool isAwaited;
  final double progress;
  final Function() toggleFn;
  final Function()? onTap;
  final bool showDescription;

  const TaskItem({
    super.key,
    required this.task,
    required this.onTaskStatusChanged,
    required this.isPlanned,
    required this.isCompleted,
    required this.isNeedAttention,
    required this.toggleFn,
    this.onTap,
    this.progress = 0.0,
    this.showDescription = false,
    this.isAwaited = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListSectionTile(
      onTap: onTap,
      leading: ColorCheckbox(
        progress: progress,
        color: generateColorFromText(task.targetId ?? "none"),
        checked: isPlanned,
        onChanged: toggleFn,
        checkIcon: isNeedAttention
            ? Iconsax.info_circle_outline
            : isAwaited
                ? Icons.check
                : Iconsax.timer_outline,
        variant: isCompleted || isNeedAttention
            ? ColorCheckboxVariant.check
            : ColorCheckboxVariant.color,
      ),
      title: task.title,
      subtitle: task.description.isNotEmpty ? task.description : null,
      subtitleOverflow: TextOverflow.ellipsis,
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDescription) Text(task.description),
          const SizedBox(height: 5),
          Wrap(
            spacing: 5,
            children: [
              Text(
                task.duration,
                style: const TextStyle(fontSize: 10),
              ),
              if (task.repeats != 'once') ...[
                const Text('•', style: TextStyle(fontSize: 10)),
                Text(
                  '${task.currentIteration}/${task.iterations}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
              const Text('•', style: TextStyle(fontSize: 10)),
              Text(
                task.repeats,
                style: const TextStyle(fontSize: 10),
              ),
              if (isNeedAttention) ...[
                const Text('•', style: TextStyle(fontSize: 10)),
                Text(
                  'Task overdue',
                  style: const TextStyle(fontSize: 10),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
