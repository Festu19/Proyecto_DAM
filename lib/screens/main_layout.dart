// lib/screens/main_layout.dart

import 'package:casazenn/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:casazenn/screens/calendar_screen.dart';

// Esta pantalla será temporalmente un "placeholder" hasta que la programemos
class CalendarScreenPlaceholder extends StatelessWidget {
  const CalendarScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Aquí irá el Calendario y Gestión de Tareas"),
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // Lista de pantallas
  final List<Widget> _screens = [
    const HomeScreen(),            // Index 0: Tu pantalla principal actual
    const CalendarScreen(), // Index 1: La futura pantalla de calendario
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Hoy',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Planificación',
          ),
        ],
      ),
    );
  }
}