import 'package:flutter_test/flutter_test.dart';
import 'package:maternal_vault/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaternalVaultApp());
    await tester.pump(const Duration(milliseconds: 1600));

    // The splash screen should show the app name and tagline.
    expect(find.text('Maternal Vault'), findsOneWidget);
    expect(find.text('Secure today, stronger tomorrow'), findsOneWidget);

    // Let the minimum-duration timer elapse so none is pending at teardown.
    await tester.pump(const Duration(seconds: 3));
  });
}
