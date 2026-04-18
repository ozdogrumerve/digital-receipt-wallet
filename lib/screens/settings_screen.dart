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
          ListTile(
            leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
            title: const Text('English'),
            trailing: localeProvider.locale.languageCode == 'en'
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            onTap: () {
              localeProvider.setLocale(const Locale('en'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Text('🇹🇷', style: TextStyle(fontSize: 24)),
            title: const Text('Türkçe'),
            trailing: localeProvider.locale.languageCode == 'tr'
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            onTap: () {
              localeProvider.setLocale(const Locale('tr'));
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      avatarImage = MemoryImage(base64Decode(_currentBase64Photo!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
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
            Text("PERSONAL ACCOUNT",
                style: theme.textTheme.bodyMedium),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text("Profile Details"),
                subtitle:
                    const Text("Change name, email, and avatar"),
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
            Text("APP PREFERENCES",
                style: theme.textTheme.bodyMedium),

            const SizedBox(height: 12),

            /// NOTIFICATION SWITCH
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text("Push Notifications"),
                subtitle:
                    const Text("Alerts for large transactions"),
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
                              const SnackBar(
                                content: Text("Bildirimlere izin vermelisiniz."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        print("Permission error: $e");
                      }
                    } 
                    else {
                      // ---------- TOGGLE KAPATILIYOR ----------
                      notificationProvider.setNotification(false);

                      // Basit ve temiz uyarı
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Bildirimler kapatıldı. "
                            "Tamamen kapatmak isterseniz cihaz ayarlarından kapatabilirsiniz."),
                            action: SnackBarAction(
                              label: "Ayarlara Git",
                              textColor: Colors.white,
                              onPressed: () async {
                                await openAppSettings();
                              },
                            ),
                            duration: const Duration(seconds: 4),
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
                title: const Text("Visual Theme"),
                subtitle:
                    const Text("Switch between light and dark"),
                trailing: Switch(
                  value: themeProvider.isDark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            // YENİ
            /// LANGUAGE
            Text("LANGUAGE",
                style: theme.textTheme.bodyMedium),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text("Language"),
                subtitle: Text(
                  localeProvider.locale.languageCode == 'tr'
                      ? 'Türkçe'
                      : 'English',
                ),
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
                label: const Text(
                  "Sign Out",
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