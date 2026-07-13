import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking_app/main.dart';

void main() {
  testWidgets('boots into onboarding after splash checks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GymBookingApp()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Premium training access'), findsAtLeastNWidgets(1));
    expect(find.text('Next'), findsOneWidget);
  });
}
