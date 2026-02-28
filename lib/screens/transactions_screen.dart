import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/receipt_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState
    extends State<TransactionsScreen> {
  final FirestoreService _service = FirestoreService();

  bool isSearching = false;
  String searchQuery = '';

  DateTime? startDate;
  DateTime? endDate;

  String formatTL(double amount) =>
      "₺${amount.toStringAsFixed(2)}";

  Widget _sourceIcon(String source) {
    if (source == 'scan') {
      return const Icon(Icons.insert_drive_file, size: 18);
    }
    if (source == 'pdf') {
      return const Icon(Icons.attach_file, size: 18);
    }
    return const SizedBox();
  }

  void _applyWeeklyFilter() {
    final now = DateTime.now();
    final start =
        now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));

    setState(() {
      startDate = start;
      endDate = end;
    });
  }

  void _applyMonthlyFilter() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    setState(() {
      startDate = start;
      endDate = end;
    });
  }

  void _clearFilter() {
    setState(() {
      startDate = null;
      endDate = null;
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("This Week"),
              onTap: () {
                _applyWeeklyFilter();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("This Month"),
              onTap: () {
                _applyMonthlyFilter();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Clear Filter"),
              onTap: () {
                _clearFilter();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isSearching
              ? TextField(
                  autofocus: true,
                  onChanged: (val) =>
                      setState(() => searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "Search store...",
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          isSearching = false;
                          searchQuery = '';
                        });
                      },
                    ),
                  ),
                )
              : const Text("Transactions"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () =>
                setState(() => isSearching = true),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: StreamBuilder<List<ReceiptModel>>(
        stream: _service.getTransactions(
          start: startDate,
          end: endDate,
          searchQuery:
              searchQuery.isEmpty ? null : searchQuery,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final list = snapshot.data!;

          if (list.isEmpty) {
            return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_sharp,
                      size: 60,
                      color: theme
                          .colorScheme.primary
                          .withAlpha(40),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "No transactions yet",
                      style:
                          theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your transactions will appear here",
                      style:
                          theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ]
                ));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final tx = list[i];

              return Card(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: _sourceIcon(tx.source),
                  title: Text(tx.storeName),
                  subtitle: Text(tx.category),
                  trailing: Text(
                    formatTL(tx.totalAmount),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}