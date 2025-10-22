import 'package:flutter_test/flutter_test.dart';
import 'package:easy_git/app.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('App loads successfully', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    expect(find.text('Easy Git'), findsOneWidget);
  });
}
