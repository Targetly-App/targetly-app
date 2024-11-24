import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:targetly/models/task.dart';
import 'package:targetly/services/app_service.dart';

import '../models/account.dart';
import '../utils.dart';
import 'local_notification_service.dart';

class TasksService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _tasksRef => _firestore.collection('tasks');
  Account get account => Get.find<AppService>().currentAccount.value!;
  LocalNotificationService get _localNotificationService => Get.find();

  Timer? _batchTimer;
  // Map to store pending updates
  final Map<String, Task> _pendingUpdates = {};

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

  Future<Task> setStatus(
    Task task,
    String status, {
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    try {
      Task updatedTask = task;

      switch (status) {
        case 'completed':
          updatedTask = task.copyWith(
            completedAt: DateTime.now(),
            currentIteration: task.currentIteration + 1,
            status: task.currentIteration + 1 < task.iterations
                ? 'planned'
                : 'completed',
          );
          break;

        case 'planned':
          updatedTask = task
              .copyWith(
                plannedAt: task.plannedAt ?? DateTime.now(),
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
                currentIteration: 0,
              )
              .copyWithNull(
                plannedAt: true,
                completedAt: true,
              );
          break;
      }

      // Store the updated task in pending updates
      _pendingUpdates[task.id!] = updatedTask;

      // Cancel existing timer if any
      _batchTimer?.cancel();

      // Schedule new batch update
      _batchTimer = Timer(delay, () async {
        final updates = Map<String, Task>.from(_pendingUpdates);
        _pendingUpdates.clear();

        try {
          // Create a batch
          final batch = FirebaseFirestore.instance.batch();

          // Add all pending updates to the batch
          for (final entry in updates.entries) {
            final taskRef = _tasksRef.doc(entry.key);
            batch.update(taskRef, entry.value.toFirestore());
          }

          // Commit the batch
          await batch.commit();
        } catch (e) {
          print('Error updating Firestore batch: $e');
          // If batch fails, you might want to retry or handle the error
          // For now, we'll add the failed updates back to pending
          _pendingUpdates.addAll(updates);
        } finally {
          _batchTimer = null;
        }
      });

      // Return the updated task immediately
      return updatedTask;
    } catch (e) {
      print(e);
      throw e;
    }
  }

  // Method to force immediate update of all pending changes
  Future<void> flushUpdates() async {
    _batchTimer?.cancel();

    if (_pendingUpdates.isEmpty) return;

    final updates = Map<String, Task>.from(_pendingUpdates);
    _pendingUpdates.clear();

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final entry in updates.entries) {
        final taskRef = _tasksRef.doc(entry.key);
        batch.update(taskRef, entry.value.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      print('Error flushing updates: $e');
      _pendingUpdates.addAll(updates);
      throw e;
    }
  }

  List getTaskCompletions(Task task) {
    bool isCompleted = false;
    double timeCounterPercent = 0.0;

    if (task.status == 'completed') {
      isCompleted = true;
      timeCounterPercent = 1.0;
    } else if (task.completedAt != null) {
      int secondsToNextIteration = _getRepeatsInSeconds(task.repeats);
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

    return [isCompleted, timeCounterPercent];
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

  int _parseDuration(String duration) {
    final parts = duration.split(':');
    if (parts.length == 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return 0;
  }

  int _getRepeatsInSeconds(String repeat) {
    switch (repeat.toLowerCase()) {
      case 'daily':
        return 24 * 60 * 60;
      case 'weekly':
        return 7 * 24 * 60 * 60;
      case 'monthly':
        return 30 * 24 * 60 * 60;
      case 'once':
      default:
        return 0;
    }
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

  Future<void> updateLocalNotification(Task task) async {
    int notificationId = getEnhanced32BitFromFirestoreId(task.id!);
    bool isNeedNotify = task.iterations > 0 &&
        task.currentIteration < task.iterations &&
        TaskStatus.planned.value == task.status;
    // If task is planned, we should add notification
    if (isNeedNotify) {
      int secondsToNextIteration = _getRepeatsInSeconds(task.repeats);

      // Getting DateTime of next iteration + time until default notification time
      DateFormat format = DateFormat("h:mm a");
      DateTime defaultTime =
          format.parse(account.accountSettings.defaultNotificationsTime);
      DateTime plannedAt =
          task.plannedAt!.add(Duration(seconds: secondsToNextIteration));
      // Move time to default time
      plannedAt = plannedAt
          .add(Duration(
              hours: defaultTime.hour, minutes: defaultTime.minute, seconds: 0))
          .subtract(Duration(hours: plannedAt.hour, minutes: plannedAt.minute));

      // Notification id value must be 32 bit integer and should be based timestamp of task completedAt,
      await _localNotificationService.scheduleNotification(
        notificationId,
        task.title,
        task.description ?? '',
        plannedAt,
      );
    } else {
      await _localNotificationService.cancelNotification(notificationId);
    }
  }

  void dispose() {
    _batchTimer?.cancel();
    _pendingUpdates.clear();
  }
}
