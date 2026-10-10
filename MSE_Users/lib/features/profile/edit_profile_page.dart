import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../auth/auth_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    _nameCtrl.text = auth.user?.displayName ?? auth.profile?.displayName ?? '';
    _phoneCtrl.text = auth.profile?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter display name')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthState>();
      await auth.updateProfileInfo(
        displayName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final email = auth.user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    (_nameCtrl.text.isNotEmpty)
                        ? _nameCtrl.text[0].toUpperCase()
                        : '👤',
                    style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt,
                          size: 18, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Avatar picture upload ready.')),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameCtrl,
            decoration: AppStyles.inputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: AppStyles.inputDecoration(
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            enabled: false,
            controller: TextEditingController(text: email),
            decoration: AppStyles.inputDecoration(
              labelText: 'Email Address (Read-only)',
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: AppStyles.filledButton,
              onPressed: _busy ? null : _saveProfile,
              child: _busy
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
