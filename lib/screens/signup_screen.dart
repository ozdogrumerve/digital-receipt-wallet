import 'package:digital_receipt_wallet/models/user_model.dart';
import 'package:digital_receipt_wallet/screens/login_screen.dart';
import 'package:digital_receipt_wallet/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:digital_receipt_wallet/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  late AnimationController _walletController;
  late Animation<double> _receiptOffset;

  @override
  void initState() {
    super.initState();
    _walletController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _receiptOffset = Tween<double>(begin: -10, end: 25).animate(
      CurvedAnimation(parent: _walletController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _walletController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String _privacyPolicyUrl(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'tr'
        ? 'https://ozdogrumerve.github.io/privacy-policy/privacy-tr.html'
        : 'https://ozdogrumerve.github.io/privacy-policy/privacy-en.html';
  }

  String _termsOfServiceUrl(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'tr'
        ? 'https://ozdogrumerve.github.io/privacy-policy/terms-tr.html'
        : 'https://ozdogrumerve.github.io/privacy-policy/terms-en.html';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenLink)),
        );
      }
    }
  }
  
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

  Future<void> register() async {
    final loc = AppLocalizations.of(context)!;

    // Boş alan kontrolü
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty || 
        confirmPasswordController.text.trim().isEmpty) {
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

    // Şifre eşleşme kontrolü
    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(loc.errorPasswordsDoNotMatch)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user!;
      await user.updateDisplayName(nameController.text.trim());

      ///  Firestore User Document Oluştur
      final userModel = UserModel(
        uid: user.uid,
        name: nameController.text.trim(),
        email: user.email ?? "",
        photo: null,
        monthlyBudget: 0,
        createdAt: DateTime.now(),
      );

      await FirestoreService().createUserIfNotExists(userModel);

      if (!mounted) return;

      Navigator.pop(context);

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
                SizedBox(
                  width: 90,
                  height: 80,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Arka gövde (cüzdanın içi/arkası)
                      Positioned(
                        left: 10,
                        top: 15,
                        child: Container(
                          width: 70,
                          height: 50,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(180),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      // Fiş (arka gövde ile ön kapak arasında hareket eder)
                      AnimatedBuilder(
                        animation: _receiptOffset,
                        builder: (context, child) {
                          return Positioned(
                            left: 28, // width büyüdüğü için ortalamak adına 32'den 28'e çektim
                            top: _receiptOffset.value,
                            child: child!,
                          );
                        },
                        child: ClipPath(
                          clipper: _ReceiptClipper(teeth: 5),
                          child: Container(
                            width: 34, // 26'dan büyüttük
                            height: 50,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(40),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12, left: 4, right: 4, bottom: 12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                  4,
                                  (_) => Container(
                                    height: 2,
                                    color: theme.colorScheme.onSurface.withAlpha(60),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Ön kapak (fişi gerçekten örten opak katman — arkası asla sızmaz)
                      Positioned(
                        left: 8,
                        top: 46,
                        child: Container(
                          width: 74,
                          height: 34,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                width: 18,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onPrimary.withAlpha(80),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(loc.createAccount,
                    style: theme.textTheme.headlineMedium),
                const SizedBox(height: 12),
                Text(loc.signUpToStartManagingYourReceipts,
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 40),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: loc.fullName,
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
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
                        obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: loc.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : register,
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(loc.createAccount),
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(0x99),
                    ),
                    children: [
                      TextSpan(text: "${loc.bySigningUpYouAgreeToOur} "),
                      TextSpan(
                        text: loc.termsOfService,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _openUrl(_termsOfServiceUrl(context)),
                      ),
                      TextSpan(text: " ${loc.and} "),
                      TextSpan(
                        text: loc.privacyPolicy,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _openUrl(_privacyPolicyUrl(context)),
                      ),
                      TextSpan(text: loc.agreementSuffix),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const LoginScreen()));
                  },
                  child:
                      Text(loc.alreadyHaveAnAccount),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptClipper extends CustomClipper<Path> {
  final int teeth;
  _ReceiptClipper({this.teeth = 5});

  @override
  Path getClip(Size size) {
    final path = Path();
    final toothWidth = size.width / teeth;

    // Üst kenar (tırtıklı, soldan sağa)
    path.moveTo(0, 6);
    for (int i = 0; i < teeth; i++) {
      final xMid = i * toothWidth + toothWidth / 2;
      final x1 = (i + 1) * toothWidth;
      path.lineTo(xMid, 0);
      path.lineTo(x1, 6);
    }

    path.lineTo(size.width, size.height - 6);

    // Alt kenar (tırtıklı, sağdan sola)
    for (int i = teeth; i >= 1; i--) {
      final x1 = i * toothWidth;
      final xMid = x1 - toothWidth / 2;
      path.lineTo(x1, size.height - 6);
      path.lineTo(xMid, size.height);
    }

    path.lineTo(0, size.height - 6);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}