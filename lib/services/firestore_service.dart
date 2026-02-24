import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/receipt_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// ===============================
  /// USER
  /// ===============================

  Future<void> createUserIfNotExists(UserModel user, Exception exception) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    }
  }

  Future<UserModel?> getUser() async {
    final doc = await _firestore.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateProfilePhoto(String base64) async {
    await _firestore.collection('users').doc(_uid).update({
      'photo': base64,
    });
  }

  Future<void> updateMonthlyBudget(double budget) async {
    await _firestore.collection('users').doc(_uid).update({
      'monthlyBudget': budget,
    });
  }

  ///  USER STREAM
  Stream<UserModel?> getUserStream() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.id, doc.data()!);
    });
  }

  /// ===============================
  /// RECEIPTS
  /// ===============================

  Stream<List<ReceiptModel>> getReceiptsStream() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('receipts')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReceiptModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<String> addReceipt(ReceiptModel receipt) async {
    final doc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('receipts')
        .add(receipt.toMap());

    return doc.id;
  }

  Future<void> deleteReceipt(String receiptId) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('receipts')
        .doc(receiptId)
        .delete();
  }

  Future<void> updateReceipt(ReceiptModel receipt) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('receipts')
        .doc(receipt.id)
        .update(receipt.toMap());
  }

  /// ===============================
  /// PRODUCTS (SUBCOLLECTION)
  /// ===============================

  Stream<List<ProductModel>> getProductsStream(String receiptId) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('receipts')
        .doc(receiptId)
        .collection('products')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addProduct(String receiptId, ProductModel product) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('receipts')
        .doc(receiptId)
        .collection('products')
        .add(product.toMap());
  }

  Future<void> deleteProduct(String receiptId, String productId) async {
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('receipts')
        .doc(receiptId)
        .collection('products')
        .doc(productId)
        .delete();
  }
}