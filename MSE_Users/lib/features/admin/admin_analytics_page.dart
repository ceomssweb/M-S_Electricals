import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/config/firestore_config.dart';
import '../../core/models/models.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset(
          'lib/assets/logo/M&S.PNG',
          height: 38,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text('Finance & Analytics'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreConfig.db.collection('bookings').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Failed to load financial data.'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings =
              snap.data!.docs.map((d) => Booking.fromDoc(d)).toList();

          double grossRevenue = 0;
          double onlinePayments = 0;
          double cashPayments = 0;
          Map<String, double> categoryRevenue = {};

          for (final b in bookings) {
            if (b.status == BookingStatus.completed) {
              grossRevenue += b.amount;
              if (b.paid) {
                onlinePayments += b.amount;
              } else {
                cashPayments += b.amount;
              }

              final cat = b.serviceTitle.split(' ').first;
              categoryRevenue[cat] = (categoryRevenue[cat] ?? 0) + b.amount;
            }
          }

          final technicianPayouts = grossRevenue * 0.70; // 70% payout
          final grossProfit = grossRevenue - technicianPayouts; // 30% margin
          final operatingOverhead = grossRevenue * 0.05; // 5% overhead
          final netProfit = grossProfit - operatingOverhead; // 25% net profit

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Financial Performance Summary',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),

              // Profit & Loss Card
              Card(
                color: const Color(0xFF0F2C59),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NET PROFIT (YTD)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currencyFormat.format(netProfit),
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _FinanceStatItem(
                            label: 'Gross Sales',
                            value: currencyFormat.format(grossRevenue),
                            color: Colors.white,
                          ),
                          _FinanceStatItem(
                            label: 'Tech Payouts (70%)',
                            value: currencyFormat.format(technicianPayouts),
                            color: const Color(0xFFEE5922),
                          ),
                          _FinanceStatItem(
                            label: 'Net Margin',
                            value: grossRevenue > 0
                                ? '${((netProfit / grossRevenue) * 100).toStringAsFixed(1)}%'
                                : '0%',
                            color: Colors.lightGreenAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Payment Method Breakdown',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _PaymentTile(
                      label: 'Razorpay Online',
                      value: currencyFormat.format(onlinePayments),
                      icon: Icons.credit_card,
                      color: const Color(0xFF0F2C59),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PaymentTile(
                      label: 'Cash on Delivery',
                      value: currencyFormat.format(cashPayments),
                      icon: Icons.payments,
                      color: const Color(0xFFEE5922),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Revenue by Service Category',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),

              if (categoryRevenue.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No completed bookings data available yet.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                )
              else
                ...categoryRevenue.entries.map((e) {
                  final percent = grossRevenue > 0
                      ? (e.value / grossRevenue)
                      : 0.0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1E293B)),
                              ),
                              Text(
                                currencyFormat.format(e.value),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F2C59)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percent,
                            backgroundColor: const Color(0xFFE2E8F0),
                            color: const Color(0xFFEE5922),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _FinanceStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FinanceStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PaymentTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
