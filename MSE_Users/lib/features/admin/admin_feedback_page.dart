import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/config/firestore_config.dart';
import '../../core/models/models.dart';

class AdminFeedbackPage extends StatefulWidget {
  const AdminFeedbackPage({super.key});

  @override
  State<AdminFeedbackPage> createState() => _AdminFeedbackPageState();
}

class _AdminFeedbackPageState extends State<AdminFeedbackPage> {
  int _selectedStarFilter = 0; // 0 = All stars

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset(
          'lib/assets/logo/M&S.PNG',
          height: 38,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text('Customer Reviews'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreConfig.db.collection('bookings').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Failed to load feedback.'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookingsWithReviews = snap.data!.docs
              .map((d) => Booking.fromDoc(d))
              .where((b) => b.reviewRating != null)
              .toList();

          double totalRatingSum = 0;
          for (final b in bookingsWithReviews) {
            totalRatingSum += (b.reviewRating ?? 0);
          }
          final avgRating = bookingsWithReviews.isNotEmpty
              ? totalRatingSum / bookingsWithReviews.length
              : 5.0;

          var filteredReviews = bookingsWithReviews;
          if (_selectedStarFilter > 0) {
            filteredReviews = bookingsWithReviews
                .where((b) => (b.reviewRating ?? 0).round() == _selectedStarFilter)
                .toList();
          }

          return Column(
            children: [
              // Rating Overview Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2C59)),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < avgRating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color(0xFFEE5922),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Satisfaction Score',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Based on ${bookingsWithReviews.length} verified booking reviews.',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Rating Filter Chips
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final isSelected = _selectedStarFilter == i;
                    return ChoiceChip(
                      label: Text(i == 0 ? 'All Ratings' : '$i ⭐'),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0F2C59),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedStarFilter = i;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Feedback Stream List
              Expanded(
                child: filteredReviews.isEmpty
                    ? const Center(
                        child: Text(
                          'No customer feedback matches this filter.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredReviews.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final b = filteredReviews[i];
                          final rating = b.reviewRating ?? 5.0;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        b.serviceTitle,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF1E293B)),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (starIdx) => Icon(
                                            starIdx < rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: const Color(0xFFEE5922),
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Booking #${b.id.substring(0, 8)} • Completed on ${dateFormat.format(b.scheduledAt)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  if (b.reviewComment != null &&
                                      b.reviewComment!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Text(
                                        '"${b.reviewComment}"',
                                        style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Color(0xFF334155)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
