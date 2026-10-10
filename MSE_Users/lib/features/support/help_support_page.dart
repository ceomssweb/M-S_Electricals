import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/firestore_config.dart';

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
        padding: const EdgeInsets.all(16),
        children: [
          // Contact Channels
          Card(
            color: const Color(0xFFE3F2FD),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('24/7 Electrical Customer Support',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl('tel:+919876543210'),
                        icon: const Icon(Icons.call),
                        label: const Text('Call'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl(
                            'mailto:support@mandselectricals.com?subject=Support%20Request'),
                        icon: const Icon(Icons.email),
                        label: const Text('Email'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _launchUrl('https://wa.me/919876543210'),
                        icon: const Icon(Icons.chat),
                        label: const Text('WhatsApp'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // FAQ Accordion
          const Text('Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final faq in _faqs)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(faq['question']!,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(faq['answer']!,
                        style: const TextStyle(color: Colors.black87)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Submit Ticket Form
          const Text('Submit a Query / Issue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _subjectCtrl,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Describe your issue or query...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submitTicket,
            child: _busy
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit Support Request'),
          ),
        ],
      ),
    );
  }
}
