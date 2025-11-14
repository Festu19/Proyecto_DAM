// lib/services/auth_service.dart

import 'package:casazenn/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Obtenemos la instancia de Firebase Authentication para usarla en la clase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  
  // --- MÉTODO PARA INICIAR SESIÓN ---
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Usamos el método de Firebase para iniciar sesión con email y contraseña
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Si Firebase nos da un error (ej: contraseña incorrecta), lo capturamos
      // y lo lanzamos como una excepción para que la pantalla de login lo pueda gestionar.
      // e.code nos dará el tipo de error (ej: 'wrong-password', 'user-not-found')
      throw Exception(e.code);
    }
  }

  // --- MÉTODO PARA REGISTRAR UN NUEVO USUARIO ---
  // Lo dejaremos aquí listo para el siguiente paso
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

        // 2. Después de crearlo, crear su documento en Firestore
      await _firestoreService.createUserDocument(
        userCredential.user!.uid,
        email,
        name,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // --- MÉTODO PARA CERRAR SESIÓN ---
  // También lo dejaremos listo para usarlo más adelante
  Future<void> signOut() async {
    return await _auth.signOut();
  }
}