import 'package:razorpay_flutter/razorpay_flutter.dart' as rp;
import 'payment_handler.dart';

class PaymentHandlerImpl implements PaymentHandler {
  rp.Razorpay? _razorpay;

  @override
  void init({
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onError,
    required void Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay = rp.Razorpay()
      ..on(rp.Razorpay.EVENT_PAYMENT_SUCCESS, (rp.PaymentSuccessResponse r) {
        onSuccess(PaymentSuccessResponse(r.paymentId, r.orderId, r.signature));
      })
      ..on(rp.Razorpay.EVENT_PAYMENT_ERROR, (rp.PaymentFailureResponse r) {
        onError(PaymentFailureResponse(r.code, r.message));
      })
      ..on(rp.Razorpay.EVENT_EXTERNAL_WALLET, (rp.ExternalWalletResponse r) {
        onExternalWallet(ExternalWalletResponse(r.walletName));
      });
  }

  @override
  void open(Map<String, dynamic> options) {
    _razorpay?.open(options);
  }

  @override
  void clear() {
    _razorpay?.clear();
  }
}
