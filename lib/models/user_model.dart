import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photo;
  final double monthlyBudget;
  final DateTime createdAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photo,
    required this.monthlyBudget,
    required this.createdAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photo: map['photo'],
      monthlyBudget: (map['monthlyBudget'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isDeleted: map['isDeleted'] ?? false,
      deletedAt: map['deletedAt'] != null
          ? (map['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photo': photo,
      'monthlyBudget': monthlyBudget,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }
}