import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexam/main.dart';

void main() {
  testWidgets('Rexam app boots with Brand Wordmark and SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RexamApp(),
      ),
    );

    // Verify REXAM wordmark renders
    expect(find.text('REXAM'), findsOneWidget);
    expect(find.text('Indian Examination & Opportunity Intelligence'), findsOneWidget);

    // Let the splash transition timer elapse cleanly
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });
}
