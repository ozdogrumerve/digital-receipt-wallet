import 'package:flutter/material.dart';

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Text(
          "Receipts Screen",
          style: theme.textTheme.headlineMedium,
        ),
      ),
    );
  }
}