import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:digital_receipt_wallet/screens/home_screen.dart';
import 'package:digital_receipt_wallet/screens/transactions_screen.dart';
import 'package:digital_receipt_wallet/screens/reports_screen.dart';
import 'package:digital_receipt_wallet/screens/settings_screen.dart';
import 'package:digital_receipt_wallet/screens/add_expense_screen.dart';
import 'package:digital_receipt_wallet/screens/scan_receipt_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int selectedIndex = 0;
  
  late AnimationController _controller;
  late Animation<double> _animation;

  bool isOpen = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  void toggleFab() {
    if (isOpen) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      isOpen = !isOpen;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> pages = [
      HomeScreen(
          onSeeHistory: () {
            setState(() {
              selectedIndex = 1;
            });
          },
        ),
      const TransactionsScreen(),
      ReportsScreen(),
      const SettingsScreen(),
    ];

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
              index: selectedIndex,
              children: pages,
            ),

            bottomNavigationBar: Container(
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(25)),
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
        ),

        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return IgnorePointer(
              ignoring: _animation.value == 0,
              child: Opacity(
                opacity: _animation.value,
                child: GestureDetector(
                  onTap: toggleFab,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 5 * _animation.value,
                      sigmaY: 5 * _animation.value,
                    ),
                    child: Container(
                      color: Colors.black
                          .withAlpha((0.3 * _animation.value * 255).round()),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
                
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
                children: [
                _buildOptionButton(
                  icon: Icons.document_scanner,
                  label: "Scan Receipt",
                  index: 1,
                ),
                const SizedBox(height: 12),
                _buildOptionButton(
                  icon: Icons.upload_file,
                  label: "Upload Receipt",
                  index: 2,
                ),
                const SizedBox(height: 12),
                _buildOptionButton(
                  icon: Icons.edit,
                  label: "Add Expense",
                  index: 3,
                ),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 30,
          left: MediaQuery.of(context).size.width / 2 - 30,
          child: FloatingActionButton(
            onPressed: toggleFab,
            backgroundColor: theme.colorScheme.primary,
            shape: const CircleBorder(),
            child: AnimatedRotation(
              turns: isOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.add, size: 30),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(_animation),
        child: ScaleTransition(
          scale: _animation,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              minimumSize: const Size(220, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 6,
            ),
            onPressed: () async {
              toggleFab();

              await Future.delayed(const Duration(milliseconds: 200));

              if (!mounted) return;

              switch (index) {
                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScanReceiptScreen(
                        detectedProducts: [],
                        storeName: '',
                        category: '',
                      ),
                    ),
                  );
                  break;

                // case 2:
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (_) => const ScanReceiptScreen(
                //         detectedProducts: [],
                //         storeName: '',
                //         category: '',
                //       ),
                //     ),
                //   );
                //   break;

                case 3:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddExpenseScreen(),
                    ),
                  );
                  break;
              }
            },
            icon: Icon(icon),
            label: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final theme = Theme.of(context);
    final bool isSelected = selectedIndex == index;

    final activeColor = theme.colorScheme.primary;
    final inactiveColor =
        theme.textTheme.bodyMedium!.color!.withAlpha(128);

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