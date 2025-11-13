// lib/screens/signup_screen.dart

import 'package:casazenn/services/auth_service.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    try {
      // Llamamos al método de registro de nuestro servicio
      await _authService.signUpWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
      // Si el registro es exitoso, Firebase automáticamente inicia sesión con el nuevo usuario.
      // El AuthGate lo detectará y nos llevará a la HomeScreen, pero como ya estamos
      // en una pantalla "por encima", cerramos esta para volver al AuthGate.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Manejo de errores (ej: email ya en uso, contraseña débil)
      String errorMessage = "Ha ocurrido un error al registrarse.";
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = "Este email ya está registrado.";
      } else if (e.toString().contains('weak-password')) {
        errorMessage = "La contraseña debe tener al menos 6 caracteres.";
      }
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: const Text('Error de Registro'),
              content: Text(errorMessage),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( // Le añadimos una AppBar para poder volver atrás
        title: const Text('Registrarse'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Crear Cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}