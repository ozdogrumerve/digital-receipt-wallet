import 'package:cloud_firestore/cloud_firestore.dart';

enum RecurringFrequency { daily, weekly, monthly, yearly }

enum RecurringStatus { active, paused }

class RecurringModel {
  final String id;
  final String storeName;
  final String storeNameLower;
  final double amount;
  final String category;
  final RecurringFrequency frequency;
  final RecurringStatus status;
  final DateTime startDate;
  final DateTime? nextDueDate;
  final String note;
  final DateTime createdAt;

  RecurringModel({
    required this.id,
    required this.storeName,
    required this.storeNameLower,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.status,
    required this.startDate,
    this.nextDueDate,
    required this.note,
    required this.createdAt,
  });

  factory RecurringModel.fromMap(String id, Map<String, dynamic> map) {
    return RecurringModel(
      id: id,
      storeName: map['storeName'] ?? '',
      storeNameLower: map['storeNameLower'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      status: RecurringStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RecurringStatus.active,
      ),
      startDate: (map['startDate'] as Timestamp).toDate(),
      nextDueDate: map['nextDueDate'] != null
          ? (map['nextDueDate'] as Timestamp).toDate()
          : null,
      note: map['note'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'storeNameLower': storeNameLower,
      'amount': amount,
      'category': category,
      'frequency': frequency.name,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'nextDueDate':
          nextDueDate != null ? Timestamp.fromDate(nextDueDate!) : null,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RecurringModel copyWith({
    String? storeName,
    double? amount,
    String? category,
    RecurringFrequency? frequency,
    RecurringStatus? status,
    DateTime? nextDueDate,
    String? note,
  }) {
    return RecurringModel(
      id: id,
      storeName: storeName ?? this.storeName,
      storeNameLower: (storeName ?? this.storeName).toLowerCase(),
      amount: amount ?? this.amount,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      startDate: startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  DateTime computeNextDueDate(DateTime from) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurringFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }
}