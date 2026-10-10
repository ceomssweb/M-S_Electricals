import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/config/firestore_config.dart';
import '../../core/models/models.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset(
          'lib/assets/logo/M&S.PNG',
          height: 38,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text('User Management'),
        ),
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF0F2C59)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search user by name, email, or phone...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                            color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon:
                          const Icon(Icons.clear, size: 20, color: Colors.grey),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ),

          // User Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreConfig.db.collection('users').snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                      child: Text('Failed to load users list.'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = snap.data!.docs
                    .map((d) => UserProfile.fromDoc(d))
                    .toList();

                final query = _searchCtrl.text.toLowerCase().trim();
                if (query.isNotEmpty) {
                  users = users
                      .where((u) =>
                          u.displayName.toLowerCase().contains(query) ||
                          u.email.toLowerCase().contains(query) ||
                          u.phoneNumber.toLowerCase().contains(query))
                      .toList();
                }

                if (users.isEmpty) {
                  return const Center(
                    child: Text('No users found.',
                        style: TextStyle(color: Color(0xFF64748B))),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final u = users[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF0F2C59).withValues(alpha: 0.1),
                          child: const Icon(Icons.person,
                              color: Color(0xFF0F2C59)),
                        ),
                        title: Text(
                          u.displayName.isNotEmpty
                              ? u.displayName
                              : 'Unnamed User',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B)),
                        ),
                        subtitle: Text(
                          '${u.email}\n${u.phoneNumber.isNotEmpty ? u.phoneNumber : "No phone number"}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showUserDetailsModal(context, u),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetailsModal(BuildContext context, UserProfile u) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      const Color(0xFF0F2C59).withValues(alpha: 0.1),
                  child: const Icon(Icons.person,
                      color: Color(0xFF0F2C59), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.displayName.isNotEmpty
                            ? u.displayName
                            : 'Customer Profile',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B)),
                      ),
                      Text(
                        'UID: ${u.uid.substring(0, 8)}...',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 24),
            _DetailRow(icon: Icons.email_outlined, label: 'Email', value: u.email),
            const SizedBox(height: 10),
            _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: u.phoneNumber.isNotEmpty ? u.phoneNumber : 'Not set'),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.notifications_active_outlined,
              label: 'Push Status',
              value: u.pushEnabled ? 'Enabled' : 'Disabled',
            ),
            if (u.createdAt != null) ...[
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Registered On',
                value: dateFormat.format(u.createdAt!),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2C59),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0F2C59)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF475569)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
