import 'dart:async';
import 'package:digital_receipt_wallet/screens/homepage.dart';
import 'package:digital_receipt_wallet/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:digital_receipt_wallet/l10n/app_localizations.dart';

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
    // Önce güncelleme kontrolü yap
    await _checkForUpdate();

    if (!mounted) return;

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

  Future<void> _checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // Kullanıcı güncellemeyi tamamlamadan devam edemez.
        // Bu satır, güncelleme tamamlanana (ya da kullanıcı geri gidene) kadar bekler.
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      // Play Store üzerinden yüklenmemiş build'lerde (örn. flutter run ile test)
      // ya da bağlantı sorunlarında hata fırlatır, bu durumda sessizce devam et.
      debugPrint('Güncelleme kontrolü başarısız: $e');
    }
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