import 'package:digital_receipt_wallet/providers/theme_provider.dart';
import 'package:digital_receipt_wallet/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: false,
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
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    child: Text(
                      user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0].toUpperCase()
                          : "U",
                      style: theme.textTheme.headlineMedium,
                    ),
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

            _settingsTile(
              icon: Icons.person_outline,
              title: "Profile Details",
              subtitle: "Change name, email, and avatar",
              onTap: () {},
            ),

            const SizedBox(height: 30),

            /// APP PREFERENCES
            Text("APP PREFERENCES",
                style: theme.textTheme.bodyMedium),

            const SizedBox(height: 12),

            /// PUSH NOTIFICATIONS
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text("Push Notifications"),
                subtitle: const Text("Alerts for large transactions"),
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

            /// VISUAL THEME (ÇALIŞAN)
            Card(
              child: ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text("Visual Theme"),
                subtitle: const Text("Switch between light and dark"),
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

            _settingsTile(
              icon: Icons.account_balance_outlined,
              title: "Bank Sync",
              subtitle: "Auto-import your transactions",
              onTap: () {},
            ),

            const SizedBox(height: 40),

            /// SIGN OUT
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "Sign Out",
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
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

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}