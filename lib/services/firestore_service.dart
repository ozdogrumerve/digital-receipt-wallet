import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/receipt_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// =====================================================
  /// USER
  /// =====================================================

  Future<void> createUserIfNotExists(UserModel user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    }
  }

  Future<UserModel?> getUser() async {
    final doc =
        await _firestore.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Stream<UserModel?> getUserStream() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .snapshots()
        .map((doc) =>
            doc.exists ? UserModel.fromMap(doc.id, doc.data()!) : null);
  }

  Future<void> updateMonthlyBudget(double budget) async {
    await _firestore.collection('users').doc(_uid).update({
      'monthlyBudget': budget,
    });
  }

  Future<void> updateProfilePhoto(String base64) async {
    await _firestore.collection('users').doc(_uid).update({
      'photo': base64,
    });
  }

  /// =====================================================
  /// TRANSACTIONS (MAIN DATA STRUCTURE)
  /// =====================================================

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore
          .collection('users')
          .doc(_uid)
          .collection('transactions');

  Future<String> addTransaction(ReceiptModel receipt) async {
    final doc = await _transactionsRef.add({
      ...receipt.toMap(),
      'storeNameLower': receipt.storeName.toLowerCase(),
    });
    return doc.id;
  }

  Future<void> updateTransaction(ReceiptModel receipt) async {
    await _transactionsRef.doc(receipt.id).update({
      ...receipt.toMap(),
      'storeNameLower': receipt.storeName.toLowerCase(),
    });
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsRef.doc(id).delete();
  }

  /// =====================================================
  /// TRANSACTION STREAM (FILTER + PREFIX SEARCH)
  /// =====================================================

  Stream<List<ReceiptModel>> getTransactions({
    DateTime? start,
    DateTime? end,
    String? searchQuery,
  }) {
    Query<Map<String, dynamic>> query =
        _transactionsRef.orderBy('date', descending: true);

    /// DATE FILTER
    if (start != null && end != null) {
      query = query
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date',
              isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    /// PREFIX SEARCH (CASE INSENSITIVE)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lower = searchQuery.toLowerCase();

      query = _transactionsRef
          .orderBy('storeNameLower')
          .where('storeNameLower',
              isGreaterThanOrEqualTo: lower)
          .where('storeNameLower',
              isLessThanOrEqualTo: '$lower\uf8ff');
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ReceiptModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// =====================================================
  /// ANALYTICS
  /// =====================================================

  Stream<double> getMonthlyTotal() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    return getTransactions(start: start, end: end)
        .map((list) =>
            list.fold(0, (sum, e) => sum + e.totalAmount));
  }

  Stream<double> getWeeklyTotal() {
    final now = DateTime.now();
    final start =
        now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));

    return getTransactions(start: start, end: end)
        .map((list) =>
            list.fold(0, (sum, e) => sum + e.totalAmount));
  }
}