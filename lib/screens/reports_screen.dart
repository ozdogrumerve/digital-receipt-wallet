import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Text(
          "Reports Screen",
          style: theme.textTheme.headlineMedium,
        ),
      ),
    );
  }
}