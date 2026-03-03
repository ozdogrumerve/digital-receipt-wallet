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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Yesterday";
    return DateFormat('MMM d').format(date);
  }
  
  final VoidCallback onSeeHistory;
  final VoidCallback onSeeSettings;

  const HomeScreen({
    super.key,
    required this.onSeeHistory,
    required this.onSeeSettings,
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
                        GestureDetector(
                          onTap: onSeeSettings,
                          child: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              user?.displayName?.isNotEmpty == true
                                  ? user!.displayName![0].toUpperCase()
                                  : "U",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 40),

                    /// SUMMARY CARD
                    Card(
                      elevation: 2, // biraz gölge güzel durur
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Başlık her zaman aynı
                            Text(
                              "Total Spent",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "₺${totalSpent.toStringAsFixed(2)}", // para birimini senin projene göre ₺ veya $ yap
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ─────────────── Koşullu kısım başlar ───────────────
                            if (monthlyBudget <= 0) ...[
                              // Bütçe yoksa → basit hali (mevcut gibi)
                              Text(
                                "No monthly budget set yet",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: 0, // boş göster
                                backgroundColor: theme.colorScheme.primary.withAlpha(51), // 0.2 opacity = 51 alpha (255 * 0.2)
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ] else ...[
                              // Bütçe varsa → detaylı görünüm (resimdeki gibi)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "LIMIT LEFT",
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "₺${(monthlyBudget - totalSpent).toStringAsFixed(0)}",
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: (monthlyBudget - totalSpent) < 0
                                              ? Colors.red
                                              : theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "${(progress * 100).toStringAsFixed(0)}% USED",
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                backgroundColor: theme.colorScheme.primary.withAlpha(51), // 0.2 opacity = 51 alpha (255 * 0.2)
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  (progress > 1)
                                      ? Colors.red
                                      : (progress > 0.8)
                                          ? Colors.orange
                                          : theme.colorScheme.primary,
                                ),
                                minHeight: 12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ],
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
                              itemCount: receipts.length > 3
                                  ? 3
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
                                            color: theme.colorScheme.primary.withAlpha(25),
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