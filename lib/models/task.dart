// lib/models/task.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final bool isDone;
  final DateTime? date;
  final List<int>? repeatDays;

  Task({
    required this.id,
    required this.title,
    required this.isDone,
    this.date,
    this.repeatDays,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      isDone: data['isDone'] ?? false,
      // Corrección 1: Aseguramos que la fecha se lea bien
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : null,
      // Corrección 2: Lectura BLINDADA de la lista de números.
      // Esto evita errores si Firebase guarda los números en formato raro.
      repeatDays: data['repeatDays'] != null 
          ? (data['repeatDays'] as List).map((e) => e as int).toList() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isDone': isDone,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'repeatDays': repeatDays,
    };
  }
}