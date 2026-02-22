import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

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

              /// SUMMARY CARD
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Spent", style: theme.textTheme.bodyMedium),
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

      /// ORTA YUVARLAK BUTON
      floatingActionButton: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      /// CUSTOM ALT BAR
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, "Home", 0),
            _navItem(Icons.receipt_long, "Receipts", 1),

            const SizedBox(width: 50), // FAB boşluğu

            _navItem(Icons.bar_chart, "Reports", 2),
            _navItem(Icons.settings, "Settings", 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final theme = Theme.of(context);
    final bool isSelected = selectedIndex == index;

    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.textTheme.bodyMedium!.color!.withOpacity(0.5);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
