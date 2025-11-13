// lib/main.dart

import 'package:flutter/material.dart';
// 1. Importaciones necesarias para Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// 2. La función main ahora debe ser 'async'
Future<void> main() async {
  // 3. Asegurarse de que Flutter esté listo antes de llamar a Firebase
  WidgetsFlutterBinding.ensureInitialized();
  // 4. Inicializar Firebase con las opciones de la plataforma actual
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CasaZenn',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('CasaZenn'),
          backgroundColor: Colors.green.shade100,
        ),
        body: const Center(
          // Cambiamos el texto para saber que funcionó
          child: Text('¡Proyecto Conectado a Firebase!'),
        ),
      ),
    );
  }
}