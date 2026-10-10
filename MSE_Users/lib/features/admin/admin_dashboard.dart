import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/firestore_config.dart';
import '../../core/config/razorpay_config.dart';
import '../../core/models/models.dart';
import '../booking/booking_service.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final bookingSvc = context.watch<BookingService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset(
          'lib/assets/logo/M&S.PNG',
          height: 38,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'M&S Electricals - Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2C59)),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreConfig.db.collection('services').snapshots(),
        builder: (context, servicesSnap) {
          final serviceCount = servicesSnap.data?.docs.length ?? 0;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirestoreConfig.db.collection('bookings').snapshots(),
            builder: (context, bookingSnap) {
              final bookings = bookingSnap.data?.docs
                      .map((d) => Booking.fromDoc(d))
                      .toList() ??
                  [];

              double totalRevenue = 0;
              int pendingCount = 0;
              int inProgressCount = 0;

              for (final b in bookings) {
                if (b.status == BookingStatus.completed) {
                  totalRevenue += b.amount;
                } else if (b.status == BookingStatus.pending) {
                  pendingCount++;
                } else if (b.status == BookingStatus.inProgress) {
                  inProgressCount++;
                }
              }

              final netProfit = totalRevenue * 0.30;

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirestoreConfig.db.collection('users').snapshots(),
                builder: (context, userSnap) {
                  final totalUsers = userSnap.data?.docs.length ?? 0;

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Database Seed Banner if 0 Services
                      if (serviceCount == 0) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFEE5922), size: 32),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Database Empty (0 Services)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF1E293B)),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Populate Firestore database with default electrical services so customer & admin apps display live data.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F2C59),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.cloud_upload, size: 18),
                                label: const Text('Seed Database'),
                                onPressed: () async {
                                  await bookingSvc.seedDefaultServices();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Initial electrical services successfully seeded into Firestore!'),
                                        backgroundColor: Color(0xFF0F2C59),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Razorpay Dynamic Gateway Config Card
                      _buildRazorpayConfigCard(context),

                      const Text(
                        'Executive Summary',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 12),

                      // Responsive Financial & Operations Metrics Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;

                          return Flex(
                            direction: isWide ? Axis.horizontal : Axis.vertical,
                            children: [
                              // Financial Card
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: Container(
                                  margin: EdgeInsets.only(
                                      right: isWide ? 10 : 0,
                                      bottom: isWide ? 0 : 12),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(
                                              Icons
                                                  .account_balance_wallet_outlined,
                                              size: 20,
                                              color: Color(0xFF0F2C59)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Financial Performance',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F2C59)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _BatchMetricItem(
                                              label: 'Gross Revenue',
                                              value: currencyFormat
                                                  .format(totalRevenue),
                                              color: const Color(0xFF0F2C59),
                                            ),
                                          ),
                                          Container(
                                              width: 1,
                                              height: 36,
                                              color: const Color(0xFFE2E8F0)),
                                          Expanded(
                                            child: _BatchMetricItem(
                                              label: 'Est. Net Profit (30%)',
                                              value: currencyFormat
                                                  .format(netProfit),
                                              color: const Color(0xFFEE5922),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Operations Card
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(
                                              Icons
                                                  .precision_manufacturing_outlined,
                                              size: 20,
                                              color: Color(0xFFEE5922)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Operations & Database',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFEE5922)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _BatchMetricItem(
                                              label: 'Database Services',
                                              value: '$serviceCount Active',
                                              color: const Color(0xFF0F2C59),
                                            ),
                                          ),
                                          Container(
                                              width: 1,
                                              height: 36,
                                              color: const Color(0xFFE2E8F0)),
                                          Expanded(
                                            child: _BatchMetricItem(
                                              label: 'Total Bookings',
                                              value: bookings.length.toString(),
                                              color: const Color(0xFFEE5922),
                                            ),
                                          ),
                                          Container(
                                              width: 1,
                                              height: 36,
                                              color: const Color(0xFFE2E8F0)),
                                          Expanded(
                                            child: _BatchMetricItem(
                                              label: 'Active Users',
                                              value: totalUsers.toString(),
                                              color: const Color(0xFF0F2C59),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Real-Time Dispatch Activity',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 12),

                      // Activity Summary Banners
                      Row(
                        children: [
                          Expanded(
                            child: _ActivityBannerTile(
                              label: 'Pending Dispatches',
                              count: '$pendingCount New',
                              color: const Color(0xFFEE5922),
                              icon: Icons.hourglass_top,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActivityBannerTile(
                              label: 'Jobs In Progress',
                              count: '$inProgressCount Active',
                              color: const Color(0xFF0F2C59),
                              icon: Icons.build_circle_outlined,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Recent Booking Activity',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 12),

                      if (bookings.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text('No bookings recorded in Firestore yet.',
                                  style: TextStyle(color: Color(0xFF64748B))),
                            ),
                          ),
                        )
                      else
                        ...bookings.take(5).map((b) => Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Color(0xFFF1F5F9),
                                  child: Icon(Icons.electrical_services,
                                      size: 18, color: Color(0xFF0F2C59)),
                                ),
                                title: Text(
                                  b.serviceTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${b.addressLine} • ${b.status.label}',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  currencyFormat.format(b.amount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF0F2C59)),
                                ),
                              ),
                            )),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRazorpayConfigCard(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreConfig.db
          .collection('system_config')
          .doc('razorpay')
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final keyId = (data['keyId'] ?? RazorpayConfig.keyId) as String;
        final merchantName =
            (data['merchantName'] ?? RazorpayConfig.merchantName) as String;
        final isLive = keyId.startsWith('rzp_live_');

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.payment, color: Color(0xFF0F2C59), size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Razorpay Payment Gateway Config',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLive ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isLive ? Colors.green.shade200 : Colors.orange.shade200),
                    ),
                    child: Text(
                      isLive ? 'LIVE MODE' : 'TEST MODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isLive ? Colors.green.shade800 : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Merchant Name: $merchantName',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          'Key ID: ${keyId.length > 14 ? "${keyId.substring(0, 12)}..." : keyId}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F2C59),
                      side: const BorderSide(color: Color(0xFF0F2C59)),
                    ),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Update Keys'),
                    onPressed: () =>
                        _showRazorpayConfigModal(context, keyId, merchantName),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRazorpayConfigModal(
      BuildContext context, String currentKey, String currentMerchant) {
    final keyCtrl = TextEditingController(text: currentKey);
    final merchantCtrl = TextEditingController(text: currentMerchant);

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Razorpay Keys & Config',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                labelText: 'Razorpay Key ID (rzp_test_... or rzp_live_...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: merchantCtrl,
              decoration: const InputDecoration(
                labelText: 'Merchant Name',
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
                  final key = keyCtrl.text.trim();
                  final merchant = merchantCtrl.text.trim();

                  if (key.isEmpty) return;

                  await RazorpayConfig.updateConfig(
                    keyId: key,
                    merchantName: merchant.isNotEmpty ? merchant : 'M&S Electricals',
                    themeColorHex: '#0F2C59',
                  );

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Razorpay configuration updated dynamically!'),
                        backgroundColor: Color(0xFF0F2C59),
                      ),
                    );
                  }
                },
                child: const Text('Save Configuration'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchMetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BatchMetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _ActivityBannerTile extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  final IconData icon;

  const _ActivityBannerTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
