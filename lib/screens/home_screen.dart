// lib/screens/home_screen.dart

import 'package:casazenn/models/home_model.dart';
import 'package:casazenn/models/task.dart';
import 'package:casazenn/models/user_model.dart';
import 'package:casazenn/services/auth_service.dart';
import 'package:casazenn/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final _taskController = TextEditingController();

  // Obtenemos el ID del usuario actual de forma segura
  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _firestoreService.getUserData(currentUserId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = userSnapshot.data!;
        final homeId = user.homeId;

        // Si por alguna razón el usuario no tiene homeId, mostramos un error
        if (homeId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: const Center(child: Text("No perteneces a ningún hogar. Intenta iniciar session de neuvo o crear un nuevo hogar")),
          );
        }

        // Si tenemos el homeId, construimos la pantalla principal
        return StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.getHomeStream(homeId),
          builder: (context, homeSnapshot) {
            if (!homeSnapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final home = HomeModel.fromFirestore(homeSnapshot.data!);

            return Scaffold(
              appBar: AppBar(
                title: Text(home.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _showInviteCodeDialog(context, home.inviteCode),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => _authService.signOut(),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECCIÓN DE TAREAS ---
                    _buildSectionHeader(
                      title: 'Tareas del hogar',
                      buttonText: 'Añadir tarea',
                      onPressed: () => _showAddTaskDialog(context, homeId),
                    ),
                    _buildTasksList(homeId),

                    const SizedBox(height: 24),

                    // --- SECCIÓN DE MIEMBROS ---
                    _buildSectionHeader(
                      title: 'Miembros de la casa',
                      buttonText: 'Añadir miembro',
                      onPressed: () {}, // Lógica para añadir miembros
                    ),
                    _buildMembersList(homeId),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGETS CONSTRUCTORES ---

  Widget _buildTasksList(String homeId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getTasksStreamForHome(homeId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        if (snapshot.data!.docs.isEmpty) return const Text('No hay tareas. ¡Añade la primera!');
        
        final tasks = snapshot.data!.docs.map((doc) => Task.fromFirestore(doc)).toList();

        return ListView.builder(
          itemCount: tasks.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              child: ListTile(
                title: Text(task.title, style: TextStyle(decoration: task.isDone ? TextDecoration.lineThrough : null)),
                trailing: Checkbox(
                  value: task.isDone,
                  // --- ÚNICO CAMBIO REALIZADO ---
                  // Se llama al nuevo método que maneja la transacción de puntos.
                  onChanged: (val) {
                    _firestoreService.toggleTaskCompletion(homeId, task, currentUserId);
                  },
                ),
                onLongPress: () => _firestoreService.deleteTaskFromHome(homeId, task.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMembersList(String homeId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getHomeMembersStream(homeId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        if (snapshot.data!.docs.isEmpty) return const Text('No hay miembros en esta casa.');

        final members = snapshot.data!.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

        return ListView.builder(
          itemCount: members.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final member = members[index];
            
            final bool isCurrentUser = member.uid == currentUserId;

            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(member.name.substring(0, 1))),
                title: Row(
                  children: [
                    Text(member.name),
                    const SizedBox(width: 8),
                    if (isCurrentUser)
                      const Text(
                        '(Tú)',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                  ],
                ),
                trailing: Text('${member.points} Puntos', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  // --- DIÁLOGOS Y HELPERS ---

  void _showAddTaskDialog(BuildContext context, String homeId) {
    _taskController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Tarea'),
        content: TextField(controller: _taskController, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (_taskController.text.isNotEmpty) {
                _firestoreService.addTaskToHome(homeId, _taskController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  
  void _showInviteCodeDialog(BuildContext context, String inviteCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código de Invitación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comparte este código con otros para que se unan a tu hogar:'),
            const SizedBox(height: 16),
            SelectableText(
              inviteCode,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Código copiado!')));
            },
            child: const Text('Copiar Código'),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String buttonText, required VoidCallback onPressed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton.icon(icon: const Icon(Icons.add), label: Text(buttonText), onPressed: onPressed),
      ],
    );
  }
}