# Rasi Customer App

Customer-facing Flutter app for Rasi Electricals. Customers browse services,
book appointments, and pay via Razorpay.

## Bring it online

```powershell
cd f:\Meena-AI\Manoj_customer
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
flutter run
```

Then put your Razorpay public Key ID into
`lib/core/config/razorpay_config.dart` (replace `rzp_test_REPLACE_ME`).

## Architecture

- `lib/main.dart` — `RasiCustomerApp`, theme, GoRouter, all UI pages.
- `lib/core/models/models.dart` — `RasiService`, `Booking`, `BookingStatus`.
- `lib/core/config/razorpay_config.dart` — public key only.
- `lib/features/auth/auth_state.dart` — Firebase auth.
- `lib/features/booking/booking_service.dart` — Firestore + Razorpay.

Booking flow: `createBooking` (status=pending) → `_callCreateOrderFunction`
(STUB) → Razorpay sheet → `markPaid` (status=confirmed). Admin then assigns
a job to a provider.

## Known gaps

- `_callCreateOrderFunction` is stubbed; replace with `httpsCallable` once
  the `createRazorpayOrder` Cloud Function is deployed.
- Razorpay key is a placeholder until you set it.
