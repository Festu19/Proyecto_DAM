// lib/auth/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:casazenn/screens/home_screen.dart';
import 'package:casazenn/screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // StreamBuilder escucha constantemente los cambios en el estado de autenticación de Firebase
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si el snapshot todavía no tiene datos, mostramos un indicador de carga
        if (!snapshot.hasData) {
          // Si no hay datos de usuario (nadie ha iniciado sesión), mostramos la LoginScreen
          return const LoginScreen();
        }

        // Si hay datos de usuario, mostramos la HomeScreen
        return const HomeScreen();
      },
    );
  }
}