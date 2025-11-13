// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Obtenemos una referencia a la colección 'tasks' en Firestore.
  // Si la colección no existe, Firestore la creará automáticamente.
  final CollectionReference tasksCollection =
      FirebaseFirestore.instance.collection('tasks');

  // --- MÉTODO PARA AÑADIR UNA TAREA ---
  Future<void> addTask(String taskTitle) {
    return tasksCollection.add({
      'title': taskTitle,
      'isDone': false,
      'timestamp': Timestamp.now(),
    });
  }

  // --- MÉTODO PARA OBTENER LAS TAREAS (EN TIEMPO REAL) ---
  Stream<QuerySnapshot> getTasksStream() {
    // Ordenamos las tareas por fecha de creación, las más nuevas primero.
    return tasksCollection.orderBy('timestamp', descending: true).snapshots();
  }

  // --- MÉTODO PARA ACTUALIZAR EL ESTADO DE UNA TAREA ---
  Future<void> updateTaskStatus(String taskId, bool isDone) {
    return tasksCollection.doc(taskId).update({'isDone': isDone});
  }

  // --- MÉTODO PARA ELIMINAR UNA TAREA ---
  Future<void> deleteTask(String taskId) {
    return tasksCollection.doc(taskId).delete();
  }
}