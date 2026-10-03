/// Razorpay key configuration.
///
/// **DO NOT commit production keys.** This file holds the Razorpay public
/// (test) key. The secret must NEVER live in client code — it stays on a
/// Cloud Function that creates orders server-side.
///
/// Setup:
///   1. Create a Razorpay account → Dashboard → Settings → API Keys.
///   2. Copy the *Key ID* (starts with `rzp_test_` or `rzp_live_`) below.
///   3. Deploy the matching Cloud Function (`createRazorpayOrder`) with the
///      *Key Secret* set via `firebase functions:secrets:set RAZORPAY_SECRET`.
class RazorpayConfig {
  /// Replace with your real Razorpay Key ID before shipping.
  static const String keyId = 'rzp_test_REPLACE_ME';

  /// Display name shown in the Razorpay checkout sheet.
  static const String merchantName = 'M&S Electricals';

  /// Theme colour for the Razorpay checkout (hex without `#`).
  static const String themeColorHex = '#1976D2';

  /// True until you swap [keyId] for a real value.
  static bool get isPlaceholder => keyId.contains('REPLACE_ME');
}
