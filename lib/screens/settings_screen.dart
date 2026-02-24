import 'dart:io';
import 'package:digital_receipt_wallet/providers/theme_provider.dart';
import 'package:digital_receipt_wallet/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  bool notificationsEnabled = true;
  File? selectedImage;

  final ImagePicker picker = ImagePicker();

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

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

                  Stack(
                    children: [

                      CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            theme.colorScheme.primary.withAlpha(51), // 0.2 * 255 = 51
                        backgroundImage:
                            selectedImage != null
                                ? FileImage(selectedImage!)
                                : null,
                        child: selectedImage == null
                            ? Text(
                                user?.displayName?.isNotEmpty == true
                                    ? user!.displayName![0].toUpperCase()
                                    : "U",
                                style: theme.textTheme.headlineMedium,
                              )
                            : null,
                      ),

                      /// KALEM İKONU
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                onTap: () {},
              ),
            ),

            const SizedBox(height: 30),

            /// APP PREFERENCES
            Text("APP PREFERENCES",
                style: theme.textTheme.bodyMedium),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text("Push Notifications"),
                subtitle:
                    const Text("Alerts for large transactions"),
                trailing: Switch(
                  value: notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
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

            /// CONNECTIONS
            Text("CONNECTIONS",
                style: theme.textTheme.bodyMedium),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.account_balance_outlined),
                title: const Text("Bank Sync"),
                subtitle: const Text(
                    "Auto-import your transactions"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
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