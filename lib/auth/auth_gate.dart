// lib/auth/auth_gate.dart

import 'package:casazenn/models/user_model.dart';
import 'package:casazenn/screens/select_home_screen.dart';
import 'package:casazenn/services/firestore_service.dart';
import 'package:casazenn/widgets/loading_screen.dart'; // ¡Importamos la nueva pantalla!
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:casazenn/screens/home_screen.dart';
import 'package:casazenn/screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        
        // --- ESTADO DE CARGA INICIAL ---
        // Mientras esperamos la primera respuesta de Firebase Auth, mostramos la pantalla de carga.
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        // --- CASO 1: El usuario NO ha iniciado sesión ---
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        // --- CASO 2: El usuario SÍ ha iniciado sesión ---
        // Ahora escuchamos su documento en Firestore
        return StreamBuilder<DocumentSnapshot>(
          stream: FirestoreService().getUserDocumentStream(authSnapshot.data!.uid),
          builder: (context, userDocSnapshot) {
            
            // --- ESTADO DE CARGA DEL PERFIL ---
            // Mientras esperamos los datos del perfil de Firestore, también mostramos la pantalla de carga.
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }

            // Si el documento del usuario no existe (primera vez que entra), lo mandamos a la pantalla de selección.
            if (!userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
              return SelectHomeScreen(user: authSnapshot.data!);
            }

            final userModel = UserModel.fromFirestore(userDocSnapshot.data!);
            
            // --- LÓGICA DE DECISIÓN ---
            if (userModel.homeId != null) {
              return const HomeScreen();
            } else {
              return SelectHomeScreen(user: authSnapshot.data!);
            }
          },
        );
      },
    );
  }
}