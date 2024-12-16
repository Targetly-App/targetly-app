import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';
import 'package:targetly/services/app_service.dart';
import 'package:targetly/services/remote_functions_service.dart';
import 'package:targetly/services/tasks_service.dart';

import '../models/account.dart';
import '../models/target.dart';
import '../models/task.dart';
import '../utils.dart';
import '../widgets/time_buffer_indicator.dart';

class ClarificationQuestion {
  final String title;
  final String question;
  final String? answerType;
  final bool multiline;
  final List<String?> answerOptions;

  ClarificationQuestion({
    required this.title,
    required this.question,
    this.answerType,
    this.multiline = false,
    this.answerOptions = const [],
  });

  factory ClarificationQuestion.fromJson(Map<String, dynamic> json) {
    return ClarificationQuestion(
      title: json['title'],
      question: json['question'],
      answerType: json['answerType'],
      multiline: json['multiline'] ?? false,
      answerOptions: json['answerOptions'] != null
          ? List<String?>.from(json['answerOptions'])
          : [],
    );
  }
}

class TargetsService extends GetxService {
  final AppService _appService = Get.find();
  final TasksService _tasksService = Get.find();
  final RemoteFunctionsService _remoteFunctionsService = Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const limitPerPage = 10;

  CollectionReference get _targetsRef => _firestore.collection('targets');

  Account get account => _appService.currentAccount()!;

  // Get a target by ID with its tasks
  Stream<Target?> listenOneById(String id) {
    return _targetsRef
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Target.fromFirestore(doc) : null);
  }

  Future<List<Target>> getTargets() async {
    final snapshot =
        await _targetsRef.where('uid', isEqualTo: account.id).get();
    return snapshot.docs.map((doc) => Target.fromFirestore(doc)).toList();
  }

  // Create a new target with tasks
  Future<Target> create(Target target, List<Task> tasks) async {
    // Create the target document
    final targetDoc = await _targetsRef.add(target.toFirestore());

    // Create sub collection for tasks
    final tasksCollection = targetDoc.collection('tasks');

    // Add all tasks
    final batch = _firestore.batch();
    for (var task in tasks) {
      final taskRef = tasksCollection.doc(task.id);
      batch.set(taskRef, task.toFirestore());
    }
    await batch.commit();

    return target.copyWith(id: targetDoc.id);
  }

  // Update an existing target
  Future<void> update(Target target) async {
    await _targetsRef.doc(target.id).update(target.toFirestore());
  }

  Stream<List<Target>> subscribe({
    int limit = limitPerPage,
    DocumentSnapshot? startAfter,
    throttle = const Duration(milliseconds: 0),
  }) {
    try {
      Query query = _targetsRef
          .where('uid', isEqualTo: account.id)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      return query
          .snapshots()
          .throttleTime(throttle)
          .map((snapshot) =>
              snapshot.docs.map((doc) => Target.fromFirestore(doc)).toList())
          .startWith([]);
    } catch (e) {
      print(e);
      return Stream.error(e);
    }
  }

  // Delete a target and all its tasks
  Future<void> delete(Target target) async {
    // First delete all tasks
    await _tasksService.deleteByTargetId(target.id!);
    // Then delete the target document
    await _targetsRef.doc(target.id).delete();
  }

  Future<List<ClarificationQuestion?>> getClarificationQuestions(
      String targetId) async {
    String uid = _appService.currentAccount()!.id;
    try {
      List<dynamic> response =
          await _remoteFunctionsService.call('requestAdditionalQuestionsFlow', {
        'uid': uid,
        'targetId': targetId,
      }) as List<dynamic>;

      List<ClarificationQuestion> questions = response
          .map((map) =>
              ClarificationQuestion.fromJson(Map<String, dynamic>.from(map)))
          .toList();

      return questions;
    } catch (e) {
      return [];
    }
  }

  Future<List<Task>> generateTasks(
      String targetId, List<Map<String, String>> answers) async {
    String uid = _appService.currentAccount()!.id;
    try {
      List<dynamic> response =
          await _remoteFunctionsService.call('generateTasksFlow', {
        'uid': uid,
        'targetId': targetId,
        'answers': answers,
      }) as List<dynamic>;

      List<Task> tasks = response
          .map((map) => Task.fromJson(Map<String, dynamic>.from(map)))
          .toList();

      return tasks;
    } catch (e) {
      print(e);
      return [];
    }
  }

  double calculateTasksTime(List<Task> tasks, {bool allIterations = false}) {
    if (tasks.isEmpty) {
      return 0;
    }

    var totalMinutes = tasks.map((task) {
      var restIterations = allIterations
          ? task.iterations
          : task.iterations - task.currentIteration;
      return parseDuration(task.duration) * restIterations;
    }).reduce((value, element) => value + element);

    return totalMinutes.toDouble();
  }

  double getCompletedPercentage(Target target, List<Task> tasks) {
    if (tasks.isEmpty) {
      return 0;
    }
    var totalMinutes = calculateTasksTime(tasks, allIterations: true);
    var restMinutes = calculateTasksTime(tasks, allIterations: false);

    return 1 - restMinutes / totalMinutes;
  }

  Future<void> deleteAll() async {
    // Delete all targets of current user
    final targets = await _targetsRef.where('uid', isEqualTo: account.id).get();
    final batch = _firestore.batch();
    for (var target in targets.docs) {
      batch.delete(target.reference);
    }
    await batch.commit();
  }

  Future<TimeDetails> getTimeDetails(Target target) async {
    var targetTasks = await _tasksService.getTasksByTargetId(target.id!);

    var notCompletedTasks = targetTasks.where((task) {
      return task.status != TaskStatus.completed.value;
    }).toList();

    var notCompletedTasksMinutes =
        calculateTasksTime(notCompletedTasks, allIterations: false);

    var details = TimeDetails.calculate(
      maxHoursPerDay:
          _appService.currentAccount.value!.settings['hoursPerDayForTasks'],
      deadline: target.deadline!,
      totalTasksDuration: Duration(minutes: notCompletedTasksMinutes.toInt()),
    );

    return details;
  }
}
