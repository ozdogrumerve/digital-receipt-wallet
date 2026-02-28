import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digital_receipt_wallet/services/firestore_service.dart';
import 'package:digital_receipt_wallet/models/receipt_model.dart';
import 'package:digital_receipt_wallet/models/user_model.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & drinks':
        return Icons.restaurant;
        
      case 'clothing':
      case 'apparel':
        return Icons.checkroom;
        
      case 'electronics':
      case 'tech':
        return Icons.devices; // phone_iphone yerine devices daha kapsayıcıdır
        
      case 'transportation':
      case 'transport':
        return Icons.directions_car; // veya Icons.commute
        
      case 'bills':
      case 'utilities':
        return Icons.receipt;
        
      case 'rent':
        return Icons.home;
        
      case 'education':
        return Icons.school;
        
      case 'health':
      case 'healthcare':
        return Icons.health_and_safety;
        
      case 'personal care':
        return Icons.spa;
        
      case 'entertainment':
        return Icons.sports_esports; // oyun/eğlence için (Icons.movie de kullanılabilir)
        
      case 'furniture':
      case 'household':
      case 'household / furniture':
        return Icons.chair;
        
      case 'stationery':
        return Icons.edit; // veya Icons.design_services
        
      case 'vacation':
      case 'travel':
      case 'vacation / travel':
        return Icons.flight_takeoff; // tatil ve uçuş hissiyatı için
        
      case 'taxes':
      case 'official payments':
      case 'taxes / official payments':
        return Icons.account_balance; // devlet ve resmi kurum hissiyatı verir
        
      case 'other':
      case 'shopping': // shopping'i diğer veya ayrı bir case yapabilirsin, şimdilik ayrı tuttum
        return Icons.shopping_bag;

      default:
        return Icons.receipt_long;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Yesterday";
    return DateFormat('MMM d').format(date);
  }
  
  final VoidCallback onSeeHistory;

  const HomeScreen({
    super.key,
    required this.onSeeHistory,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<UserModel?>(
          stream: firestoreService.getUserStream(),
          builder: (context, userSnapshot) {
            return StreamBuilder<List<ReceiptModel>>(
              stream: firestoreService.getTransactions(),
              builder: (context, receiptSnapshot) {

                final receipts = receiptSnapshot.data ?? [];

                double totalSpent = 0;
                for (var r in receipts) {
                  totalSpent += r.totalAmount;
                }

                final monthlyBudget =
                    userSnapshot.data?.monthlyBudget ?? 0;

                double progress = 0;
                if (monthlyBudget > 0) {
                  progress = totalSpent / monthlyBudget;
                  if (progress > 1) progress = 1;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.wallet),
                            const SizedBox(width: 8),
                            Text(
                              "Digital Receipt Wallet",
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            user?.displayName?.isNotEmpty == true
                                ? user!.displayName![0].toUpperCase()
                                : "U",
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 40),

                    /// SUMMARY CARD
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text("Total Spent",
                                style:
                                    theme.textTheme.bodyMedium),
                            const SizedBox(height: 10),
                            Text(
                              "\₺${totalSpent.toStringAsFixed(2)}",
                              style:
                                  theme.textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 20),
                            LinearProgressIndicator(
                              value: progress,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recent Activity",
                          style: theme.textTheme.titleLarge,
                        ),
                        InkWell(
                          onTap: onSeeHistory,
                          child: Row(
                            children: [
                              Text(
                                "See History",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// RECEIPTS AREA
                    Expanded(
                      child: receipts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt,
                                    size: 60,
                                    color: theme
                                        .colorScheme.primary
                                        .withAlpha(40),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "No receipts yet",
                                    style:
                                        theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Your scanned receipts will appear here",
                                    style:
                                        theme.textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: receipts.length > 5
                                  ? 5
                                  : receipts.length,
                              itemBuilder: (context, index) {
                                final receipt = receipts[index];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [

                                        /// CATEGORY ICON
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _getCategoryIcon(receipt.category),
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),

                                        const SizedBox(width: 16),

                                        /// STORE + DATE
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                receipt.storeName,
                                                style: theme.textTheme.titleMedium,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDate(receipt.date),
                                                style: theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),

                                        /// AMOUNT + CATEGORY
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "- ₺${receipt.totalAmount.toStringAsFixed(2)}",
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              receipt.category,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}