import 'package:flutter/material.dart';
import 'package:digital_receipt_wallet/screens/home_screen.dart';
import 'package:digital_receipt_wallet/screens/receipts_screen.dart';
import 'package:digital_receipt_wallet/screens/reports_screen.dart';
import 'package:digital_receipt_wallet/screens/settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomeScreen(),
    ReceiptsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      floatingActionButton: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withAlpha(102), // 0.4 * 255 = 102
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

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
            _navItem(Icons.receipt_long, "Transaction", 1),
            const SizedBox(width: 50),
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
    final inactiveColor =
        theme.textTheme.bodyMedium!.color!.withAlpha(128); // 0.5 * 255 = 128

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
            Icon(icon,
                color: isSelected ? activeColor : inactiveColor),
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