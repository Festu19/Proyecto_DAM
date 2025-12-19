// lib/services/firestore_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casazenn/models/user_model.dart'; 
import 'package:casazenn/models/task.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- MÉTODOS DE USUARIO ---

  Future<void> createUserDocument(String uid, String email, String name) {
    return _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'points': 0,
      'homeId': null, 
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
      'members': [userId], 
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
    
    return null; // Devuelve null si no se encontró el código
  }

// Obtiene los datos de una casa específica 
Stream<DocumentSnapshot> getHomeStream(String homeId) {
  return _db.collection('homes').doc(homeId).snapshots();
}

// Obtiene la lista de miembros de una casa 
Stream<QuerySnapshot> getHomeMembersStream(String homeId) {
  return _db.collection('users').where('homeId', isEqualTo: homeId).orderBy('name').snapshots();
}
// Actualiza una tarea existente
  Future<void> updateTask(String homeId, String taskId, String title, {DateTime? date, List<int>? repeatDays}) {
    DateTime? cleanDate;
    if (date != null) {
      cleanDate = DateTime(date.year, date.month, date.day);
    }

    return _db.collection('homes').doc(homeId).collection('tasks').doc(taskId).update({
      'title': title,
      'date': cleanDate != null ? Timestamp.fromDate(cleanDate) : null,
      'repeatDays': repeatDays, 
    });
  }




// --- MÉTODOS DE TAREAS ---

  // Añade una tarea con fecha opcional O días de repetición
  Future<void> addTaskToHome(String homeId, String taskTitle, {DateTime? date, List<int>? repeatDays}) {
    DateTime? cleanDate;
    if (date != null) {
      cleanDate = DateTime(date.year, date.month, date.day);
    }

    return _db.collection('homes').doc(homeId).collection('tasks').add({
      'title': taskTitle,
      'isDone': false,
      'timestamp': Timestamp.now(),
      'date': cleanDate != null ? Timestamp.fromDate(cleanDate) : null,
      'repeatDays': repeatDays,
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
  // Definimos cuántos puntos vale una tarea 
  const int taskPoints = 10;

  // Obtenemos las referencias a los dos documentos que vamos a modificar
  final taskRef = _db.collection('homes').doc(homeId).collection('tasks').doc(task.id);
  final userRef = _db.collection('users').doc(userId);

  // Ejecutamos una transacción para asegurar que ambas escrituras fallen o tengan éxito juntas
  return _db.runTransaction((transaction) async {
    
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
// NUEVO: Borra todas las tareas completadas de una casa en lote
  Future<void> deleteCompletedTasks(String homeId) async {
    // 1. Buscamos todas las tareas que tengan isDone == true
    final snapshot = await _db
        .collection('homes')
        .doc(homeId)
        .collection('tasks')
        .where('isDone', isEqualTo: true)
        .get();

    // 2. Iniciamos un lote de escritura 
    WriteBatch batch = _db.batch();

    // 3. Añadimos cada operación de borrado al lote
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    // 4. Ejecutamos todas las operaciones juntas
    await batch.commit();
  }


  // --- MÉTODOS DE LA TIENDA DE RECOMPENSAS ---

  // Obtener stream de recompensas
  Stream<QuerySnapshot> getRewardsStream(String homeId) {
    return _db.collection('homes').doc(homeId).collection('rewards').orderBy('cost').snapshots();
  }

  // Añadir una recompensa
  Future<void> addReward(String homeId, String title, int cost, String iconName) {
    return _db.collection('homes').doc(homeId).collection('rewards').add({
      'title': title,
      'cost': cost,
      'icon': iconName,
    });
  }

  // Borrar una recompensa
  Future<void> deleteReward(String homeId, String rewardId) {
    return _db.collection('homes').doc(homeId).collection('rewards').doc(rewardId).delete();
  }

// --- MÉTODOS DE HISTORIAL Y CANJE ---

  // Obtener historial de actividad
  Stream<QuerySnapshot> getHistoryStream(String homeId) {
    return _db
        .collection('homes')
        .doc(homeId)
        .collection('history')
        .orderBy('timestamp', descending: true) 
        .limit(20) 
        .snapshots();
  }

  // CANJEAR RECOMPENSA 
  Future<bool> redeemReward(String userId, String homeId, String userName, String rewardTitle, int cost) async {
    final userRef = _db.collection('users').doc(userId);
    final historyRef = _db.collection('homes').doc(homeId).collection('history');

    try {
      await _db.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) throw Exception("Usuario no encontrado");

        final currentPoints = userSnapshot.data()!['points'] as int;

        if (currentPoints < cost) {
          throw Exception("No tienes suficientes puntos");
        }

        // 1. Restamos los puntos
        transaction.update(userRef, {'points': currentPoints - cost});

        // 2. Creamos el registro en el historial
                 
      });

      // 3. Escribimos en el historial (Fuera de la transacción estricta para simplificar, pero seguro)
      await historyRef.add({
        'text': '$userName ha canjeado: $rewardTitle',
        'cost': cost,
        'timestamp': Timestamp.now(),
        'type': 'redemption', 
      });

      return true; 
    } catch (e) {
      print(e);
      return false;
    }
  }
  // Borrar un item del historial (para marcar como cumplido)
  Future<void> deleteHistoryItem(String homeId, String historyId) {
    return _db.collection('homes').doc(homeId).collection('history').doc(historyId).delete();
  }
}
