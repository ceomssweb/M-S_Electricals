import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/models.dart';
import 'booking_service.dart';

class BookingDetailPage extends StatelessWidget {
  final String bookingId;
  const BookingDetailPage({super.key, required this.bookingId});

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.assigned:
      case BookingStatus.inProgress:
        return Colors.indigo;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  void _showCancelDialog(BuildContext context, Booking b) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please state the reason for cancelling this booking:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Schedule conflict, changed mind...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep Booking')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
                      color: Colors.amber,
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
                decoration: const InputDecoration(
                  hintText: 'Share your feedback on the electrical service...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('This booking has been cancelled',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final currentIndex = steps.indexWhere((s) => s.$1 == status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: i <= currentIndex
                        ? const Color(0xFF1976D2)
                        : Colors.grey.shade300,
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
                          ? const Color(0xFF1976D2)
                          : Colors.grey,
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
                    ? const Color(0xFF1976D2)
                    : Colors.grey.shade300,
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
        stream: FirebaseFirestore.instance
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
            padding: const EdgeInsets.all(16),
            children: [
              // Service Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.electrical_services,
                            color: Color(0xFF1976D2), size: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.serviceTitle,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Booking ID: #${b.id.substring(0, 8)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                      Text('₹${b.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2))),
                    ],
                  ),
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
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_read, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Email Notification Status',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                            Text(
                              b.emailLogMessage ??
                                  'Status update email sent to ${b.emailNotifyAddress ?? 'customer'}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Booking Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Service Info',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: const Text('Scheduled Time'),
                        subtitle: Text(DateFormat('EEEE, dd MMM yyyy • hh:mm a')
                            .format(b.scheduledAt)),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_on),
                        title: const Text('Address'),
                        subtitle: Text(b.addressLine),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.payment),
                        title: const Text('Payment Status'),
                        subtitle: Text(b.paid ? 'Paid Online' : 'Pending Payment'),
                        trailing: Icon(
                          b.paid ? Icons.check_circle : Icons.pending,
                          color: b.paid ? Colors.green : Colors.orange,
                        ),
                      ),
                      if (b.notes != null && b.notes!.isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.note),
                          title: const Text('Customer Notes'),
                          subtitle: Text(b.notes!),
                        ),
                      if (b.cancelReason != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              const Icon(Icons.info, color: Colors.redAccent),
                          title: const Text('Cancellation Reason'),
                          subtitle: Text(b.cancelReason!),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Review Card if rated
              if (b.reviewRating != null)
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text('Your Rating: ${b.reviewRating} / 5.0',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (b.reviewComment != null &&
                            b.reviewComment!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('"${b.reviewComment}"',
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
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
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Reschedule'),
                        onPressed: () => _showRescheduleDialog(context, b),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red),
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
                FilledButton.icon(
                  icon: const Icon(Icons.star),
                  label: const Text('Rate & Review Service'),
                  onPressed: () => _showReviewDialog(context, b),
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
