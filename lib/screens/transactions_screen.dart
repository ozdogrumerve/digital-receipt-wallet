import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    "Food",
    "Clothing",
    "Tech",
    "Transportation",
    "Bills",
    "Rent",
    "Education",
    "Healthcare",
    "Personal Care",
    "Entertainment",
    "Household / Furniture",
    "Stationery",
    "Vacation / Travel",
    "Taxes / Official Payments",
    "Other",
  ];

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
        
      case 'clothing':
        return Icons.checkroom;
        
      case 'tech':
        return Icons.devices; 
        
      case 'transportation':
        return Icons.commute; 
        
      case 'bills':
        return Icons.receipt;
        
      case 'rent':
        return Icons.home;
        
      case 'education':
        return Icons.school;
        
      case 'healthcare':
        return Icons.health_and_safety;
        
      case 'personal care':
        return Icons.spa;
        
      case 'entertainment':
        return Icons.sports_esports; 
       
      case 'household / furniture':
        return Icons.chair;
        
      case 'stationery':
        return Icons.edit; 
        
      case 'vacation / travel':
        return Icons.flight_takeoff; 
        
      case 'taxes / official payments':
        return Icons.account_balance; 
        
      case 'other':
        return Icons.shopping_bag;

      default:
        return Icons.receipt_long;
    }
  }

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
    if (source == "manual") {
      return const Icon(Icons.edit, size: 14, color: Colors.white);
    }
    if (source == "scan") {
      return const Icon(Icons.camera_alt, size: 14, color: Colors.white);
    }
    if (source == "pdf") {
      return const Icon(Icons.picture_as_pdf, size: 14, color: Colors.white);
    }
    return const SizedBox.shrink();
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
          if (startDate != null || endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(
                      startDate != null && endDate != null
                          ? "${DateFormat('d MMM').format(startDate!)} - ${DateFormat('d MMM').format(endDate!)}"
                          : "Custom Date",
                    ),
                    onDeleted: _clearFilter,
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ReceiptModel>>(
              stream: _service.getTransactions(
                start: startDate,
                end: endDate,
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

  Widget _buildTransactionCard(ReceiptModel tx) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // ─── Soldaki ikon kısmı ───
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(30), // 30 is 12% alpha of 255
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getCategoryIcon(tx.category),
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              if (tx.source == "scan" || tx.source == "pdf" || tx.source == "manual")
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary, // veya Colors.grey[800]
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2, // beyaz kenar efekti için
                      ),
                    ),
                    child: _sourceIcon(tx.source),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Orta kısım (store + category)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.storeName,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  tx.category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Sağdaki tutar
          Text(
            "-${formatTL(tx.totalAmount)}",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
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