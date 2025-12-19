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
import 'package:intl/intl.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  
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

        if (homeId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: const Center(child: Text("No perteneces a ningún hogar.")),
          );
        }

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tareas: ${toBeginningOfSentenceCase(DateFormat('EEEE d', 'es_ES').format(DateTime.now()))}', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.cleaning_services_outlined, color: Colors.green),
                              tooltip: 'Limpiar completadas',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('¿Limpiar tareas?'),
                                    content: const Text('Se borrarán todas las tareas marcadas como completadas.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx), 
                                        child: const Text('Cancelar')
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _firestoreService.deleteCompletedTasks(homeId);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text('Borrar'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Añadir'),
                              // Usamos el NUEVO diálogo unificado
                              onPressed: () => _showTaskDialog(context, homeId),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    _buildTasksList(homeId),

                    const SizedBox(height: 24),

                    // --- SECCIÓN DE MIEMBROS ---
                    _buildSectionHeader(
                      title: 'Miembros de la casa',
                      buttonText: 'Añadir miembro',
                      onPressed: () {}, 
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
        if (snapshot.data!.docs.isEmpty) return const Text('No hay tareas.');
        
        final allTasks = snapshot.data!.docs.map((doc) => Task.fromFirestore(doc)).toList();

        // FILTRO BLINDADO
        final tasksToShow = allTasks.where((task) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          if (task.repeatDays != null && task.repeatDays!.isNotEmpty) {
            return task.repeatDays!.contains(now.weekday);
          }
          if (task.repeatDays != null && task.repeatDays!.isEmpty) return false;
          if (task.date == null) return true;

          final taskDate = DateTime(task.date!.year, task.date!.month, task.date!.day);
          return !taskDate.isAfter(today); 
        }).toList();

        if (tasksToShow.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('¡Todo limpio por hoy!'),
          );
        }

        return ListView.builder(
          itemCount: tasksToShow.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final task = tasksToShow[index];
            return Card(
              child: ListTile(
                // AL PULSAR EN LA TAREA -> EDITAR
                onTap: () => _showTaskDialog(context, homeId, taskToEdit: task),
                subtitle: (task.date != null && task.date!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))) 
                  ? Text(
                      'Atrasada del ${task.date!.day}/${task.date!.month}', 
                      style: const TextStyle(color: Colors.red, fontSize: 12)
                    )
                  : null,
                title: Text(task.title, style: TextStyle(decoration: task.isDone ? TextDecoration.lineThrough : null)),
                trailing: Checkbox(
                  value: task.isDone,
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
                      const Text('(Tú)', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
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

  // --- DIÁLOGOS ---

  void _showInviteCodeDialog(BuildContext context, String inviteCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código de Invitación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comparte este código con otros:'),
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
            child: const Text('Copiar'),
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

  // --- DIÁLOGO UNIFICADO DE TAREA (COPIADO DE CALENDAR) ---
  void _showTaskDialog(BuildContext context, String homeId, {Task? taskToEdit}) {
    final taskController = TextEditingController();
    
    if (taskToEdit != null) {
      taskController.text = taskToEdit.title;
    }

    List<int> selectedRepeatDays = [];
    bool isRepeating = false;

    if (taskToEdit != null) {
      if (taskToEdit.repeatDays != null && taskToEdit.repeatDays!.isNotEmpty) {
        isRepeating = true;
        selectedRepeatDays = List.from(taskToEdit.repeatDays!);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(taskToEdit == null ? 'Nueva Tarea' : 'Editar Tarea'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: taskController,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: "¿Qué hay que hacer?"),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text("Repetir semanalmente"),
                      const Spacer(),
                      Switch(
                        value: isRepeating,
                        onChanged: (val) {
                          setStateDialog(() {
                            isRepeating = val;
                          });
                        },
                      ),
                    ],
                  ),
                  if (isRepeating)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 5,
                        children: [
                          _buildDayButton(1, "L", selectedRepeatDays, setStateDialog),
                          _buildDayButton(2, "M", selectedRepeatDays, setStateDialog),
                          _buildDayButton(3, "X", selectedRepeatDays, setStateDialog),
                          _buildDayButton(4, "J", selectedRepeatDays, setStateDialog),
                          _buildDayButton(5, "V", selectedRepeatDays, setStateDialog),
                          _buildDayButton(6, "S", selectedRepeatDays, setStateDialog),
                          _buildDayButton(7, "D", selectedRepeatDays, setStateDialog),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (taskController.text.isNotEmpty) {
                      List<int>? finalRepeatDays = isRepeating ? selectedRepeatDays : null;
                      DateTime? finalDate;
                      
                      // Si editamos y pasamos a puntual, usaremos HOY por defecto
                      if (!isRepeating) {
                        finalDate = taskToEdit?.date ?? DateTime.now();
                      }

                      if (taskToEdit == null) {
                        _firestoreService.addTaskToHome(
                          homeId, 
                          taskController.text, 
                          date: finalDate, 
                          repeatDays: finalRepeatDays
                        );
                      } else {
                        _firestoreService.updateTask(
                          homeId, 
                          taskToEdit.id, 
                          taskController.text,
                          date: finalDate,
                          repeatDays: finalRepeatDays
                        );
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDayButton(int dayNum, String label, List<int> selectedDays, Function setStateDialog) {
    final isSelected = selectedDays.contains(dayNum);
    return GestureDetector(
      onTap: () {
        setStateDialog(() {
          if (isSelected) {
            selectedDays.remove(dayNum);
          } else {
            selectedDays.add(dayNum);
          }
        });
      },
      child: CircleAvatar(
        radius: 16,
        backgroundColor: isSelected ? Colors.green : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}