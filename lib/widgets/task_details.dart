import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/task.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final double widthFactor;
  final double heightFactor;
  final Color backgroundColor;

  const InfoCard({
    super.key,
    required this.title,
    required this.content,
    this.widthFactor = 1.0,
    this.heightFactor = 1.0,
    this.backgroundColor = const Color(0xFF2C2C2E),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * widthFactor,
      constraints: BoxConstraints(
        minHeight: 80 * heightFactor,
      ),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              overflow: TextOverflow.ellipsis,
              title.tr.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskDetails extends StatelessWidget {
  final Task task;
  const TaskDetails({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Title card (full width)
          InfoCard(
            title: "Task title",
            content: task.title,
            backgroundColor: const Color(0xFF1C1C1E),
            heightFactor: 1.0,
          ),

          if (task.description.isNotEmpty)
            InfoCard(
              title: "Description",
              content: task.description,
              backgroundColor: const Color(0xFF1C1C1E),
              heightFactor: 1.5,
            ),

          // Bottom row with three equal cards
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  title: "Duration",
                  content: task.duration,
                  widthFactor: 1 / 3,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: InfoCard(
                  title: "Repeat",
                  content: task.repeats,
                  widthFactor: 1 / 3,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: InfoCard(
                  title: "Iterations",
                  content: "${task.currentIteration} / ${task.iterations}",
                  widthFactor: 1 / 3,
                ),
              ),
            ],
          ),
          //
          // Row(
          //   children: [
          //     Expanded(
          //       child: InfoCard(
          //         title: "Favorites",
          //         content: '1',
          //         widthFactor: 1 / 3,
          //       ),
          //     ),
          //     SizedBox(width: 10),
          //     Expanded(
          //       child: InfoCard(
          //         title: "Comments",
          //         content: '1',
          //         widthFactor: 1 / 3,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
