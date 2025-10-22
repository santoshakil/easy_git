import 'package:flutter_test/flutter_test.dart';
import 'package:easy_git/app.dart';
import 'package:easy_git/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  testWidgets('App can load', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    expect(find.text('Easy Git'), findsOneWidget);
  });
}
