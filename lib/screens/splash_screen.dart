// lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
// Importamos la futura pantalla principal a la que navegaremos.
// Nos dará un error ahora porque aún no la hemos creado, pero se solucionará en el siguiente paso.
import 'package:casazenn/screens/home_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // Creamos un temporizador que se activará cuando la pantalla se construya.
    Timer(const Duration(seconds: 3), () {
      // Después de 3 segundos, navegamos a la HomeScreen.
      // Usamos 'pushReplacement' para que el usuario no pueda "volver" a la splash screen con el botón de retroceso.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El color de fondo debe coincidir con tu mockup.
      // Puedes usar `Color(0xFFCODIGO_HEX)` para un color exacto.
      // Este es un verde claro de ejemplo.
      backgroundColor: const Color(0xFFE3FCEF),
      body: Center(
        // Usamos el widget Image.asset para mostrar una imagen desde nuestra carpeta de assets.
        child: Image.asset(
          'assets/images/Logo_CasaZenn.png', // <-- ¡IMPORTANTE! Asegúrate de que el nombre del archivo coincida EXACTAMENTE con el de tu logo.
        ),
      ),
    );
  }
}