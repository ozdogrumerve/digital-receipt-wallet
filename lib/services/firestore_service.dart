import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_receipt_wallet/models/product_model.dart';
import 'package:digital_receipt_wallet/models/recurring_transaction_model.dart';
import 'package:digital_receipt_wallet/services/notification_service.dart';
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
    await _firestore.collection('users').doc(_uid).set(
      {'photo': base64},
      SetOptions(merge: true),
    );
  }

  Future<void> updateUserEmail(String newEmail) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set(
      {'email': newEmail},
      SetOptions(merge: true),
    );
  }

  Future<void> removeMonthlyBudget() async {
    await _firestore.collection('users').doc(_uid).update({
      'monthlyBudget': 0,
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
  /// RECURRING TRANSACTIONS
  /// =====================================================

  CollectionReference<Map<String, dynamic>> get _recurringRef =>
      _firestore
          .collection('users')
          .doc(_uid)
          .collection('recurring');

  Stream<List<RecurringModel>> getRecurring() {
    return _recurringRef
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => RecurringModel.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> addRecurring(RecurringModel model) async {
    await _recurringRef.add(model.toMap());
  }

  Future<void> updateRecurring(RecurringModel model) async {
    await _recurringRef.doc(model.id).update(model.toMap());
  }

  Future<void> deleteRecurring(String id) async {
    await _recurringRef.doc(id).delete();
  }

  Future<void> toggleRecurringStatus(RecurringModel model) async {
    final newStatus = model.status == RecurringStatus.active
        ? RecurringStatus.paused
        : RecurringStatus.active;

    final Map<String, dynamic> update = {'status': newStatus.name};

    // Resume olunca ve nextDueDate geçmişteyse bugüne çek
    if (newStatus == RecurringStatus.active && model.nextDueDate != null) {
      final today = DateTime.now();
      final todayClean = DateTime(today.year, today.month, today.day);
      final due = DateTime(
        model.nextDueDate!.year,
        model.nextDueDate!.month,
        model.nextDueDate!.day,
      );

      if (due.isBefore(todayClean)) {
        update['nextDueDate'] = Timestamp.fromDate(todayClean);
      }
    }

    await _recurringRef.doc(model.id).update(update);
  }

  Future<void> processRecurring({
    bool notify = true,
    String Function(String storeName, String amount, String category)? buildBody,
    String? notificationTitle,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final snapshot = await _recurringRef.get();

    for (final doc in snapshot.docs) {
      final r = RecurringModel.fromMap(doc.id, doc.data());

      if (r.nextDueDate == null) continue;

      final due = DateTime(
        r.nextDueDate!.year,
        r.nextDueDate!.month,
        r.nextDueDate!.day,
      );

      // Paused ise tarihi ilerlet ama işlem ekleme (orijinal davranış korundu)
      if (r.status != RecurringStatus.active) {
        if (!due.isAfter(today)) {
          DateTime nextDue = due;
          while (!nextDue.isAfter(today)) {
            nextDue = r.computeNextDueDate(nextDue);
          }
          await _recurringRef.doc(r.id).update({
            'nextDueDate': Timestamp.fromDate(nextDue),
          });
        }
        continue;
      }

      // due bugün veya geçmişte mi?
      if (due.isAfter(today)) continue;

      DateTime current = due;

      while (!current.isAfter(today)) {
        final currentDay = DateTime(current.year, current.month, current.day);
        final startOfDay = Timestamp.fromDate(currentDay);
        final endOfDay = Timestamp.fromDate(currentDay.add(const Duration(days: 1)));

        bool alreadyProcessed = false;
        try {
          final existing = await _transactionsRef
              .where('source', isEqualTo: 'recurring')
              .where('date', isGreaterThanOrEqualTo: startOfDay)
              .where('date', isLessThan: endOfDay)
              .get();

          alreadyProcessed = existing.docs.any(
            (d) => d.data()['storeNameLower'] == r.storeNameLower,
          );
        } catch (e) {
          alreadyProcessed = false;
        }

        if (!alreadyProcessed) {
          final receipt = ReceiptModel(
            id: '',
            storeName: r.storeName,
            storeNameLower: r.storeNameLower,
            totalAmount: r.amount,
            date: DateTime(currentDay.year, currentDay.month, currentDay.day,
                now.hour, now.minute, now.second),
            category: r.category,
            createdAt: now,
            source: 'recurring',
          );

          await addTransaction(receipt: receipt, products: []);

          if (notify) {
            await NotificationService.showRecurringNotification(
              storeName: r.storeName,
              amount: r.amount,
              category: r.category,
              title: notificationTitle ?? 'Recurring Transaction',
              body: buildBody?.call(
                r.storeName,
                '₺${r.amount.toStringAsFixed(2)}',
                r.category,
              ),
            );
          }
        }

        current = r.computeNextDueDate(current);
      }

      // Döngü bitti, nextDueDate'i güncelle
      await _recurringRef.doc(r.id).update({
        'nextDueDate': Timestamp.fromDate(current),
      });

      // Bildirim — bu recurring için bir kez
      if (notify) {
        await NotificationService.showRecurringNotification(
          storeName: r.storeName,
          amount: r.amount,
          category: r.category,
          title: notificationTitle ?? 'Recurring Transaction',
          body: buildBody?.call(
            r.storeName,
            '₺${r.amount.toStringAsFixed(2)}',
            r.category,
          ),
        );
      }
    }
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