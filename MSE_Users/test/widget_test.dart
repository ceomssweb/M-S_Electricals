import 'package:flutter_test/flutter_test.dart';
import 'package:rasi_customer/main.dart';

void main() {
  testWidgets('Customer app boots without crashing', (tester) async {
    await tester.pumpWidget(const RasiCustomerApp());
    expect(find.byType(RasiCustomerApp), findsOneWidget);
  });
}
