import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firestore_config.dart';

/// Dynamic Razorpay key and merchant configuration loaded from Cloud Firestore `system_config/razorpay`.
class RazorpayConfig {
  static String _dynamicKeyId = 'rzp_test_REPLACE_ME';
  static String _merchantName = 'M&S Electricals';
  static String _themeColorHex = '#0F2C59';

  static String get keyId => _dynamicKeyId;
  static String get merchantName => _merchantName;
  static String get themeColorHex => _themeColorHex;

  static bool get isPlaceholder =>
      _dynamicKeyId.contains('REPLACE_ME') || _dynamicKeyId.isEmpty;

  /// Listen to dynamic Razorpay configuration updates from Firestore
  static void initDynamicConfig() {
    try {
      FirestoreConfig.db
          .collection('system_config')
          .doc('razorpay')
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          final data = doc.data() ?? {};
          if (data['keyId'] != null && (data['keyId'] as String).isNotEmpty) {
            _dynamicKeyId = data['keyId'] as String;
          }
          if (data['merchantName'] != null) {
            _merchantName = data['merchantName'] as String;
          }
          if (data['themeColorHex'] != null) {
            _themeColorHex = data['themeColorHex'] as String;
          }
          debugPrint('Razorpay dynamic config loaded from Firestore: keyId=$keyId');
        }
      }, onError: (e) {
        debugPrint('Non-fatal error reading dynamic Razorpay config: $e');
      });
    } catch (e) {
      debugPrint('Non-fatal error initializing dynamic Razorpay config: $e');
    }
  }

  /// Update Razorpay Config in Firestore (Admin function)
  static Future<void> updateConfig({
    required String keyId,
    required String merchantName,
    required String themeColorHex,
  }) async {
    await FirestoreConfig.db.collection('system_config').doc('razorpay').set({
      'keyId': keyId,
      'merchantName': merchantName,
      'themeColorHex': themeColorHex,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
