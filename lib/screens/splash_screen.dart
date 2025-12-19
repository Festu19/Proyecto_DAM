// lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
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
    
    Timer(const Duration(seconds: 3), () {
           
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      backgroundColor: const Color(0xFFE3FCEF),
      body: Center(
        
        child: Image.asset(
          'assets/images/Logo_CasaZenn.png', 
        ),
      ),
    );
  }
}