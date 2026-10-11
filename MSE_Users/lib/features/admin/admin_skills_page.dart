import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/config/firestore_config.dart';

class AdminSkillsPage extends StatefulWidget {
  const AdminSkillsPage({super.key});

  @override
  State<AdminSkillsPage> createState() => _AdminSkillsPageState();
}

class _AdminSkillsPageState extends State<AdminSkillsPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showSkillModal(BuildContext context,
      {DocumentSnapshot<Map<String, dynamic>>? existing}) {
    final data = existing?.data() ?? {};
    final nameCtrl = TextEditingController(text: (data['name'] ?? '') as String);
    final emojiCtrl =
        TextEditingController(text: (data['iconEmoji'] ?? '⚡') as String);
    final descCtrl =
        TextEditingController(text: (data['description'] ?? '') as String);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    existing == null ? 'Add New Skill' : 'Edit Skill',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Skill Name (e.g., Wiring, AC, Lighting)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emojiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Emoji Icon',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Skill Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2C59),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final emoji = emojiCtrl.text.trim().isNotEmpty
                        ? emojiCtrl.text.trim()
                        : '⚡';
                    final desc = descCtrl.text.trim();

                    if (name.isEmpty) return;

                    final col = FirestoreConfig.db.collection('skills');

                    final payload = {
                      'name': name,
                      'iconEmoji': emoji,
                      'description': desc,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (existing == null) {
                      await col.add({
                        ...payload,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      await col.doc(existing.id).update(payload);
                    }

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existing == null
                              ? 'New skill added to catalog!'
                              : 'Skill updated!'),
                          backgroundColor: const Color(0xFF0F2C59),
                        ),
                      );
                    }
                  },
                  child: Text(existing == null ? 'Add Skill' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteSkill(
      BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) {
    final name = doc.data()?['name'] ?? 'Skill';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Skill?'),
        content: Text(
          'Are you sure you want to delete "$name" from the skills catalog?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await doc.reference.delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Skill "$name" deleted.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
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
          errorBuilder: (_, __, ___) => const Text('Skills Management'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F2C59),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Skill',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showSkillModal(context),
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
                        hintText: 'Search skills by name...',
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

          // Skills Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreConfig.db.collection('skills').snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                      child: Text('Failed to load skills list.'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snap.data!.docs;

                final query = _searchCtrl.text.toLowerCase().trim();
                if (query.isNotEmpty) {
                  docs = docs
                      .where((d) =>
                          (d.data()['name'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(query) ||
                          (d.data()['description'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(query))
                      .toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.psychology_outlined,
                            size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text('No skills in database catalog.',
                            style: TextStyle(color: Color(0xFF64748B))),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Default Skills'),
                          onPressed: () async {
                            final defaultSkills = [
                              {'name': 'Wiring', 'iconEmoji': '🔌', 'description': 'House wiring, circuit testing'},
                              {'name': 'Lighting', 'iconEmoji': '💡', 'description': 'LED fixture & chandelier mounting'},
                              {'name': 'AC', 'iconEmoji': '❄️', 'description': 'AC deep clean & refrigerant service'},
                              {'name': 'Fan', 'iconEmoji': '🌀', 'description': 'Fan motor & regulator replace'},
                              {'name': 'Repair', 'iconEmoji': '🔧', 'description': 'Socket & switchboard fixes'},
                              {'name': 'Inspection', 'iconEmoji': '🔍', 'description': 'Full electrical safety diagnostic'},
                              {'name': 'Emergency', 'iconEmoji': '🚨', 'description': '24/7 short circuit response'},
                            ];
                            for (final sk in defaultSkills) {
                              await FirestoreConfig.db.collection('skills').add({
                                ...sk,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final data = d.data();
                    final name = data['name'] ?? 'Skill';
                    final emoji = data['iconEmoji'] ?? '⚡';
                    final desc = data['description'] ?? '';

                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F2C59).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B)),
                        ),
                        subtitle: desc.isNotEmpty
                            ? Text(desc,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B)))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () =>
                                  _showSkillModal(context, existing: d),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                              onPressed: () => _confirmDeleteSkill(context, d),
                            ),
                          ],
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
