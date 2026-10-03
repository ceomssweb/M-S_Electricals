import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                  backgroundColor: const Color(0xFFE3F2FD),
                  child: Text(
                    (_nameCtrl.text.isNotEmpty)
                        ? _nameCtrl.text[0].toUpperCase()
                        : '👤',
                    style: const TextStyle(
                        fontSize: 44, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF1976D2),
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
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            enabled: false,
            controller: TextEditingController(text: email),
            decoration: const InputDecoration(
              labelText: 'Email Address (Read-only)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
              helperText: 'Email cannot be changed directly',
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _busy ? null : _saveProfile,
            child: _busy
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
