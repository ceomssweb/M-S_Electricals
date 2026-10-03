class PaymentSuccessResponse {
  final String? paymentId;
  final String? orderId;
  final String? signature;
  PaymentSuccessResponse(this.paymentId, this.orderId, this.signature);
}

class PaymentFailureResponse {
  final int? code;
  final String? message;
  PaymentFailureResponse(this.code, this.message);
}

class ExternalWalletResponse {
  final String? walletName;
  ExternalWalletResponse(this.walletName);
}

abstract class PaymentHandler {
  void init({
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onError,
    required void Function(ExternalWalletResponse) onExternalWallet,
  });

  void open(Map<String, dynamic> options);

  void clear();
}
