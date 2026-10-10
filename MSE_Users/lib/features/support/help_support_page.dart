import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/firestore_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _busy = false;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I book an electrician?',
      'answer':
          'Select your desired service from the home screen, choose a date and time slot, select your saved address, and proceed to book with or without payment.'
    },
    {
      'question': 'Can I reschedule or cancel my booking?',
      'answer':
          'Yes, you can reschedule or cancel your booking at any time before the technician arrives directly from the Booking Details page.'
    },
    {
      'question': 'What payment options are available?',
      'answer':
          'We accept UPI, Credit/Debit cards, Net Banking, and Wallet payments via Razorpay, as well as Cash on Delivery.'
    },
    {
      'question': 'Are the electrical services guaranteed?',
      'answer':
          'All electrical repair and installation jobs performed by M&S Electricals technicians carry a 30-day service warranty.'
    },
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String uriString) async {
    final uri = Uri.parse(uriString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $uriString')),
        );
      }
    }
  }

  Future<void> _submitTicket() async {
    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill subject and message')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirestoreConfig.db.collection('support_tickets').add({
        'customerUid': user?.uid,
        'email': user?.email ?? '',
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _subjectCtrl.clear();
        _messageCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Support ticket submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit ticket: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 24/7 Contact Channels Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.cardDecoration,
            child: Column(
              children: [
                const Text('24/7 Electrical Customer Support',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _launchUrl('tel:+919876543210'),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Call'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _launchUrl(
                          'mailto:support@mandselectricals.com?subject=Support%20Request'),
                      icon: const Icon(Icons.email, size: 18),
                      label: const Text('Email'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () =>
                          _launchUrl('https://wa.me/919876543210'),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('WhatsApp'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Legal Documents Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Legal & Compliance Policies',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined,
                      color: AppColors.primary),
                  title: const Text('Privacy Policy',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'How we protect your personal & location data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/privacy-policy'),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined,
                      color: AppColors.primary),
                  title: const Text('Terms & Conditions',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Service terms, 18% GST & 30-day warranty'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/terms-conditions'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // FAQ Accordion
          const Text('Frequently Asked Questions',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          for (final faq in _faqs)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: AppStyles.cardDecoration,
              child: ExpansionTile(
                title: Text(faq['question']!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(faq['answer']!,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                            fontSize: 13)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Submit Ticket Form
          const Text('Submit a Query / Issue',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          TextField(
            controller: _subjectCtrl,
            decoration: AppStyles.inputDecoration(
              labelText: 'Subject',
              hintText: 'e.g. Booking inquiry, billing question',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            maxLines: 4,
            decoration: AppStyles.inputDecoration(
              labelText: 'Describe your issue or query...',
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: AppStyles.filledButton,
              onPressed: _busy ? null : _submitTicket,
              child: _busy
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Support Request'),
            ),
          ),
        ],
      ),
    );
  }
}
