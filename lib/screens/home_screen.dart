// lib/screens/home_screen.dart

import 'package:casazenn/models/task.dart';
import 'package:casazenn/services/auth_service.dart';
import 'package:casazenn/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _taskController = TextEditingController();

  void _showAddTaskDialog() {
    // Limpiamos el controlador antes de mostrar el diálogo
    _taskController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir Nueva Tarea'),
          content: TextField(
            controller: _taskController,
            autofocus: true, // Pone el foco en el campo de texto automáticamente
            decoration: const InputDecoration(hintText: "Título de la tarea"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_taskController.text.isNotEmpty) {
                  _firestoreService.addTask(_taskController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String fechaActual = DateFormat('d \'de\' MMMM', 'es_ES').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('CasaZen', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authService.signOut(),
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fechaActual, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              _buildSectionHeader(title: 'Tareas programadas', buttonText: 'Añadir tarea', onPressed: _showAddTaskDialog),
              const SizedBox(height: 8),

              StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getTasksStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No hay tareas pendientes. ¡Añade una!'),
                    ));
                  }

                  final tasks = snapshot.data!.docs.map((doc) => Task.fromFirestore(doc)).toList();
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskCard(task);
                    },
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionHeader(title: 'Miembros de la casa', buttonText: 'Añadir miembro', onPressed: () {}),
              const SizedBox(height: 8),
              _buildMemberCard(name: 'Jesus', points: 12),
              _buildMemberCard(name: 'Maria', points: 9),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String buttonText, required VoidCallback onPressed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: Text(buttonText),
          onPressed: onPressed,
        ),
      ],
    );
  }
  
  Widget _buildTaskCard(Task task) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
      child: ListTile(
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
            color: task.isDone ? Colors.grey : Colors.black,
          ),
        ),
        trailing: Checkbox(
          value: task.isDone,
          onChanged: (value) {
            if (value != null) {
              _firestoreService.updateTaskStatus(task.id, value);
            }
          },
        ),
        onLongPress: () {
          _firestoreService.deleteTask(task.id);
        },
      ),
    );
  }

  Widget _buildMemberCard({required String name, required int points}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text('$points Puntos', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ),
    );
  }
}