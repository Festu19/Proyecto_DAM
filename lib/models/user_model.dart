// lib/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final int points;
  final String? homeId; // Puede ser nulo si el usuario aún no se ha unido a una casa

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.points,
    this.homeId,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? 'Sin Nombre',
      email: data['email'] ?? '',
      points: data['points'] ?? 0,
      homeId: data['homeId'], // Firestore maneja bien los campos nulos
    );
  }
}