import 'dart:async';
import 'package:digital_receipt_wallet/screens/homepage.dart';
import 'package:digital_receipt_wallet/screens/login_screen.dart';
import 'package:digital_receipt_wallet/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:digital_receipt_wallet/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;

    // 2 saniyelik bekleme hala çalışsın
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user != null ? const HomePage() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long,
                size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 30),
            Text(
              loc.splashSlogan,
              textAlign: TextAlign.center,
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