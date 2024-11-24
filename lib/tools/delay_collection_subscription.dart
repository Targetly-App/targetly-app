import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class DelayedCollectionSubscription {
  final CollectionReference collection;
  StreamSubscription<QuerySnapshot>? _subscription;
  Timer? _delayTimer;
  final Duration delay;

  DelayedCollectionSubscription({
    required this.collection,
    this.delay = const Duration(milliseconds: 500), // Default delay of 500ms
  });

  void subscribe({
    required Function(List<DocumentSnapshot>) onData,
    Function(dynamic)? onError,
  }) {
    _subscription = collection.snapshots().listen(
      (QuerySnapshot snapshot) {
        // Cancel any existing timer
        _delayTimer?.cancel();

        // Start a new timer
        _delayTimer = Timer(delay, () {
          onData(snapshot.docs);
        });
      },
      onError: onError,
    );
  }

  void dispose() {
    _delayTimer?.cancel();
    _subscription?.cancel();
  }
}
