import 'dart:async';
import 'package:digital_receipt_wallet/screens/homepage.dart';
import 'package:digital_receipt_wallet/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long,
                size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 30),
            Text(
              "TRACK SMARTER. SPEND BETTER.",
              style: theme.textTheme.bodyMedium?.copyWith(letterSpacing: 2),
            ),
            const SizedBox(height: 80),
            const SizedBox(
              width: 150,
              child: LinearProgressIndicator(),
            )
          ],
        ),
      ),
    );
  }
}