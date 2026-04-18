import 'dart:convert';
import 'dart:io';
import 'package:digital_receipt_wallet/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:digital_receipt_wallet/screens/login_screen.dart';
import 'package:digital_receipt_wallet/l10n/app_localizations.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen>
    with WidgetsBindingObserver {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool _obscurePassword = true;

  File? _selectedImage;
  String? _currentBase64Photo;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
    _loadCurrentPhoto();
  }

  Future<void> _loadCurrentPhoto() async {
    final userModel = await _firestoreService.getUser();
    if (userModel != null &&
        userModel.photo != null &&
        userModel.photo!.isNotEmpty) {
      setState(() => _currentBase64Photo = userModel.photo);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
  
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkEmailVerification();
    }
  }

  // Kullanıcı email değişikliği yaptıktan sonra uygulamaya geri döndüğünde
  // email doğrulamasını kontrol eden fonksiyon
  Future<void> _checkEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context)!;
    if (user == null) return;

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final password = _passwordController.text;
    final newPass = _newPasswordController.text;  

    if (newName.isEmpty) {
      _showError(loc.nameCannotBeEmpty);
      return;
    }

    final emailChanged = newEmail != user.email;
    final passwordChanging = newPass.isNotEmpty;

    // Şifre değiştirilecekse kontrol et
    if (passwordChanging) {
      if (newPass.length < 6) {
        _showError(loc.newPasswordMustBeAtLeast6);
        return;
      }
      if (newPass != _confirmPasswordController.text) {
        _showError(loc.passwordsDontMatch);
        return;
      }
      if (_currentPasswordController.text.isEmpty) {
        _showError(loc.enterCurrentPassword);
        return;
      }
    }

    // Email değişecekse şifre gerekli
    if (emailChanged && password.isEmpty && !passwordChanging) {
      _showError(loc.enterPasswordToChangeEmail);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Avatar güncelle
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final base64Str = base64Encode(bytes);
        await _firestoreService.updateProfilePhoto(base64Str);
      }

      // Display name güncelle
      if (newName != user.displayName) {
        await user.updateDisplayName(newName);
      }

      // Re-auth için credential hazırla
      final needReauth = emailChanged || passwordChanging;
      if (needReauth) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          // Email değişiyorsa _passwordController, yoksa _currentPasswordController
          password: emailChanged ? password : _currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(cred);

        // Şifre güncelle
        if (passwordChanging) {
          await user.updatePassword(newPass);
        }
      }

      // Email güncelle
      if (emailChanged) {
        await user.verifyBeforeUpdateEmail(newEmail);
        await _firestoreService.updateUserEmail(newEmail);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.verificationEmailSent),
            backgroundColor: Colors.orange,
          ),
        );

        await FirebaseAuth.instance.signOut();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );

        return;
      }

      await user.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.profileUpdatedSuccessfully),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'wrong-password':
          msg = loc.incorrectPassword;
          break;
        case 'invalid-credential':
          msg = loc.incorrectPassword;
          break;
        case 'email-already-in-use':
          msg = loc.emailAlreadyInUse;
          break;
        case 'invalid-email':
          msg = loc.invalidEmail;
          break;
        default:
          msg = e.message ?? loc.anErrorOccurred;
      }
      _showError(msg);
    } catch (e) {
      _showError("${loc.anErrorOccurred} $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  Widget _buildAvatar(ThemeData theme) {
    ImageProvider? imageProvider;

    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_currentBase64Photo != null && _currentBase64Photo!.isNotEmpty) {
      imageProvider = MemoryImage(base64Decode(_currentBase64Photo!));
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 54,
            backgroundColor: theme.colorScheme.primary.withAlpha(51),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text[0].toUpperCase()
                        : "U",
                    style: theme.textTheme.headlineMedium,
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final emailChanged = _emailController.text.trim() != (user?.email ?? '');

    return Scaffold(
      appBar: AppBar(title: Text(loc.profileDetails)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AVATAR
            _buildAvatar(theme),

            const SizedBox(height: 32),

            // DISPLAY NAME
            Text(loc.displayName, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: loc.yourNameHint,
                prefixIcon: const Icon(Icons.person_outline),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 20),

            // EMAIL
            Text(loc.emailAddress, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: loc.yourEmailHint,
                prefixIcon: const Icon(Icons.email_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 8),

            // Şifre alanı sadece email değişince görünür
            if (emailChanged) ...[
              const SizedBox(height: 20),
              Text(loc.currentPassword, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: loc.requiredToChangeEmail,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      loc.aVerificationEmailWillBeSent,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // CHANGE PASSWORD SECTION
            Text(loc.changePassword, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              decoration: InputDecoration(
                hintText: loc.currentPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrentPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                hintText: loc.newPasswordHint,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: loc.confirmNewPasswordHint,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            
            const SizedBox(height: 16),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(loc.saveChanges,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}