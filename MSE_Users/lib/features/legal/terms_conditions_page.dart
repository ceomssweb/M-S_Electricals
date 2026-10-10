import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
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
                        Icons.description_outlined,
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
                            'Terms & Conditions',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'M&S Electricals • Effective Date: October 2026',
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
                  '1. Service Agreement',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'By scheduling an electrical service through M&S Electricals mobile or web applications, you enter into a binding agreement for professional electrical inspection, repair, or installation services performed by certified technicians.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),

                const Text(
                  '2. Pricing, Taxes & Payment Methods',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Pricing: All service quotes clearly itemize the Base Amount and applicable 18% Goods and Services Tax (GST).\n'
                  '• Payment Options: You may choose to Pay Online using Razorpay (Cards, UPI, NetBanking) or select Cash on Delivery (COD) to pay the technician upon job completion.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),

                const Text(
                  '3. Cancellation & Rescheduling Policy',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Customers can reschedule or cancel a booking at no charge prior to the technician being dispatched to the location directly from the Booking Details screen in the application.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),

                const Text(
                  '4. Site Access & Safety',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The customer is responsible for providing safe, unobstructed access to circuit breaker distribution boards, switchboards, or electrical fixtures at the scheduled service time.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),

                const Text(
                  '5. 30-Day Service Warranty',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All electrical repair and installation work completed by M&S Electricals technicians includes a 30-day service warranty covering workmanship. Spare parts or replacement fixtures purchased carry manufacturer warranty terms.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),

                const Text(
                  '6. Contact & Support',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'For inquiries or warranty service claims:\n'
                  'Email: support@mandselectricals.com\n'
                  'Customer Service: +91 98765 43210',
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
