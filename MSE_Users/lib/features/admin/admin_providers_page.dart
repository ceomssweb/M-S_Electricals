import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/config/firestore_config.dart';
import '../../core/models/models.dart';

class AdminProvidersPage extends StatefulWidget {
  const AdminProvidersPage({super.key});

  @override
  State<AdminProvidersPage> createState() => _AdminProvidersPageState();
}

class _AdminProvidersPageState extends State<AdminProvidersPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedStatusFilter = 'All';

  static const _filters = ['All', 'pending', 'verified', 'rejected'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showDocumentVerificationModal(
      BuildContext context, ServiceProviderProfile p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF0F2C59).withValues(alpha: 0.1),
                    child: const Icon(Icons.engineering,
                        color: Color(0xFF0F2C59), size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.displayName,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B)),
                        ),
                        Text(
                          '${p.email} • ${p.phoneNumber}',
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

              // Experience & Skills
              Row(
                children: [
                  const Icon(Icons.work_history_outlined,
                      size: 18, color: Color(0xFF0F2C59)),
                  const SizedBox(width: 6),
                  Text('Experience: ${p.experienceYears} Years',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Technical Skills:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: p.skills
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          backgroundColor:
                              const Color(0xFF0F2C59).withValues(alpha: 0.08),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              // Documents Section
              const Text('Identity & Verification Document Bytes',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2C59))),
              const SizedBox(height: 12),

              // PAN Card Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined,
                            size: 20, color: Color(0xFF0F2C59)),
                        const SizedBox(width: 8),
                        Text('PAN Card No: ${p.panNumber}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _Base64DocumentImage(
                      imageData: p.panPhotoUrl,
                      title: 'PAN Card - ${p.panNumber}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Aadhar Card Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fingerprint_outlined,
                            size: 20, color: Color(0xFF0F2C59)),
                        const SizedBox(width: 8),
                        Text('Aadhar Card No: ${p.aadharNumber}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _Base64DocumentImage(
                      imageData: p.aadharPhotoUrl,
                      title: 'Aadhar Card - ${p.aadharNumber}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Reject Account'),
                      onPressed: () async {
                        await FirestoreConfig.db
                            .collection('providers')
                            .doc(p.uid)
                            .update({'verificationStatus': 'rejected'});
                        await FirestoreConfig.db
                            .collection('users')
                            .doc(p.uid)
                            .update({'verificationStatus': 'rejected'});
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Provider account rejected.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2C59),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.verified),
                      label: const Text('Verify & Confirm'),
                      onPressed: () async {
                        await FirestoreConfig.db
                            .collection('providers')
                            .doc(p.uid)
                            .update({'verificationStatus': 'verified'});
                        await FirestoreConfig.db
                            .collection('users')
                            .doc(p.uid)
                            .update({'verificationStatus': 'verified'});
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Provider verified & confirmed successfully!'),
                              backgroundColor: Color(0xFF0F2C59),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
          errorBuilder: (_, __, ___) => const Text('Provider Management'),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final filter = _filters[i];
                final isSelected = _selectedStatusFilter == filter;
                final label = filter == 'All'
                    ? 'All'
                    : (filter == 'pending'
                        ? 'Pending Verification'
                        : filter == 'verified'
                            ? 'Verified'
                            : 'Rejected');

                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0F2C59),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedStatusFilter = filter;
                    });
                  },
                );
              },
            ),
          ),

          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        hintText: 'Search provider name, email or skills...',
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

          // Provider Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreConfig.db.collection('providers').snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                      child: Text('Failed to load providers list.'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var providers = snap.data!.docs
                    .map((d) => ServiceProviderProfile.fromDoc(d))
                    .toList();

                if (_selectedStatusFilter != 'All') {
                  providers = providers
                      .where((p) =>
                          p.verificationStatus == _selectedStatusFilter)
                      .toList();
                }

                final query = _searchCtrl.text.toLowerCase().trim();
                if (query.isNotEmpty) {
                  providers = providers
                      .where((p) =>
                          p.displayName.toLowerCase().contains(query) ||
                          p.email.toLowerCase().contains(query) ||
                          p.skills.any((s) => s.toLowerCase().contains(query)))
                      .toList();
                }

                if (providers.isEmpty) {
                  return const Center(
                    child: Text('No providers registered in this filter.',
                        style: TextStyle(color: Color(0xFF64748B))),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: providers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = providers[i];
                    final isVerified = p.verificationStatus == 'verified';
                    final isPending = p.verificationStatus == 'pending';

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isVerified
                              ? Colors.green.shade50
                              : (isPending
                                  ? Colors.orange.shade50
                                  : Colors.red.shade50),
                          child: Icon(
                            isVerified
                                ? Icons.verified
                                : (isPending
                                    ? Icons.hourglass_top
                                    : Icons.cancel),
                            color: isVerified
                                ? Colors.green.shade800
                                : (isPending
                                    ? Colors.orange.shade800
                                    : Colors.red.shade800),
                          ),
                        ),
                        title: Text(
                          p.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B)),
                        ),
                        subtitle: Text(
                          '${p.email} • Exp: ${p.experienceYears} yrs\nSkills: ${p.skills.join(", ")}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPending
                                ? const Color(0xFFEE5922)
                                : const Color(0xFF0F2C59),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              _showDocumentVerificationModal(context, p),
                          child: Text(isPending ? 'Verify Documents' : 'View'),
                        ),
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
}

class _Base64DocumentImage extends StatelessWidget {
  final String? imageData;
  final String title;

  const _Base64DocumentImage({
    required this.imageData,
    required this.title,
  });

  void _showZoomModal(BuildContext context) {
    if (imageData == null || imageData!.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0F2C59),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 500, maxWidth: 600),
              color: Colors.black,
              child: InteractiveViewer(
                child: Image.network(
                  imageData!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Could not load image bytes.',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageData == null || imageData!.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined,
                color: Colors.grey, size: 36),
            SizedBox(height: 4),
            Text('No document photo attached',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showZoomModal(context),
      child: Stack(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              imageData!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('Invalid image bytes',
                    style: TextStyle(fontSize: 12, color: Colors.red)),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Tap to Inspect',
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
