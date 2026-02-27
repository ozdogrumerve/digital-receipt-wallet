import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digital_receipt_wallet/services/firestore_service.dart';
import 'package:digital_receipt_wallet/models/receipt_model.dart';
import 'package:digital_receipt_wallet/models/user_model.dart';

class HomeScreen extends StatelessWidget {
  
  const HomeScreen({super.key});
  
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
              stream: firestoreService.getReceiptsStream(),
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
                              "\$${totalSpent.toStringAsFixed(2)}",
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

                    Text(
                      "Recent Activity",
                      style: theme.textTheme.titleLarge,
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
                                  child: ListTile(
                                    title:
                                        Text(receipt.storeName),
                                    subtitle:
                                        Text(receipt.category),
                                    trailing: Text(
                                      "- \$${receipt.totalAmount.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        color: theme
                                            .colorScheme.primary,
                                      ),
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