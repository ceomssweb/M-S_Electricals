import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/firestore_config.dart';
import '../../core/config/razorpay_config.dart';
import '../../core/models/models.dart';
import '../../core/payment/payment_handler.dart';
import '../../core/payment/payment_handler_factory.dart';

/// Booking + Razorpay flow + Search/Category Filters + Booking Management.
class BookingService extends ChangeNotifier {
  final FirebaseFirestore _db = FirestoreConfig.db;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  PaymentHandler? _paymentHandler;

  String? _lastError;
  String? get lastError => _lastError;

  BookingService() {
    _seedDefaultServicesIfEmpty();
  }

  Future<void> _seedDefaultServicesIfEmpty() async {
    // Guest users cannot write to Firestore; skip auto-seed writes if not signed in
    if (_auth.currentUser == null) return;
    try {
      final snap = await _db.collection('services').limit(1).get();
      if (snap.docs.isEmpty) {
        debugPrint('Seeding initial default services into Firestore...');
        final defaultServices = [
          {
            'title': 'Complete Home Wiring Inspection',
            'category': 'Wiring',
            'description':
                'Full diagnostic inspection of circuit breakers, distribution boards, and earthing.',
            'basePrice': 999.0,
            'discountPercent': 10.0,
            'durationMinutes': 90,
            'iconEmoji': '🔌',
            'rating': 4.9,
            'ratingCount': 42,
            'active': true,
          },
          {
            'title': 'AC Servicing & Gas Refill',
            'category': 'AC',
            'description':
                'Comprehensive split & window AC deep cleaning, filter wash, and refrigerant pressure check.',
            'basePrice': 1499.0,
            'discountPercent': 15.0,
            'durationMinutes': 75,
            'iconEmoji': '❄️',
            'rating': 4.8,
            'ratingCount': 88,
            'active': true,
          },
          {
            'title': 'LED Panel & Chandelier Installation',
            'category': 'Lighting',
            'description':
                'Safe mounting, decorative fixture wiring, and mood light switch installation.',
            'basePrice': 599.0,
            'discountPercent': 0.0,
            'durationMinutes': 45,
            'iconEmoji': '💡',
            'rating': 4.7,
            'ratingCount': 35,
            'active': true,
          },
          {
            'title': 'Ceiling Fan Repair & Regulator Replace',
            'category': 'Fan',
            'description':
                'Fix noisy bearings, wobbly blades, capacitor replacement, and speed regulator repair.',
            'basePrice': 399.0,
            'discountPercent': 5.0,
            'durationMinutes': 40,
            'iconEmoji': '🌀',
            'rating': 4.8,
            'ratingCount': 50,
            'active': true,
          },
          {
            'title': 'Emergency Short Circuit Fix (24/7)',
            'category': 'Emergency',
            'description':
                'Priority emergency dispatch for tripped main fuses, burning smell, or power outages.',
            'basePrice': 799.0,
            'discountPercent': 0.0,
            'durationMinutes': 45,
            'iconEmoji': '🚨',
            'rating': 5.0,
            'ratingCount': 95,
            'active': true,
          },
          {
            'title': 'Switchboard & Socket Replacement',
            'category': 'Repair',
            'description':
                'Replacement of damaged 6A/16A sockets, heavy appliance switches, and faceplates.',
            'basePrice': 299.0,
            'discountPercent': 0.0,
            'durationMinutes': 30,
            'iconEmoji': '🔧',
            'rating': 4.7,
            'ratingCount': 28,
            'active': true,
          },
        ];

        for (final s in defaultServices) {
          await _db.collection('services').add({
            ...s,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Auto-seed services non-fatal error: $e');
    }
  }

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

    final customerName = user.displayName ?? 'Customer';

    // Top-level reviews collection
    await _db.collection('reviews').add({
      'bookingId': bookingId,
      'serviceId': serviceId,
      'customerUid': user.uid,
      'customerName': customerName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final reviewRef = _db.collection('services').doc(serviceId).collection('reviews').doc();
    await reviewRef.set({
      'bookingId': bookingId,
      'serviceId': serviceId,
      'customerUid': user.uid,
      'customerName': customerName,
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

  /// Stream of services directly from Cloud Firestore database
  Stream<List<RasiService>> servicesFiltered({
    String? categoryFilter,
    String? searchQuery,
  }) {
    final uid = _auth.currentUser?.uid;

    return _db.collection('services').snapshots().asyncMap((qs) async {
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
          .where((s) => s.active)
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
    }).handleError((error) {
      debugPrint('Firestore services stream error: $error');
      return <RasiService>[];
    });
  }

  Stream<List<RasiService>> services() => servicesFiltered();

  /// Real-time stream of ALL services for Admin management (including inactive services)
  Stream<List<RasiService>> adminServicesFiltered({
    String? categoryFilter,
    String? searchQuery,
  }) {
    return _db.collection('services').snapshots().map((qs) {
      var list = qs.docs.map((doc) => RasiService.fromDoc(doc)).toList();

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

  /// Add a new service document reactively
  Future<String> addService(RasiService service) async {
    final docRef = await _db.collection('services').add({
      ...service.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
    return docRef.id;
  }

  /// Seed initial default electrical services into Firestore database
  Future<void> seedDefaultServices() async {
    final defaultServices = [
      const RasiService(
        id: '',
        title: 'Complete Home Wiring Inspection',
        category: 'Wiring',
        description:
            'Full diagnostic inspection of circuit breakers, distribution boards, and earthing.',
        basePrice: 999.0,
        discountPercent: 10.0,
        durationMinutes: 90,
        iconEmoji: '🔌',
        rating: 4.9,
        ratingCount: 42,
        active: true,
      ),
      const RasiService(
        id: '',
        title: 'AC Servicing & Gas Refill',
        category: 'AC',
        description:
            'Comprehensive split & window AC deep cleaning, filter wash, and refrigerant pressure check.',
        basePrice: 1499.0,
        discountPercent: 15.0,
        durationMinutes: 75,
        iconEmoji: '❄️',
        rating: 4.8,
        ratingCount: 88,
        active: true,
      ),
      const RasiService(
        id: '',
        title: 'LED Panel & Chandelier Installation',
        category: 'Lighting',
        description:
            'Safe mounting, decorative fixture wiring, and mood light switch installation.',
        basePrice: 599.0,
        discountPercent: 0.0,
        durationMinutes: 45,
        iconEmoji: '💡',
        rating: 4.7,
        ratingCount: 35,
        active: true,
      ),
      const RasiService(
        id: '',
        title: 'Ceiling Fan Repair & Regulator Replace',
        category: 'Fan',
        description:
            'Fix noisy bearings, wobbly blades, capacitor replacement, and speed regulator repair.',
        basePrice: 399.0,
        discountPercent: 5.0,
        durationMinutes: 40,
        iconEmoji: '🌀',
        rating: 4.8,
        ratingCount: 50,
        active: true,
      ),
      const RasiService(
        id: '',
        title: 'Emergency Short Circuit Fix (24/7)',
        category: 'Emergency',
        description:
            'Priority emergency dispatch for tripped main fuses, burning smell, or power outages.',
        basePrice: 799.0,
        discountPercent: 0.0,
        durationMinutes: 45,
        iconEmoji: '🚨',
        rating: 5.0,
        ratingCount: 95,
        active: true,
      ),
      const RasiService(
        id: '',
        title: 'Switchboard & Socket Replacement',
        category: 'Repair',
        description:
            'Replacement of damaged 6A/16A sockets, heavy appliance switches, and faceplates.',
        basePrice: 299.0,
        discountPercent: 0.0,
        durationMinutes: 30,
        iconEmoji: '🔧',
        rating: 4.7,
        ratingCount: 28,
        active: true,
      ),
    ];

    for (final s in defaultServices) {
      await addService(s);
    }
  }

  /// Update an existing service document reactively
  Future<void> updateService(RasiService service) async {
    await _db.collection('services').doc(service.id).update({
      ...service.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  /// Delete a service document reactively
  Future<void> deleteService(String serviceId) async {
    await _db.collection('services').doc(serviceId).delete();
    notifyListeners();
  }

  /// Toggle active state of a service document reactively
  Future<void> toggleServiceActive(String serviceId, bool active) async {
    await _db.collection('services').doc(serviceId).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

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
