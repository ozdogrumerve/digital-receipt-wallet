import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptModel {
  final String id;
  final String storeName;
  final double totalAmount;
  final DateTime date;
  final String category;
  final String paymentType; // cash | card
  final String source; // manual | camera | pdf
  final DateTime createdAt;

  ReceiptModel({
    required this.id,
    required this.storeName,
    required this.totalAmount,
    required this.date,
    required this.category,
    required this.paymentType,
    required this.source,
    required this.createdAt,
  });

  factory ReceiptModel.fromMap(String id, Map<String, dynamic> map) {
    return ReceiptModel(
      id: id,
      storeName: map['storeName'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      category: map['category'] ?? '',
      paymentType: map['paymentType'] ?? 'cash',
      source: map['source'] ?? 'manual',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'totalAmount': totalAmount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'paymentType': paymentType,
      'source': source,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}