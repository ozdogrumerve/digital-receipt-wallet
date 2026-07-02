import 'package:digital_receipt_wallet/providers/currency_provider.dart';
import 'package:digital_receipt_wallet/providers/locale_provider.dart';
import 'package:digital_receipt_wallet/providers/notifications_provider.dart';
import 'package:digital_receipt_wallet/providers/theme_provider.dart';
import 'package:digital_receipt_wallet/screens/splash_screen.dart';
import 'package:digital_receipt_wallet/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:digital_receipt_wallet/l10n/app_localizations.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();

  await dotenv.load(fileName: ".env");
  runApp(const DigitalReceiptWalletApp());
}

class DigitalReceiptWalletApp extends StatefulWidget {
  const DigitalReceiptWalletApp({super.key});

  @override
  State<DigitalReceiptWalletApp> createState() => _DigitalReceiptWalletAppState();
}

class _DigitalReceiptWalletAppState extends State<DigitalReceiptWalletApp> {

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ],

      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            // ya da Provider kullanıyorsan:
            locale: Provider.of<LocaleProvider>(context).locale,

            //  LOCALIZATION
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            supportedLocales: const [
              Locale('en'),
              Locale('tr'),
              Locale('es'),
              Locale('de'),
              Locale('pt'),
              Locale('fr'),
            ],

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