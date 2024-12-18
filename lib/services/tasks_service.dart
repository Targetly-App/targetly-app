import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';
import 'package:targetly/models/task.dart';
import 'package:targetly/services/app_service.dart';
import 'package:targetly/services/local_notification_service.dart';

import '../models/account.dart';
import '../models/target.dart';

class TasksService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _tasksRef => _firestore.collection('tasks');
  Account get account => Get.find<AppService>().currentAccount.value!;
  final LocalNotificationService _localNotificationService = Get.find();

  Stream<List<Task>> subscribeOnTargetId({required String targetId}) {
    return _tasksRef
        .where('uid', isEqualTo: account.id)
        .where('targetId', isEqualTo: targetId)
        .orderBy('step', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList())
        .startWith([]);
  }

  Stream<List<Task>> subscribe({List<String>? statuses}) {
    try {
      Query query = _tasksRef.where('uid', isEqualTo: account.id);

      // Apply filters
      if (statuses != null && statuses.isNotEmpty) {
        query = query.where('status', whereIn: statuses);
      }

      query = query.orderBy('step', descending: false);

      // Convert to stream
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
      }).startWith([]);
    } catch (e) {
      print(e);
      // For streams, we need to return an error stream instead of throwing
      return Stream.error(e);
    }
  }

  Future<List<Task>> getTasks({List<String>? statuses}) async {
    try {
      Query query = _tasksRef.where('uid', isEqualTo: account.id);

      // Apply filters
      if (statuses != null && statuses.isNotEmpty) {
        query = query.where('status', whereIn: statuses);
      }

      query = query.orderBy('step', descending: false);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<Task> setStatus(Task task, String status,
      {WriteBatch? batch, bool resetIterations = true}) async {
    try {
      Task updatedTask = task;

      switch (status) {
        case 'completed':
          updatedTask = task.copyWith(
            completedAt: DateTime.now(),
            currentIteration: task.currentIteration + 1,
          );
          if (task.currentIteration + 1 < task.iterations) {
            // If task still has iterations we should set status 'planned'
            // At same time if task was planned again we need update notification,
            // but notification time based on plannedAt, so we need update it also
            updatedTask = updatedTask.copyWith(
              status: 'planned',
              plannedAt: DateTime.now(),
            );
          } else {
            updatedTask = updatedTask.copyWith(status: 'completed');
          }
          break;

        case 'planned':
          updatedTask = task
              .copyWith(
                // We always should update planned time on change status to planned
                plannedAt: DateTime.now(),
                status: 'planned',
                currentIteration:
                    task.completedAt != null && task.currentIteration > 0
                        ? task.currentIteration - 1
                        : task.currentIteration,
              )
              .copyWithNull(
                completedAt: true,
              );
          break;

        case 'todo':
          updatedTask = task
              .copyWith(
                status: 'todo',
                currentIteration: resetIterations ? 0 : task.currentIteration,
              )
              .copyWithNull(
                plannedAt: true,
                completedAt: true,
              );
          break;
      }

      if (batch != null) {
        batch.update(_tasksRef.doc(task.id), updatedTask.toFirestore());
      } else {
        await _tasksRef.doc(task.id).update(updatedTask.toFirestore());
      }

      return updatedTask;
    } catch (e) {
      print(e);
      throw e;
    }
  }

  List getTaskCompletions(Task task) {
    bool isCompleted = false;
    double timeCounterPercent = 0.0;
    bool userNotified = false;

    DateTime? nextNotificationTime =
        _localNotificationService.calculateNextNotificationDate(task);
    if (nextNotificationTime == null) {
      userNotified = true;
    }

    if (task.status == 'completed') {
      isCompleted = true;
      timeCounterPercent = 1.0;
    } else if (task.completedAt != null) {
      // Getting next notification time
      int secondsToNextIteration = 0;
      if (task.status == TaskStatus.planned.value && task.plannedAt != null) {
        if (nextNotificationTime != null) {
          secondsToNextIteration =
              nextNotificationTime.difference(DateTime.now()).inSeconds;
        }
      }

      if (secondsToNextIteration == 0) {
        isCompleted = true;
        timeCounterPercent = 1.0;
      } else {
        timeCounterPercent = task.completedAt!
            .add(Duration(seconds: secondsToNextIteration))
            .difference(DateTime.now())
            .inSeconds
            .toDouble();
        timeCounterPercent /= secondsToNextIteration;
        isCompleted = timeCounterPercent > 0;
      }
    }

    return [isCompleted, timeCounterPercent, userNotified];
  }

  Future<Task?> getById(String id) async {
    final doc = await _tasksRef.doc(id).get();
    if (!doc.exists) return null;
    return Task.fromFirestore(doc);
  }

  Future<void> create(Task task) async {
    final taskData = task.toFirestore();
    await _tasksRef.doc(task.id).set(taskData);
  }

  Future<void> update(Task task) async {
    final taskData = task.toFirestore();
    await _tasksRef.doc(task.id).update(taskData);
  }

  Future<void> delete(String id) async {
    await _tasksRef.doc(id).delete();
  }

  Future<void> deleteByTargetId(String targetId) async {
    final batch = _firestore.batch();

    final tasks = await _tasksRef
        .where('uid', isEqualTo: account.id)
        .where('targetId', isEqualTo: targetId)
        .get();

    for (var task in tasks.docs) {
      batch.delete(_tasksRef.doc(task.id));
    }

    await batch.commit();
  }

  Future<List<Task>> getTasksByTargetId(String targetId) async {
    final tasks = await _tasksRef
        .where('uid', isEqualTo: account.id)
        .where('targetId', isEqualTo: targetId)
        .get();

    return tasks.docs.map((doc) => Task.fromFirestore(doc)).toList();
  }

  Future<void> deleteBatch(List<Task> tasks) async {
    final batch = _firestore.batch();

    for (var task in tasks) {
      batch.delete(_tasksRef.doc(task.id));
    }

    await batch.commit();
  }

  Future<void> deleteAll() async {
    // Delete all tasks of current user
    final tasks = await _tasksRef.where('uid', isEqualTo: account.id).get();
    final batch = _firestore.batch();
    for (var task in tasks.docs) {
      batch.delete(task.reference);
    }
    await batch.commit();
  }

  Future<void> markAllAsCompletedByTarget(Target target) async {
    final tasks = await getTasksByTargetId(target.id!);
    final batch = _firestore.batch();
    for (var task in tasks) {
      Task updatedTask = task.copyWith(currentIteration: task.iterations - 1);
      await setStatus(updatedTask, 'completed', batch: batch);
    }
    await batch.commit();
  }

  Future<void> resetAllTasksStatusByTarget(Target target) async {
    final tasks = await getTasksByTargetId(target.id!);
    final batch = _firestore.batch();
    for (var task in tasks) {
      await setStatus(task, 'todo', batch: batch);
    }
    await batch.commit();
  }
}
