import 'package:flutter/material.dart';
import 'package:targetly/helpers.dart';
import 'package:targetly/widgets/tag.dart';

import '../models/target.dart';
import '../models/task.dart';
import 'color_checkbox.dart';
import 'list_section.dart';

class Step {
  final String title;
  final String description;

  Step(this.title, this.description);
}

class TargetStepsWidget extends StatelessWidget {
  List steps = [];
  Target target;
  List<Task> tasks = [];
  Function(Task task)? onTaskTap;

  TargetStepsWidget(
      {super.key, required this.target, required this.tasks, this.onTaskTap}) {
    steps.addAll(tasks);
  }

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const SizedBox();
    }

    return ListSection(
      insetGrouped: false,
      children: [
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: steps.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            if (steps[index] is Task) {
              return _buildTask(steps[index]);
            }

            return _buildState(
              steps[index].title,
              steps[index].description,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTask(Task task) {
    bool isCompleted = task.status == TaskStatus.completed.name &&
        task.completedAt != null &&
        task.currentIteration == task.iterations;

    return ListTile(
      onTap: () => onTaskTap?.call(task),
      trailing: onTaskTap != null
          ? const Icon(
              Icons.arrow_forward_ios,
              size: 14,
            )
          : null,
      title: Text(task.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.description),
          const SizedBox(height: 5),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ColorCheckbox(
                strokeWidth: 1,
                size: 18,
                progress: task.currentIteration / task.iterations,
                color: generateColorFromText(task.targetId!),
                variant: isCompleted
                    ? ColorCheckboxVariant.check
                    : ColorCheckboxVariant.color,
                checked: task.status == TaskStatus.planned.name || isCompleted,
              ),
              const SizedBox(width: 5),
              Tag(label: task.duration),
              if (task.repeats != 'once')
                Tag(label: '${task.currentIteration} / ${task.iterations}'),
              Tag(label: task.repeats),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildState(String title, String description) {
    return ListTile(
      title: Text(title),
      subtitle: Text(description),
    );
  }
}
