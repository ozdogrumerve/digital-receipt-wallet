import 'package:digital_receipt_wallet/screens/homepage.dart';
import 'package:digital_receipt_wallet/screens/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:digital_receipt_wallet/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;

  String _authErrorMessage(String code, AppLocalizations loc) {
    switch (code) {
      // Email hataları
      case 'invalid-email':
        return loc.errorInvalidEmail;
      case 'email-already-in-use':
        return loc.errorEmailInUse;
      case 'user-not-found':
        return loc.errorUserNotFound;
      case 'user-disabled':
        return loc.errorUserDisabled;

      // Şifre hataları
      case 'invalid-credential':
        return loc.errorWrongPassword;
      case 'weak-password':
        return loc.errorWeakPassword;
      case 'too-many-requests':
        return loc.errorTooManyRequests;

      // Ağ hatası
      case 'network-request-failed':
        return loc.errorNetworkFailed;

      default:
        return loc.errorUnknown;
    }
  }

  Future<void> login() async {
    final loc = AppLocalizations.of(context)!;

    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(loc.errorFillAllFields)),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      final msg = _authErrorMessage(e.code, loc);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }

      setState(() => loading = false);
  }
  
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(loc.welcomeBack,
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 12),
                Text(loc.signInToManageYourReceipts,
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 40),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: loc.email,
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword, 
                  decoration: InputDecoration(
                    labelText: loc.password,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword 
                        ? Icons.visibility : 
                        Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(loc.signIn),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const SignUpScreen()));
                  },
                  child:
                      Text(loc.dontHaveAnAccount),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}