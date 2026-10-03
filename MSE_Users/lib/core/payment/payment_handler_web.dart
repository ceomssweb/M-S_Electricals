import 'package:flutter/foundation.dart';
import 'payment_handler.dart';

class PaymentHandlerImpl implements PaymentHandler {
  void Function(PaymentSuccessResponse)? _onSuccess;

  @override
  void init({
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onError,
    required void Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _onSuccess = onSuccess;
  }

  @override
  void open(Map<String, dynamic> options) {
    debugPrint('Web payment initiated for order: ${options['order_id']}');
    final orderId = options['order_id'] as String? ?? 'order_web';
    Future.delayed(const Duration(seconds: 1), () {
      _onSuccess?.call(
        PaymentSuccessResponse('pay_web_${DateTime.now().millisecondsSinceEpoch}', orderId, 'sig_web'),
      );
    });
  }

  @override
  void clear() {
    _onSuccess = null;
  }
}
