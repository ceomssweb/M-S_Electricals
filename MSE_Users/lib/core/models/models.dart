import 'package:cloud_firestore/cloud_firestore.dart';

/// Saved user address for booking services.
class UserAddress {
  final String id;
  final String label; // e.g. 'Home', 'Work', 'Other'
  final String houseNo;
  final String street;
  final String landmark;
  final String city;
  final String pincode;
  final String? phoneNumber;
  final bool isDefault;

  const UserAddress({
    required this.id,
    required this.label,
    required this.houseNo,
    required this.street,
    required this.city,
    required this.pincode,
    this.landmark = '',
    this.phoneNumber,
    this.isDefault = false,
  });

  String get formattedAddress =>
      [houseNo, street, if (landmark.isNotEmpty) landmark, city, pincode]
          .where((s) => s.isNotEmpty)
          .join(', ');

  factory UserAddress.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return UserAddress(
      id: doc.id,
      label: (d['label'] ?? 'Home') as String,
      houseNo: (d['houseNo'] ?? '') as String,
      street: (d['street'] ?? '') as String,
      landmark: (d['landmark'] ?? '') as String,
      city: (d['city'] ?? '') as String,
      pincode: (d['pincode'] ?? '') as String,
      phoneNumber: d['phoneNumber'] as String?,
      isDefault: (d['isDefault'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'houseNo': houseNo,
        'street': street,
        'landmark': landmark,
        'city': city,
        'pincode': pincode,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        'isDefault': isDefault,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

/// Extended User Profile stored in Firestore `users/{uid}`.
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String phoneNumber;
  final String role; // 'customer', 'provider', 'admin'
  final String? photoUrl;
  final bool pushEnabled;
  final bool emailNotifyEnabled;
  final String? fcmToken;
  final DateTime? createdAt;
  final bool isAdmin;
  final bool isProvider;
  final String verificationStatus; // 'pending', 'verified', 'rejected'

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phoneNumber = '',
    this.role = 'customer',
    this.photoUrl,
    this.pushEnabled = true,
    this.emailNotifyEnabled = true,
    this.fcmToken,
    this.createdAt,
    this.isAdmin = false,
    this.isProvider = false,
    this.verificationStatus = 'verified',
  });

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final roleVal = (d['role'] ?? 'customer') as String;
    final boolIsAdmin = (d['isAdmin'] ?? false) as bool;
    final isAdminUser = boolIsAdmin || roleVal.toLowerCase() == 'admin';
    final isProviderUser = roleVal.toLowerCase() == 'provider';

    return UserProfile(
      uid: doc.id,
      email: (d['email'] ?? '') as String,
      displayName: (d['displayName'] ?? '') as String,
      phoneNumber: (d['phoneNumber'] ?? '') as String,
      role: roleVal,
      photoUrl: d['photoUrl'] as String?,
      pushEnabled: (d['pushEnabled'] ?? true) as bool,
      emailNotifyEnabled: (d['emailNotifyEnabled'] ?? true) as bool,
      fcmToken: d['fcmToken'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      isAdmin: isAdminUser,
      isProvider: isProviderUser,
      verificationStatus: (d['verificationStatus'] ?? 'verified') as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'role': role,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'pushEnabled': pushEnabled,
        'emailNotifyEnabled': emailNotifyEnabled,
        if (fcmToken != null) 'fcmToken': fcmToken,
        'isAdmin': isAdmin,
        'verificationStatus': verificationStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

/// Extended Service Provider Profile for electricians and technicians.
class ServiceProviderProfile {
  final String uid;
  final String email;
  final String displayName;
  final String phoneNumber;
  final String? photoUrl;
  final List<String> skills;
  final int experienceYears;
  final String panNumber;
  final String aadharNumber;
  final String? panPhotoUrl;
  final String? aadharPhotoUrl;
  final String verificationStatus; // 'pending', 'verified', 'rejected'
  final bool isAvailable;
  final DateTime createdAt;

  const ServiceProviderProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    this.photoUrl,
    required this.skills,
    required this.experienceYears,
    required this.panNumber,
    required this.aadharNumber,
    this.panPhotoUrl,
    this.aadharPhotoUrl,
    this.verificationStatus = 'pending',
    this.isAvailable = true,
    required this.createdAt,
  });

  factory ServiceProviderProfile.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final skillsRaw = d['skills'];
    List<String> skillsList = [];
    if (skillsRaw is List) {
      skillsList = skillsRaw.map((s) => s.toString()).toList();
    }

    return ServiceProviderProfile(
      uid: doc.id,
      email: (d['email'] ?? '') as String,
      displayName: (d['displayName'] ?? '') as String,
      phoneNumber: (d['phoneNumber'] ?? '') as String,
      photoUrl: d['photoUrl'] as String?,
      skills: skillsList,
      experienceYears: ((d['experienceYears'] ?? 0) as num).toInt(),
      panNumber: (d['panNumber'] ?? '') as String,
      aadharNumber: (d['aadharNumber'] ?? '') as String,
      panPhotoUrl: d['panPhotoUrl'] as String?,
      aadharPhotoUrl: d['aadharPhotoUrl'] as String?,
      verificationStatus: (d['verificationStatus'] ?? 'pending') as String,
      isAvailable: (d['isAvailable'] ?? true) as bool,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'skills': skills,
        'experienceYears': experienceYears,
        'panNumber': panNumber,
        'aadharNumber': aadharNumber,
        if (panPhotoUrl != null) 'panPhotoUrl': panPhotoUrl,
        if (aadharPhotoUrl != null) 'aadharPhotoUrl': aadharPhotoUrl,
        'verificationStatus': verificationStatus,
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

/// Review submitted for a service booking.
class ServiceReview {
  final String id;
  final String bookingId;
  final String serviceId;
  final String customerUid;
  final String customerName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ServiceReview({
    required this.id,
    required this.bookingId,
    required this.serviceId,
    required this.customerUid,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ServiceReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ServiceReview(
      id: doc.id,
      bookingId: (d['bookingId'] ?? '') as String,
      serviceId: (d['serviceId'] ?? '') as String,
      customerUid: (d['customerUid'] ?? '') as String,
      customerName: (d['customerName'] ?? 'Customer') as String,
      rating: ((d['rating'] ?? 5.0) as num).toDouble(),
      comment: (d['comment'] ?? '') as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'bookingId': bookingId,
        'serviceId': serviceId,
        'customerUid': customerUid,
        'customerName': customerName,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

/// A service offered by Rasi Electricals (e.g. "AC Repair", "Wiring Inspection").
class RasiService {
  final String id;
  final String title;
  final String description;
  final String category;
  final double basePrice;
  final double discountPercent;
  final int durationMinutes;
  final String iconEmoji;
  final String? imageUrl;
  final double rating;
  final int ratingCount;
  final bool active;
  final bool isFavorite;

  const RasiService({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.basePrice,
    this.discountPercent = 0.0,
    required this.durationMinutes,
    required this.iconEmoji,
    this.imageUrl,
    this.rating = 0,
    this.ratingCount = 0,
    this.active = true,
    this.isFavorite = false,
  });

  double get finalPrice => discountPercent > 0
      ? basePrice * (1 - (discountPercent / 100))
      : basePrice;

  factory RasiService.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    bool isFavorite = false,
  }) {
    final d = doc.data() ?? {};
    return RasiService(
      id: doc.id,
      title: (d['title'] ?? '') as String,
      description: (d['description'] ?? '') as String,
      category: (d['category'] ?? 'Wiring') as String,
      basePrice: ((d['basePrice'] ?? 0) as num).toDouble(),
      discountPercent: ((d['discountPercent'] ?? 0) as num).toDouble(),
      durationMinutes: ((d['durationMinutes'] ?? 60) as num).toInt(),
      iconEmoji: (d['iconEmoji'] ?? '⚡') as String,
      imageUrl: d['imageUrl'] as String?,
      rating: ((d['rating'] ?? 4.8) as num).toDouble(),
      ratingCount: ((d['ratingCount'] ?? 15) as num).toInt(),
      active: (d['active'] ?? true) as bool,
      isFavorite: isFavorite,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'basePrice': basePrice,
        'discountPercent': discountPercent,
        'durationMinutes': durationMinutes,
        'iconEmoji': iconEmoji,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'rating': rating,
        'ratingCount': ratingCount,
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  RasiService copyWith({
    String? title,
    String? description,
    String? category,
    double? basePrice,
    double? discountPercent,
    int? durationMinutes,
    String? iconEmoji,
    bool? active,
    bool? isFavorite,
  }) {
    return RasiService(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      discountPercent: discountPercent ?? this.discountPercent,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      imageUrl: imageUrl,
      rating: rating,
      ratingCount: ratingCount,
      active: active ?? this.active,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// Booking lifecycle: `pending → confirmed → assigned → in_progress → completed`
/// (or `cancelled` from any non-completed state).
enum BookingStatus {
  pending,
  confirmed,
  assigned,
  inProgress,
  completed,
  cancelled;

  static BookingStatus fromString(String? s) {
    switch (s) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'assigned':
        return BookingStatus.assigned;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  String get wireValue {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.assigned:
        return 'assigned';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.assigned:
        return 'Assigned';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class Booking {
  final String id;
  final String customerUid;
  final String serviceId;
  final String serviceTitle;
  final DateTime scheduledAt;
  final String addressLine;
  final String? notes;
  final double amount;
  final BookingStatus status;
  final String? assignedProviderUid;
  final String? assignedProviderName;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final bool paid;
  final DateTime createdAt;
  final String? cancelReason;
  final DateTime? rescheduledAt;
  final double? reviewRating;
  final String? reviewComment;
  final bool emailNotificationSent;
  final String? emailNotifyAddress;
  final String? emailLogMessage;

  const Booking({
    required this.id,
    required this.customerUid,
    required this.serviceId,
    required this.serviceTitle,
    required this.scheduledAt,
    required this.addressLine,
    required this.amount,
    required this.status,
    required this.paid,
    required this.createdAt,
    this.notes,
    this.assignedProviderUid,
    this.assignedProviderName,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.cancelReason,
    this.rescheduledAt,
    this.reviewRating,
    this.reviewComment,
    this.emailNotificationSent = false,
    this.emailNotifyAddress,
    this.emailLogMessage,
  });

  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Booking(
      id: doc.id,
      customerUid: (d['customerUid'] ?? '') as String,
      serviceId: (d['serviceId'] ?? '') as String,
      serviceTitle: (d['serviceTitle'] ?? '') as String,
      scheduledAt: (d['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      addressLine: (d['addressLine'] ?? '') as String,
      notes: d['notes'] as String?,
      amount: ((d['amount'] ?? 0) as num).toDouble(),
      status: BookingStatus.fromString(d['status'] as String?),
      assignedProviderUid: d['assignedProviderUid'] as String?,
      assignedProviderName: d['assignedProviderName'] as String?,
      razorpayOrderId: d['razorpayOrderId'] as String?,
      razorpayPaymentId: d['razorpayPaymentId'] as String?,
      paid: (d['paid'] ?? false) as bool,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cancelReason: d['cancelReason'] as String?,
      rescheduledAt: (d['rescheduledAt'] as Timestamp?)?.toDate(),
      reviewRating: (d['reviewRating'] as num?)?.toDouble(),
      reviewComment: d['reviewComment'] as String?,
      emailNotificationSent: (d['emailNotificationSent'] ?? false) as bool,
      emailNotifyAddress: d['emailNotifyAddress'] as String?,
      emailLogMessage: d['emailLogMessage'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'customerUid': customerUid,
        'serviceId': serviceId,
        'serviceTitle': serviceTitle,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'addressLine': addressLine,
        if (notes != null) 'notes': notes,
        'amount': amount,
        'status': status.wireValue,
        if (assignedProviderUid != null)
          'assignedProviderUid': assignedProviderUid,
        if (assignedProviderName != null)
          'assignedProviderName': assignedProviderName,
        if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
        if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
        'paid': paid,
        'createdAt': Timestamp.fromDate(createdAt),
        if (cancelReason != null) 'cancelReason': cancelReason,
        if (rescheduledAt != null)
          'rescheduledAt': Timestamp.fromDate(rescheduledAt!),
        if (reviewRating != null) 'reviewRating': reviewRating,
        if (reviewComment != null) 'reviewComment': reviewComment,
        'emailNotificationSent': emailNotificationSent,
        if (emailNotifyAddress != null)
          'emailNotifyAddress': emailNotifyAddress,
        if (emailLogMessage != null) 'emailLogMessage': emailLogMessage,
      };
}
