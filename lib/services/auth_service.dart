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
           
      throw Exception(e.code);
    }
  }

  // --- MÉTODO PARA REGISTRAR UN NUEVO USUARIO ---
  
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
  
  Future<void> signOut() async {
    return await _auth.signOut();
  }
}