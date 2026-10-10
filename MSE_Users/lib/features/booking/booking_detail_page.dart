import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/firestore_config.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import 'booking_service.dart';

class BookingDetailPage extends StatelessWidget {
  final String bookingId;
  const BookingDetailPage({super.key, required this.bookingId});

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.assigned:
      case BookingStatus.inProgress:
        return AppColors.primary;
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
        return AppColors.error;
    }
  }

  void _showCancelDialog(BuildContext context, Booking b) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please state the reason for cancelling this booking:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: AppStyles.inputDecoration(
                labelText: 'Reason for Cancellation',
                hintText: 'e.g. Schedule conflict, changed mind...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Booking')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason.')),
                );
                return;
              }
              final svc = context.read<BookingService>();
              await svc.cancelBooking(
                bookingId: b.id,
                reason: reasonCtrl.text.trim(),
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking cancelled.')),
                );
              }
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, Booking b) async {
    final d = await showDatePicker(
      context: context,
      initialDate: b.scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (d == null || !context.mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(b.scheduledAt),
    );
    if (t == null || !context.mounted) return;

    final newScheduled = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    final svc = context.read<BookingService>();
    await svc.rescheduleBooking(bookingId: b.id, newDateTime: newScheduled);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Rescheduled to ${DateFormat('EEE, dd MMM • hh:mm a').format(newScheduled)}')),
      );
    }
  }

  void _showReviewDialog(BuildContext context, Booking b) {
    double rating = 5.0;
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rate ${b.serviceTitle}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starVal = i + 1.0;
                  return IconButton(
                    icon: Icon(
                      starVal <= rating ? Icons.star : Icons.star_border,
                      color: AppColors.accent,
                      size: 36,
                    ),
                    onPressed: () {
                      setModalState(() => rating = starVal);
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: AppStyles.inputDecoration(
                  labelText: 'Feedback & Rating',
                  hintText: 'Share your feedback on the electrical service...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: AppStyles.filledButton,
                  onPressed: () async {
                    final svc = context.read<BookingService>();
                    await svc.submitReview(
                      bookingId: b.id,
                      serviceId: b.serviceId,
                      rating: rating,
                      comment: commentCtrl.text.trim(),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Thank you for your rating!')),
                      );
                    }
                  },
                  child: const Text('Submit Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(BookingStatus status) {
    final steps = [
      (BookingStatus.pending, 'Pending'),
      (BookingStatus.confirmed, 'Confirmed'),
      (BookingStatus.assigned, 'Assigned'),
      (BookingStatus.inProgress, 'In Progress'),
      (BookingStatus.completed, 'Completed'),
    ];

    if (status == BookingStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: AppColors.error),
            SizedBox(width: 8),
            Text('This booking has been cancelled',
                style:
                    TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final currentIndex = steps.indexWhere((s) => s.$1 == status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: AppStyles.cardDecoration,
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: i <= currentIndex
                        ? AppColors.primary
                        : AppColors.border,
                    child: Icon(
                      i <= currentIndex ? Icons.check : Icons.circle,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[i].$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: i == currentIndex
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: i <= currentIndex
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (i < steps.length - 1)
              Container(
                width: 16,
                height: 2,
                color: i < currentIndex
                    ? AppColors.primary
                    : AppColors.border,
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreConfig.db
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Could not load booking details.'));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final b = Booking.fromDoc(snap.data!);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Service Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.electrical_services,
                          color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.serviceTitle,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('Booking ID: #${b.id.substring(0, 8)}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text('₹${b.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Status timeline
              _buildStatusTimeline(b.status),
              const SizedBox(height: 16),

              // Email Status Banner
              if (b.emailNotificationSent)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_read,
                          color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Email Notification Status',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success)),
                            Text(
                              b.emailLogMessage ??
                                  'Status update email sent to ${b.emailNotifyAddress ?? 'customer'}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Booking Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service Info',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const Divider(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event, color: AppColors.primary),
                      title: const Text('Scheduled Time'),
                      subtitle: Text(DateFormat('EEEE, dd MMM yyyy • hh:mm a')
                          .format(b.scheduledAt)),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on, color: AppColors.primary),
                      title: const Text('Address'),
                      subtitle: Text(b.addressLine),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.payment, color: AppColors.primary),
                      title: const Text('Payment Status'),
                      subtitle: Text(b.paid ? 'Paid Online' : 'Pending Payment'),
                      trailing: Icon(
                        b.paid ? Icons.check_circle : Icons.pending,
                        color: b.paid ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    if (b.notes != null && b.notes!.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.note, color: AppColors.primary),
                        title: const Text('Customer Notes'),
                        subtitle: Text(b.notes!),
                      ),
                    if (b.cancelReason != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info, color: AppColors.error),
                        title: const Text('Cancellation Reason'),
                        subtitle: Text(b.cancelReason!),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Review Card if rated
              if (b.reviewRating != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text('Your Rating: ${b.reviewRating} / 5.0',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                      if (b.reviewComment != null &&
                          b.reviewComment!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('"${b.reviewComment}"',
                            style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Action buttons
              if (b.status == BookingStatus.pending ||
                  b.status == BookingStatus.confirmed) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: AppStyles.outlinedButton,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Reschedule'),
                        onPressed: () => _showRescheduleDialog(context, b),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel'),
                        onPressed: () => _showCancelDialog(context, b),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              if (b.status == BookingStatus.completed &&
                  b.reviewRating == null) ...[
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    style: AppStyles.filledButton,
                    icon: const Icon(Icons.star),
                    label: const Text('Rate & Review Service'),
                    onPressed: () => _showReviewDialog(context, b),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}
