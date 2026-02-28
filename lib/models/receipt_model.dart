import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptModel {
  final String id;
  final String storeName;
  final String storeNameLower;
  final double totalAmount;
  final DateTime date;
  final String category;
  final DateTime createdAt;
  final String source; // manual | scan | pdf

  ReceiptModel({
    required this.id,
    required this.storeName,
    required this.storeNameLower,
    required this.totalAmount,
    required this.date,
    required this.category,
    required this.createdAt,
    required this.source,
  });

  factory ReceiptModel.fromMap(
      String id, Map<String, dynamic> map) {
    return ReceiptModel(
      id: id,
      storeName: map['storeName'] ?? '',
      storeNameLower: map['storeNameLower'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      category: map['category'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      source: map['source'] ?? 'manual',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'storeNameLower': storeNameLower,
      'totalAmount': totalAmount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'source': source,
    };
  }
}