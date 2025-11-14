// lib/models/home_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class HomeModel {
  final String id;
  final String name;
  final String inviteCode;
  final List<String> members; // Lista de UIDs de los miembros

  HomeModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.members,
  });

  factory HomeModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HomeModel(
      id: doc.id,
      name: data['name'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      members: List<String>.from(data['members'] ?? []),
    );
  }
}