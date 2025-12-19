// lib/screens/calendar_screen.dart

import 'package:casazenn/models/task.dart';
import 'package:casazenn/models/user_model.dart';
import 'package:casazenn/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  bool isSameDate(DateTime? date1, DateTime date2) {
    if (date1 == null) return false;
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _firestoreService.getUserData(currentUserId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final homeId = userSnapshot.data!.homeId;
        if (homeId == null) return const Scaffold(body: Center(child: Text("Error: Sin hogar")));

        return StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getTasksStreamForHome(homeId),
          builder: (context, taskSnapshot) {
            if (!taskSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

            final allTasks = taskSnapshot.data!.docs.map((doc) => Task.fromFirestore(doc)).toList();

            final tasksForSelectedDay = allTasks.where((task) {
              if (task.date != null && isSameDate(task.date, _selectedDay!)) return true;
              if (task.repeatDays != null && task.repeatDays!.contains(_selectedDay!.weekday)) return true;
              return false;
            }).toList();

            return Scaffold(
              appBar: AppBar(title: const Text("Planificación")),
              floatingActionButton: FloatingActionButton(
                // Aquí llamamos al diálogo SIN tarea (Modo Crear)
                onPressed: () => _showTaskDialog(context, homeId, date: _selectedDay!),
                child: const Icon(Icons.add),
              ),
              body: Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    locale: 'es_ES',
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                      selectedDecoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      markersMaxCount: 1,
                    ),
                    eventLoader: (day) {
                      return allTasks.where((task) {
                        if (task.date != null && isSameDate(task.date, day)) return true;
                        if (task.repeatDays != null && task.repeatDays!.contains(day.weekday)) return true;
                        return false;
                      }).toList();
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isNotEmpty) {
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6.0),
                              width: 8.0,
                              height: 8.0,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                  const Divider(),
                  Expanded(
                    child: tasksForSelectedDay.isEmpty
                        ? Center(child: Text("Sin tareas para el ${DateFormat('dd/MM').format(_selectedDay!)}"))
                        : ListView.builder(
                            itemCount: tasksForSelectedDay.length,
                            itemBuilder: (context, index) {
                              final task = tasksForSelectedDay[index];
                              
                              String subtitle = "";
                              if (task.repeatDays != null && task.repeatDays!.isNotEmpty) {
                                subtitle = "Repite: ${_formatWeekdays(task.repeatDays!)}";
                              } else if (task.date != null) {
                                subtitle = DateFormat('dd/MM/yyyy').format(task.date!);
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  // Al pulsar el texto, abrimos MODO EDICIÓN
                                  onTap: () => _showTaskDialog(context, homeId, taskToEdit: task),
                                  title: Text(task.title),
                                  subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  trailing: Checkbox(
                                    value: task.isDone,
                                    onChanged: (val) => _firestoreService.toggleTaskCompletion(homeId, task, currentUserId),
                                  ),
                                  onLongPress: () => _firestoreService.deleteTaskFromHome(homeId, task.id),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper para mostrar días bonitos (L, M, X...)
  String _formatWeekdays(List<int> days) {
    const map = {1: 'L', 2: 'M', 3: 'X', 4: 'J', 5: 'V', 6: 'S', 7: 'D'};
    // Ordenamos los días y los mapeamos a letras
    days.sort();
    return days.map((d) => map[d]).join(', ');
  }

  // --- DIÁLOGO UNIFICADO (CREAR Y EDITAR) ---
  void _showTaskDialog(BuildContext context, String homeId, {Task? taskToEdit, DateTime? date}) {
    final taskController = TextEditingController();
    
    // Si estamos editando, rellenamos los datos
    if (taskToEdit != null) {
      taskController.text = taskToEdit.title;
    }

    // Lógica inicial de repetición
    List<int> selectedRepeatDays = [];
    bool isRepeating = false;

    if (taskToEdit != null) {
      // Si editamos, cargamos la configuración existente
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
                      // DATOS FINALES A GUARDAR
                      List<int>? finalRepeatDays = isRepeating ? selectedRepeatDays : null;
                      
               
                      DateTime? finalDate;
                      if (!isRepeating) {
                        finalDate = date ?? taskToEdit?.date ?? DateTime.now();
                      }

                      if (taskToEdit == null) {
                        // --- CREAR ---
                        _firestoreService.addTaskToHome(
                          homeId, 
                          taskController.text, 
                          date: finalDate, 
                          repeatDays: finalRepeatDays
                        );
                      } else {
                        // --- ACTUALIZAR ---
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