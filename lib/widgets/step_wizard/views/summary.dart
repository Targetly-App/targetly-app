import 'package:flutter/material.dart';

import '../widget.dart';

class StepWizardSummaryView extends StatelessWidget {
  final List<StepWizardQuestion> questions;
  final Map<String, String> answers;

  const StepWizardSummaryView({
    super.key,
    required this.questions,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          for (int i = 0; i < questions.length; i++)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  questions[i].title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  answers[questions[i].id] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
              ],
            ),
        ],
      ),
    );
  }
}
