import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_receipt_wallet/models/product_model.dart';
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

  Future<void> addTransaction({
    required ReceiptModel receipt,
    required List<ProductModel> products,
  }) async {
    final doc = await _transactionsRef.add(
      receipt.toMap(),
    );

    for (var product in products) {
      await doc
          .collection('products')
          .add(product.toMap());
    }
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

  Stream<List<ProductModel>> getProducts(String transactionId) {
    return _transactionsRef
        .doc(transactionId)
        .collection('products')
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                ProductModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// =====================================================
  /// TRANSACTION STREAM (FILTER + PREFIX SEARCH)
  /// =====================================================

  Stream<List<ReceiptModel>> getTransactions({
    DateTime? start,
    DateTime? end,
    String? searchQuery,
    String? category,
  }) {
    Query<Map<String, dynamic>> query =
        _transactionsRef;

    /// SEARCH VARSA → farklı query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lower = searchQuery.toLowerCase();

      query = query
          .orderBy('storeNameLower')
          .where('storeNameLower',
              isGreaterThanOrEqualTo: lower)
          .where('storeNameLower',
              isLessThanOrEqualTo: '$lower\uf8ff');
    } else {
      query = query.orderBy('date', descending: true);
    }

    /// CATEGORY FILTER
    if (category != null && category.isNotEmpty) {
      query =
          query.where('category', isEqualTo: category);
    }

    /// DATE FILTER
    if (start != null && end != null) {
      query = query
          .where('date',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(start))
          .where('date',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(end));
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