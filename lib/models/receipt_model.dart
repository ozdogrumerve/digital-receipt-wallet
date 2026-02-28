import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';

class ReceiptModel {
  final String id;
  final String storeName;
  final double totalAmount;
  final DateTime date;
  final String category;
  final DateTime createdAt;
  final String source; // manual | scan | pdf
  final List<ProductModel> products;

  ReceiptModel({
    required this.id,
    required this.storeName,
    required this.totalAmount,
    required this.date,
    required this.category,
    required this.createdAt,
    required this.source,
    required this.products,
  });

  factory ReceiptModel.fromMap(
      String id, Map<String, dynamic> map) {
    return ReceiptModel(
      id: id,
      storeName: map['storeName'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      category: map['category'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      source: map['source'] ?? 'manual',
      products: (map['products'] as List<dynamic>? ?? [])
          .map((e) => ProductModel.fromMap('', e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'totalAmount': totalAmount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'source': source,
      'products': products.map((e) => e.toMap()).toList(),
    };
  }
}