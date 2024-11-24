import 'package:cloud_firestore/cloud_firestore.dart';

class Target {
  final String? id;
  final String uid;
  final String title;
  final String? description;
  final DateTime? deadline;
  final DateTime? createdAt;

  Target({
    this.id,
    required this.uid,
    required this.title,
    this.description,
    this.deadline,
    this.createdAt,
  });

  // Create a Target from a Firestore document
  factory Target.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Target(
      id: doc.id,
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      deadline: data['deadline'] != null
          ? (data['deadline'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert Target to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'title': title,
      'description': description,
      'deadline': deadline != null
          ? Timestamp.fromDate(deadline!)
          : FieldValue.serverTimestamp(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // Create a copy of Target with updated fields
  Target copyWith({
    String? id,
    String? uid,
    String? title,
    String? description,
    DateTime? deadline,
    DateTime? createdAt,
  }) {
    return Target(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
