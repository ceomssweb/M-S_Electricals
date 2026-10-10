import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(24),
            decoration: AppStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Image.asset(
                      'lib/assets/logo/M&S.PNG',
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.privacy_tip,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'M&S Electricals • Last updated: October 2026',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                const Text(
                  '1. Introduction',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'At M&S Electricals, we respect your privacy and are committed to protecting the personal data of our customers. This Privacy Policy explains how we collect, use, store, and safeguard your information when you use our mobile and web applications to browse, book, and manage electrical repair and installation services.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),

                const Text(
                  '2. Information We Collect',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'To deliver prompt electrical service dispatches, we collect:\n'
                  '• Personal Identifiers: Full Name, Phone Number, and Email Address.\n'
                  '• Service Location Data: Street address, house number, landmarks, and GPS location fetched with your permission to dispatch technicians.\n'
                  '• Service Booking History: Bookings, scheduled dates, notes, and payment preference records.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),

                const Text(
                  '3. How We Use Your Information',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your data is used strictly for legitimate business operations:\n'
                  '• Dispatching qualified electrical technicians to your specified location.\n'
                  '• Sending real-time booking status notifications and email invoices.\n'
                  '• Processing secure online payments or Cash on Delivery (COD) records.\n'
                  '• Providing 24/7 customer support and resolving service queries.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),

                const Text(
                  '4. Data Security & Payment Safety',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All customer records are stored securely in encrypted Google Cloud Firestore databases. Payment transactions performed online are securely tokenized and handled directly through Razorpay API integration. M&S Electricals does NOT store card numbers, UPI PINs, or banking credentials on our servers.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),

                const Text(
                  '5. Location & Notification Permissions',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Location Permission: Used exclusively to auto-fill your current service address when placing a booking.\n'
                  '• Notification Permission: Used exclusively to deliver instant technician arrival alerts and booking status updates.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),

                const Text(
                  '6. Contact Us',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you have questions regarding this Privacy Policy or wish to request data removal, please contact our support desk:\n'
                  'Email: support@mandselectricals.com\n'
                  'Phone: +91 98765 43210',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 32),

                Center(
                  child: OutlinedButton(
                    style: AppStyles.outlinedButton,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
