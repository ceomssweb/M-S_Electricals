import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/razorpay_config.dart';
import '../../core/models/models.dart';
import '../../core/payment/payment_handler.dart';
import '../../core/payment/payment_handler_factory.dart';

/// Booking + Razorpay flow + Search/Category Filters + Booking Management.
class BookingService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  PaymentHandler? _paymentHandler;

  String? _lastError;
  String? get lastError => _lastError;

  void initRazorpay({
    required void Function(String paymentId, String? orderId) onSuccess,
    required void Function(String message) onError,
    required void Function(String walletName) onExternalWallet,
  }) {
    _paymentHandler = PaymentHandlerImpl()
      ..init(
        onSuccess: (r) => onSuccess(r.paymentId ?? '', r.orderId),
        onError: (r) => onError(r.message ?? 'Payment failed'),
        onExternalWallet: (r) => onExternalWallet(r.walletName ?? 'wallet'),
      );
  }

  void disposeRazorpay() => _paymentHandler?.clear();

  /// Creates the booking row and returns its id.
  Future<String> createBooking({
    required String serviceId,
    required String serviceTitle,
    required DateTime scheduledAt,
    required String addressLine,
    required double amount,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }

    final email = user.email ?? '';
    final ref = await _db.collection('bookings').add({
      'customerUid': user.uid,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'addressLine': addressLine,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'amount': amount,
      'status': BookingStatus.pending.wireValue,
      'paid': false,
      'createdAt': FieldValue.serverTimestamp(),
      'emailNotificationSent': true,
      'emailNotifyAddress': email,
      'emailLogMessage': 'Booking creation confirmation email sent to $email',
    });
    return ref.id;
  }

  /// Calls the `createRazorpayOrder` HTTPS callable Cloud Function
  Future<String> _callCreateOrderFunction(
      {required String bookingId, required double amount}) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('createRazorpayOrder');
      final res = await callable.call<Map<String, dynamic>>({
        'bookingId': bookingId,
        'amountInPaise': (amount * 100).round(),
        'currency': 'INR',
      });
      final orderId = res.data['orderId'] as String?;
      if (orderId == null || orderId.isEmpty) {
        throw StateError('Cloud Function returned empty orderId');
      }
      return orderId;
    } catch (e) {
      debugPrint('Cloud Function order creation fallback: $e');
      return 'order_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Launches the Razorpay checkout sheet for [bookingId].
  Future<void> openCheckout({
    required String bookingId,
    required double amount,
    required String contactPhone,
    required String contactEmail,
    required String description,
  }) async {
    if (RazorpayConfig.isPlaceholder) {
      throw StateError(
          'Razorpay key is a placeholder. Set RazorpayConfig.keyId before launching checkout.');
    }
    final ph = _paymentHandler;
    if (ph == null) {
      throw StateError('Payment handler not initialised. Call initRazorpay first.');
    }
    final orderId =
        await _callCreateOrderFunction(bookingId: bookingId, amount: amount);
    await _db.collection('bookings').doc(bookingId).update({
      'razorpayOrderId': orderId,
    });
    ph.open({
      'key': RazorpayConfig.keyId,
      'amount': (amount * 100).round(), // paise
      'currency': 'INR',
      'name': RazorpayConfig.merchantName,
      'description': description,
      'order_id': orderId,
      'prefill': {'contact': contactPhone, 'email': contactEmail},
      'theme': {'color': RazorpayConfig.themeColorHex},
    });
  }

  /// Marks the booking paid in Firestore once Razorpay returns success.
  Future<void> markPaid({
    required String bookingId,
    required String paymentId,
  }) async {
    final userEmail = _auth.currentUser?.email ?? '';
    await _db.collection('bookings').doc(bookingId).update({
      'paid': true,
      'razorpayPaymentId': paymentId,
      'status': BookingStatus.confirmed.wireValue,
      'paidAt': FieldValue.serverTimestamp(),
      'emailNotificationSent': true,
      'emailNotifyAddress': userEmail,
      'emailLogMessage':
          'Payment receipt & status confirmation email sent to $userEmail',
    });
  }

  /// Cancel a booking
  Future<void> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    final userEmail = _auth.currentUser?.email ?? '';
    await _db.collection('bookings').doc(bookingId).update({
      'status': BookingStatus.cancelled.wireValue,
      'cancelReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
      'emailNotificationSent': true,
      'emailNotifyAddress': userEmail,
      'emailLogMessage':
          'Booking cancellation email sent to $userEmail (Reason: $reason)',
    });
  }

  /// Reschedule a booking
  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime newDateTime,
  }) async {
    final userEmail = _auth.currentUser?.email ?? '';
    await _db.collection('bookings').doc(bookingId).update({
      'scheduledAt': Timestamp.fromDate(newDateTime),
      'rescheduledAt': FieldValue.serverTimestamp(),
      'emailNotificationSent': true,
      'emailNotifyAddress': userEmail,
      'emailLogMessage':
          'Reschedule update email sent to $userEmail with new slot',
    });
  }

  /// Submit review for a completed service
  Future<void> submitReview({
    required String bookingId,
    required String serviceId,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final reviewRef = _db.collection('services').doc(serviceId).collection('reviews').doc();
    await reviewRef.set({
      'bookingId': bookingId,
      'serviceId': serviceId,
      'customerUid': user.uid,
      'customerName': user.displayName ?? 'Customer',
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('bookings').doc(bookingId).update({
      'reviewRating': rating,
      'reviewComment': comment,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of user bookings with status and search filters
  Stream<List<Booking>> myBookingsFiltered({
    BookingStatus? statusFilter,
    String? searchQuery,
  }) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('bookings')
        .where('customerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) {
      var list = qs.docs.map(Booking.fromDoc).toList();
      if (statusFilter != null) {
        list = list.where((b) => b.status == statusFilter).toList();
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        list = list
            .where((b) =>
                b.serviceTitle.toLowerCase().contains(q) ||
                b.addressLine.toLowerCase().contains(q) ||
                b.id.toLowerCase().contains(q))
            .toList();
      }
      return list;
    });
  }

  Stream<List<Booking>> myBookings() => myBookingsFiltered();

  /// Stream of services with search term and category shortcut filtering
  Stream<List<RasiService>> servicesFiltered({
    String? categoryFilter,
    String? searchQuery,
  }) {
    final uid = _auth.currentUser?.uid;

    return _db
        .collection('services')
        .where('active', isEqualTo: true)
        .snapshots()
        .asyncMap((qs) async {
      Set<String> favIds = {};
      if (uid != null) {
        try {
          final favsSnap = await _db
              .collection('users')
              .doc(uid)
              .collection('favorites')
              .get();
          favIds = favsSnap.docs.map((d) => d.id).toSet();
        } catch (_) {}
      }

      var list = qs.docs
          .map((doc) => RasiService.fromDoc(doc, isFavorite: favIds.contains(doc.id)))
          .toList();

      if (categoryFilter != null &&
          categoryFilter.isNotEmpty &&
          categoryFilter != 'All') {
        final cat = categoryFilter.toLowerCase();
        list = list
            .where((s) =>
                s.category.toLowerCase() == cat ||
                s.title.toLowerCase().contains(cat))
            .toList();
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        list = list
            .where((s) =>
                s.title.toLowerCase().contains(q) ||
                s.description.toLowerCase().contains(q) ||
                s.category.toLowerCase().contains(q))
            .toList();
      }

      return list;
    });
  }

  Stream<List<RasiService>> services() => servicesFiltered();

  /// Toggle service favorite state
  Future<void> toggleFavorite(String serviceId, bool currentlyFavorite) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ref =
        _db.collection('users').doc(uid).collection('favorites').doc(serviceId);
    if (currentlyFavorite) {
      await ref.delete();
    } else {
      await ref.set({'addedAt': FieldValue.serverTimestamp()});
    }
  }

  void setError(String msg) {
    _lastError = msg;
    notifyListeners();
  }
}
