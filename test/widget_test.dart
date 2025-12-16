// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final bool isDone;
  final DateTime? date; // Fecha específica (opcional)
  final List<int>? repeatDays; // Días de la semana: 1=Lunes, 7=Domingo (opcional)

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
      // Convertimos el Timestamp de Firestore a DateTime de Dart
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : null,
      // Convertimos la lista dinámica a lista de enteros
      repeatDays: data['repeatDays'] != null ? List<int>.from(data['repeatDays']) : null,
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