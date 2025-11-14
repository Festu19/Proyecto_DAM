// lib/screens/select_home_screen.dart

import 'package:casazenn/services/auth_service.dart';
import 'package:casazenn/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SelectHomeScreen extends StatefulWidget {
  final User user;
  const SelectHomeScreen({super.key, required this.user});

  @override
  State<SelectHomeScreen> createState() => _SelectHomeScreenState();
}

class _SelectHomeScreenState extends State<SelectHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _homeNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _homeNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  
// --- LÓGICA PARA CREAR HOGAR (VERSIÓN "DISPARA Y OLVIDA" SIMPLE) ---
void _showCreateHomeDialog() {
  _homeNameController.clear();
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Crear un Nuevo Hogar"),
        content: TextField(
          controller: _homeNameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Nombre del hogar"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () { // ¡NO es async!
              if (_homeNameController.text.isNotEmpty) {
                // "Disparamos" la orden y no esperamos.
                _firestoreService.createHome(
                  _homeNameController.text,
                  widget.user.uid,
                );
                // Cerramos el diálogo INMEDIATAMENTE.
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Crear"),
          ),
        ],
      );
    },
  );
}
// --- LÓGICA PARA UNIRSE A HOGAR (VERSIÓN SIMPLE "DISPARA Y OLVIDA") ---
void _showJoinHomeDialog() {
  _inviteCodeController.clear();
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Unirse a un Hogar"),
        content: TextField(
          controller: _inviteCodeController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Código de invitación"),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () { // ¡NO es async!
              if (_inviteCodeController.text.isNotEmpty) {
                // "Disparamos" la orden y no esperamos.
                _firestoreService.joinHome(
                  _inviteCodeController.text,
                  widget.user.uid,
                );
                // Cerramos el diálogo INMEDIATAMENTE.
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Unirse"),
          ),
        ],
      );
    },
  );
  // Al igual que con "Crear", no podemos mostrar el error "código no válido"
  // con este patrón simple, pero evitamos todos los errores.
}

  // --- ESTE ES EL MÉTODO QUE FALTABA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bienvenido a CasaZen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/images/Logo_CasaZenn.png', height: 100),
              const SizedBox(height: 48),
              const Text(
                "Para empezar, crea un nuevo hogar o únete a uno existente.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.home_work_outlined),
                label: const Text("Crear un nuevo hogar"),
                onPressed: _showCreateHomeDialog,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.group_add_outlined),
                label: const Text("Unirme a un hogar existente"),
                onPressed: _showJoinHomeDialog,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}