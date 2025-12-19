// lib/models/reward_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RewardModel {
  final String id;
  final String title;
  final int cost;
  final String icon; 

  RewardModel({
    required this.id,
    required this.title,
    required this.cost,
    required this.icon,
  });

  factory RewardModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return RewardModel(
      id: doc.id,
      title: data['title'] ?? '',
      cost: data['cost'] ?? 0,
      icon: data['icon'] ?? 'card_giftcard',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'cost': cost,
      'icon': icon,
    };
  }
}