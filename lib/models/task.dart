// lib/models/task.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final bool isDone;
  final Timestamp timestamp;

  Task({
    required this.id,
    required this.title,
    required this.isDone,
    required this.timestamp,
  });

  // Un "factory constructor" para crear una Tarea desde un documento de Firestore
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      isDone: data['isDone'] ?? false,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}