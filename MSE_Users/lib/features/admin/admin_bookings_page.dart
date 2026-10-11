import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/config/firestore_config.dart';
import '../../core/models/models.dart';

class AdminBookingsPage extends StatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends State<AdminBookingsPage> {
  String _selectedStatusFilter = 'All';

  static const _filters = [
    'All',
    'pending',
    'confirmed',
    'assigned',
    'in_progress',
    'completed',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset(
          'lib/assets/logo/M&S.PNG',
          height: 38,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text('Booking Management'),
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
                    : BookingStatus.fromString(filter).label;

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

          // Booking Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreConfig.db
                  .collection('bookings')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                      child: Text('Failed to load bookings list.'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var bookings =
                    snap.data!.docs.map((d) => Booking.fromDoc(d)).toList();

                if (_selectedStatusFilter != 'All') {
                  bookings = bookings
                      .where((b) => b.status.wireValue == _selectedStatusFilter)
                      .toList();
                }

                if (bookings.isEmpty) {
                  return const Center(
                    child: Text('No bookings in this filter.',
                        style: TextStyle(color: Color(0xFF64748B))),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final b = bookings[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F2C59)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.electrical_services,
                                      color: Color(0xFF0F2C59), size: 24),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.serviceTitle,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B)),
                                      ),
                                      Text(
                                        'ID: #${b.id.substring(0, 8)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                _StatusBadge(status: b.status),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Icon(Icons.event_outlined,
                                    size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  dateFormat.format(b.scheduledAt),
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF475569)),
                                ),
                                const Spacer(),
                                Text(
                                  currencyFormat.format(b.amount),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F2C59)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    b.addressLine,
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF475569)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (b.assignedProviderName != null &&
                                b.assignedProviderName!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.engineering_outlined,
                                      size: 16, color: Color(0xFFEE5922)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Assigned Technician: ${b.assignedProviderName}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEE5922)),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 14),

                            // Actions Bar
                            Row(
                              children: [
                                Text(
                                  b.paid ? '💳 Paid' : '💵 Cash/Pending',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: b.paid
                                        ? Colors.green.shade700
                                        : const Color(0xFFEE5922),
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F2C59),
                                    side: const BorderSide(
                                        color: Color(0xFF0F2C59)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                  ),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Update & Assign'),
                                  onPressed: () =>
                                      _showStatusUpdateDialog(context, b),
                                ),
                              ],
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

  void _showStatusUpdateDialog(BuildContext context, Booking b) {
    BookingStatus currentStatus = b.status;
    String? selectedProviderUid = b.assignedProviderUid;
    String? selectedProviderName = b.assignedProviderName;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Status: #${b.id.substring(0, 8)}'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service: ${b.serviceTitle}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Select New Status:'),
              const SizedBox(height: 6),
              DropdownButtonFormField<BookingStatus>(
                value: currentStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: BookingStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.label),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      currentStatus = val;
                    });
                  }
                },
              ),

              // Skill-Based Provider Assignment Section
              if (currentStatus == BookingStatus.assigned ||
                  currentStatus == BookingStatus.inProgress) ...[
                const SizedBox(height: 16),
                const Text('Assign Certified Service Provider:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF0F2C59))),
                const SizedBox(height: 6),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirestoreConfig.db
                      .collection('providers')
                      .where('verificationStatus', isEqualTo: 'verified')
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const SizedBox(
                          height: 20,
                          child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2)));
                    }

                    // Self-Booking Protection Rule: Exclude the provider who booked the service!
                    var eligibleProviders = snap.data!.docs
                        .map((d) => ServiceProviderProfile.fromDoc(d))
                        .where((p) => p.uid != b.customerUid)
                        .toList();

                    if (eligibleProviders.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No verified eligible providers available (or provider self-booking exclusion active).',
                          style: TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: eligibleProviders
                              .any((p) => p.uid == selectedProviderUid)
                          ? selectedProviderUid
                          : eligibleProviders.first.uid,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: eligibleProviders.map((p) {
                        final skillsJoined = p.skills.join(', ');
                        return DropdownMenuItem(
                          value: p.uid,
                          child: Text(
                            '⚡ ${p.displayName} (${p.experienceYears} yrs) • $skillsJoined',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final selected = eligibleProviders
                              .firstWhere((p) => p.uid == val);
                          setDialogState(() {
                            selectedProviderUid = selected.uid;
                            selectedProviderName = selected.displayName;
                          });
                        }
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F2C59),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final payload = <String, dynamic>{
                'status': currentStatus.wireValue,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              if (currentStatus == BookingStatus.assigned &&
                  selectedProviderUid != null) {
                payload['assignedProviderUid'] = selectedProviderUid;
                payload['assignedProviderName'] = selectedProviderName;
              }

              await FirestoreConfig.db
                  .collection('bookings')
                  .doc(b.id)
                  .update(payload);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Booking status updated to ${currentStatus.label}!'),
                    backgroundColor: const Color(0xFF0F2C59),
                  ),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case BookingStatus.completed:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case BookingStatus.cancelled:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
      case BookingStatus.inProgress:
        bg = const Color(0xFFFFF1EB);
        fg = const Color(0xFFEE5922);
        break;
      case BookingStatus.confirmed:
      case BookingStatus.assigned:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0F2C59);
        break;
      case BookingStatus.pending:
      default:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
