// lib/services/firestore_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casazenn/models/user_model.dart'; 
import 'package:casazenn/models/task.dart';// ¡Importante!

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- MÉTODOS DE USUARIO ---

  Future<void> createUserDocument(String uid, String email, String name) {
    return _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'points': 0,
      'homeId': null, // Nulo por defecto al crear el usuario
      'timestamp': Timestamp.now(),
    });
  }

  // Obtiene los datos de un usuario específico
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

   Stream<DocumentSnapshot> getUserDocumentStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }
  
  // --- MÉTODOS DE LA CASA (HOME) ---
  
  // Genera un código de invitación aleatorio y único
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  // Crea una nueva casa
  Future<String> createHome(String homeName, String userId) async {
    final newHomeRef = _db.collection('homes').doc();
    final inviteCode = _generateInviteCode();

    await newHomeRef.set({
      'name': homeName,
      'inviteCode': inviteCode,
      'members': [userId], // El creador es el primer miembro
    });

    // Actualiza el perfil del usuario con el nuevo homeId
    await _db.collection('users').doc(userId).update({'homeId': newHomeRef.id});
    
    return newHomeRef.id;
  }

  // Permite a un usuario unirse a una casa existente usando un código
  Future<String?> joinHome(String inviteCode, String userId) async {
    // Busca la casa con ese código de invitación
    final query = await _db
        .collection('homes')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final homeDoc = query.docs.first;
      
      // Añade al nuevo usuario a la lista de miembros de la casa
      await homeDoc.reference.update({
        'members': FieldValue.arrayUnion([userId])
      });

      // Actualiza el perfil del usuario con el homeId
      await _db.collection('users').doc(userId).update({'homeId': homeDoc.id});
      
      return homeDoc.id;
    }
    
    return null; // Retorna nulo si no se encontró el código
  }

// Obtiene los datos de una casa específica en tiempo real
Stream<DocumentSnapshot> getHomeStream(String homeId) {
  return _db.collection('homes').doc(homeId).snapshots();
}

// Obtiene la lista de miembros de una casa en tiempo real
Stream<QuerySnapshot> getHomeMembersStream(String homeId) {
  return _db.collection('users').where('homeId', isEqualTo: homeId).orderBy('name').snapshots();
}

// --- MÉTODOS DE TAREAS (AHORA DEPENDEN DE HOMEID) ---

// Añade una tarea a una casa específica
Future<void> addTaskToHome(String homeId, String taskTitle) {
  return _db.collection('homes').doc(homeId).collection('tasks').add({
    'title': taskTitle,
    'isDone': false,
    'timestamp': Timestamp.now(),
  });
}

// Obtiene las tareas de una casa en tiempo real
Stream<QuerySnapshot> getTasksStreamForHome(String homeId) {
  return _db
      .collection('homes')
      .doc(homeId)
      .collection('tasks')
      .orderBy('timestamp', descending: true)
      .snapshots();
}

Future<void> toggleTaskCompletion(String homeId, Task task, String userId) async {
  // Definimos cuántos puntos vale una tarea (podemos hacerlo dinámico en el futuro)
  const int taskPoints = 10;

  // Obtenemos las referencias a los dos documentos que vamos a modificar
  final taskRef = _db.collection('homes').doc(homeId).collection('tasks').doc(task.id);
  final userRef = _db.collection('users').doc(userId);

  // Ejecutamos una transacción para asegurar que ambas escrituras fallen o tengan éxito juntas
  return _db.runTransaction((transaction) async {
    // Leemos el documento del usuario DENTRO de la transacción
    final userSnapshot = await transaction.get(userRef);

    if (!userSnapshot.exists) {
      throw Exception("¡El usuario no existe!");
    }

    // Calculamos los nuevos puntos del usuario
    final currentPoints = userSnapshot.data()!['points'] as int;
    // Si la tarea NO estaba hecha, sumamos puntos. Si SÍ estaba hecha, los restamos.
    final newPoints = task.isDone ? (currentPoints - taskPoints) : (currentPoints + taskPoints);

    // Actualizamos el documento del usuario con los nuevos puntos
    transaction.update(userRef, {'points': newPoints});

    // Actualizamos el documento de la tarea para cambiar su estado 'isDone'
    transaction.update(taskRef, {'isDone': !task.isDone});
  });
}

// Borra una tarea de una casa
Future<void> deleteTaskFromHome(String homeId, String taskId) {
  return _db.collection('homes').doc(homeId).collection('tasks').doc(taskId).delete();
}

}