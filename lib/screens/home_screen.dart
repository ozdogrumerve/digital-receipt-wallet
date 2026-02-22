import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long),
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

              /// SUMMARY CARD (Şimdilik 0 state)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Spent",
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 10),
                      Text(
                        "\$0.00",
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 20),
                      const LinearProgressIndicator(value: 0),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              /// RECENT SECTION TITLE
              Text(
                "Recent Activity",
                style: theme.textTheme.titleLarge,
              ),

              const SizedBox(height: 20),

              /// EMPTY STATE
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt,
                        size: 60,
                        color: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "No receipts yet",
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your scanned receipts will appear here",
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      /// FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // receipt add ekranı gelecek
        },
        child: const Icon(Icons.add),
      ),

      /// BOTTOM NAV (statik label, data yok)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Receipts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Reports",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}