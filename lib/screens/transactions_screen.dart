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
  String searchQuery = "";
  String selectedCategory = "All";
  DateTime? startDate;
  DateTime? endDate;

  final List<String> categories = [
    "All",
    "General",
    "Gıda",
    "Giyim",
    "Elektronik",
    "Ulaşım",
    "Fatura",
    "Kira",
    "Eğitim",
    "Sağlık",
    "Kişisel Bakım",
    "Eğlence",
    "Ev Eşyası / Mobilya",
    "Kırtasiye",
    "Tatil / Seyahat",
    "Vergi / Resmi Ödemeler",
    "Diğer",
  ];

  String formatTL(double amount) =>
      "₺${amount.toStringAsFixed(2)}";

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool isYesterday(DateTime date) {
    final yesterday =
        DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  Widget _sourceIcon(String source) {
    if (source == "scan") {
      return const Icon(Icons.insert_drive_file, size: 18);
    }
    if (source == "pdf") {
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
                    hintText: "Search...",
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
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: StreamBuilder<List<ReceiptModel>>(
              stream: _service.getTransactions(
                category: selectedCategory == "All"
                    ? null
                    : selectedCategory,
                searchQuery: searchQuery.isEmpty
                    ? null
                    : searchQuery,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator());
                }

                final transactions = snapshot.data!;

                if (transactions.isEmpty) {
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
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];

                    return Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (index == 0 ||
                            !_isSameDay(
                                tx.date,
                                transactions[index - 1]
                                    .date))
                          Padding(
                            padding:
                                const EdgeInsets.only(
                                    bottom: 8),
                            child: Text(
                              isToday(tx.date)
                                  ? "TODAY"
                                  : isYesterday(tx.date)
                                      ? "YESTERDAY"
                                      : "${tx.date.day}/${tx.date.month}/${tx.date.year}",
                              style: theme
                                  .textTheme.labelMedium,
                            ),
                          ),
                        _buildTransactionCard(tx),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected =
              selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
            },
            child: Container(
              margin:
                  const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius:
                    BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.textTheme.bodyMedium!
                            .color,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(
      ReceiptModel tx) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                theme.colorScheme.primary
                    .withOpacity(0.2),
            child: _sourceIcon(tx.source),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  tx.storeName,
                  style: theme
                      .textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  tx.category,
                  style: theme
                      .textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            "-${formatTL(tx.totalAmount)}",
            style: theme.textTheme.titleMedium!
                .copyWith(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(
      DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}