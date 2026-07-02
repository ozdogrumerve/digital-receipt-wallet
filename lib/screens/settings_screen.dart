import 'dart:convert';
import 'dart:io';
import 'package:digital_receipt_wallet/providers/notifications_provider.dart';
import 'package:digital_receipt_wallet/providers/theme_provider.dart';
import 'package:digital_receipt_wallet/screens/login_screen.dart';
import 'package:digital_receipt_wallet/screens/profile_details_screen.dart';
import 'package:digital_receipt_wallet/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:digital_receipt_wallet/providers/locale_provider.dart';
import 'package:digital_receipt_wallet/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  File? selectedImage;

  final ImagePicker picker = ImagePicker();

  // Firestore'dan avatar yuklemek icin
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentBase64Photo;

  String _languageName(String code) {
  switch (code) {
    case 'tr':
      return 'Türkçe';
    case 'en':
      return 'English';
    case 'es':
      return 'Español';
    case 'de':
      return 'Deutsch';
    case 'pt':
      return 'Português';
    case 'fr':
      return 'Français';
    default:
      return 'English';
  }
}

  Future<void> pickImage() async {
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkSystemPermission();
    _loadCurrentPhoto();
  }

  Future<void> _checkSystemPermission() async {
    final status = await Permission.notification.status;

    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    notificationProvider.setNotification(status.isGranted);
  }

  Future<void> _loadCurrentPhoto() async {
    final userModel = await _firestoreService.getUser();
    if (userModel != null &&
        userModel.photo != null &&
        userModel.photo!.isNotEmpty) {
      setState(() => _currentBase64Photo = userModel.photo);
    }
  }

  // Language option
  void _openLanguageSheet(LocaleProvider localeProvider) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          _langTile(localeProvider, '🇬🇧', 'English', 'en'),
          _langTile(localeProvider, '🇹🇷', 'Türkçe', 'tr'),
          _langTile(localeProvider, '🇪🇸', 'Español', 'es'),
          _langTile(localeProvider, '🇩🇪', 'Deutsch', 'de'),
          _langTile(localeProvider, '🇵🇹', 'Português', 'pt'),
          _langTile(localeProvider, '🇫🇷', 'Français', 'fr'),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  ListTile _langTile(LocaleProvider localeProvider, String flag, String label, String code) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label),
      trailing: localeProvider.locale.languageCode == code
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: () {
        localeProvider.setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    // Avatar image provider: once secilen local dosyaya bak,
    // yoksa Firestore'daki base64'e bak
    ImageProvider? avatarImage;
    if (selectedImage != null) {
      avatarImage = FileImage(selectedImage!);
    } else if (_currentBase64Photo != null &&
        _currentBase64Photo!.isNotEmpty) {
      if (_currentBase64Photo!.startsWith('http')) {
        // Google hesabından gelen fotoğraf URL'si
        avatarImage = NetworkImage(_currentBase64Photo!);
      } else {
        // Firestore'da base64 olarak saklanan fotoğraf
        try {
          avatarImage = MemoryImage(base64Decode(_currentBase64Photo!));
        } catch (e) {
          avatarImage = null;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// PROFILE SECTION
            Center(
              child: Column(
                children: [

                  // Kalem ikonu kaldirildi — duzenleme Profile Details uzerinden yapiliyor
                  CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        theme.colorScheme.primary.withAlpha(51), // 0.2 * 255 = 51
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? Text(
                            user?.displayName?.isNotEmpty == true
                                ? user!.displayName![0].toUpperCase()
                                : "U",
                            style: theme.textTheme.headlineMedium,
                          )
                        : null,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    user?.displayName ?? "User",
                    style: theme.textTheme.titleLarge,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    user?.email ?? "",
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// PERSONAL ACCOUNT
            Text(loc.personalAccount,
                style: theme.textTheme.bodyMedium),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(loc.profileDetails),
                subtitle:
                    Text(loc.changeNameEmailAndAvatar),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileDetailsScreen(),
                    ),
                  );
                  // Profil Details'ten donunce avatar ve adi guncelle
                  await user?.reload();
                  _loadCurrentPhoto();
                  setState(() {});
                },
              ),
            ),

            const SizedBox(height: 30),

            /// APP PREFERENCES
            Text(loc.appPreferences,
                style: theme.textTheme.bodyMedium),

            const SizedBox(height: 12),

            /// NOTIFICATION SWITCH
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_none),
                title: Text(loc.pushNotifications),
                subtitle:
                    Text(loc.alertsForLargeTransactions),
                trailing: Switch(
                  value: notificationProvider.isEnabled,
                  onChanged: (value) async {

                    if (value) {
                      // ---------- TOGGLE AÇILIYOR ----------
                      try {
                        final messaging = FirebaseMessaging.instance;
                        final settings = await messaging.requestPermission(
                          alert: true,
                          badge: true,
                          sound: true,
                        );

                        final bool granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                                            settings.authorizationStatus == AuthorizationStatus.provisional;

                        if (granted) {
                          notificationProvider.setNotification(true);
                        } else {
                          notificationProvider.setNotification(false);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.notificationsDisabledPermission),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        print("$loc.permissionError: $e");
                      }
                    } 
                    else {
                      // ---------- TOGGLE KAPATILIYOR ----------
                      notificationProvider.setNotification(false);

                      // Basit ve temiz uyarı
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.notificationsTurnedOff),
                            action: SnackBarAction(
                              label: loc.goToSettings,
                              textColor: Colors.grey,
                              onPressed: () async {
                                await openAppSettings();
                              },
                            ),
                            duration: const Duration(seconds: 3),
                            persist: false,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// THEME SWITCH
            Card(
              child: ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(loc.visualTheme),
                subtitle:
                    Text(loc.switchBetweenLightAndDark),
                trailing: Switch(
                  value: themeProvider.isDark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// LANGUAGE
            Text(loc.language,
                style: theme.textTheme.bodyMedium),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(loc.selectAppLanguage),
                subtitle: Text(_languageName(localeProvider.locale.languageCode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openLanguageSheet(localeProvider),
              ),
            ),

            const SizedBox(height: 40),

            /// SIGN OUT
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon:
                    const Icon(Icons.logout, color: Colors.red),
                label: Text(
                  loc.signOut,
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}