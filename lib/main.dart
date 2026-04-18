import 'package:digital_receipt_wallet/providers/notifications_provider.dart';
import 'package:digital_receipt_wallet/providers/theme_provider.dart';
import 'package:digital_receipt_wallet/screens/splash_screen.dart';
import 'package:digital_receipt_wallet/services/firestore_service.dart';
import 'package:digital_receipt_wallet/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();

  // Kullanıcı giriş yapmışsa recurring işle
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirestoreService().processRecurring();
  }
  
  await dotenv.load(fileName: ".env");
  runApp(const DigitalReceiptWalletApp());
}

class DigitalReceiptWalletApp extends StatelessWidget {
  const DigitalReceiptWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "Digital Receipt Wallet",
            theme: themeProvider.currentTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}