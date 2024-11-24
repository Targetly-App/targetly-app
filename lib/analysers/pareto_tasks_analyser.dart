import '../models/task.dart';

class ParetoAnalysis {
  final Task task;
  final double efficiency;
  final double impactPercentage;
  final double cumulativeImpact;
  final bool isVital;

  const ParetoAnalysis({
    required this.task,
    required this.efficiency,
    required this.impactPercentage,
    required this.cumulativeImpact,
    required this.isVital,
  });
}

/// Group of vital and trivial tasks
class ParetoResult {
  final List<ParetoAnalysis> vital; // vital 20%
  final List<ParetoAnalysis> trivial; // trivial 80%

  const ParetoResult({
    required this.vital,
    required this.trivial,
  });

  /// Get all tasks
  List<ParetoAnalysis> get allTasks => [...vital, ...trivial];

  /// Get total impact of all tasks
  double get vitalImpactPercentage {
    if (vital.isEmpty) return 0;
    return vital.map((a) => a.impactPercentage).reduce((a, b) => a + b);
  }

  /// Get total impact of all tasks in percentage
  double get vitalEfficiency {
    if (vital.isEmpty) return 0;
    return vital.map((a) => a.efficiency).reduce((a, b) => a + b) /
        vital.length;
  }
}

class ParetoAnalyzer {
  final double _paretoThreshold;

  ParetoAnalyzer({
    double paretoThreshold = 80.0,
  }) : _paretoThreshold = paretoThreshold;

  ParetoResult analyzeTasks(List<Task> tasks) {
    if (tasks.isEmpty) return const ParetoResult(vital: [], trivial: []);

    final totalImpact = tasks.map((t) => t.impact).reduce((a, b) => a + b);

    var analyses = tasks.map((task) {
      final efficiency = task.impact / task.effort;
      final impactPercentage = (task.impact / totalImpact) * 100;

      return ParetoAnalysis(
        task: task,
        efficiency: efficiency,
        impactPercentage: impactPercentage,
        cumulativeImpact: 0, // Будет обновлено позже
        isVital: false, // Будет обновлено позже
      );
    }).toList();

    analyses.sort((a, b) => b.task.impact.compareTo(a.task.impact));

    double cumulativePercentage = 0;
    final vital = <ParetoAnalysis>[];
    final trivial = <ParetoAnalysis>[];

    for (var analysis in analyses) {
      cumulativePercentage += analysis.impactPercentage;

      final updatedAnalysis = ParetoAnalysis(
        task: analysis.task,
        efficiency: analysis.efficiency,
        impactPercentage: analysis.impactPercentage,
        cumulativeImpact: cumulativePercentage,
        isVital: cumulativePercentage <= _paretoThreshold,
      );

      if (updatedAnalysis.isVital) {
        vital.add(updatedAnalysis);
      } else {
        trivial.add(updatedAnalysis);
      }
    }

    return ParetoResult(vital: vital, trivial: trivial);
  }
}
