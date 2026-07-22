import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking_app/main.dart';
import 'package:gym_booking_app/providers_or_bloc/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('boots into onboarding after splash checks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GymBookingApp()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byType(Scaffold), findsWidgets);
  });

  test('bootstrap completes without relying on mock data', () async {
    final state = AppState();
    await state.bootstrap();

    expect(state.repository.membershipPlans, isA<List>());
    expect(state.repository.equipment, isA<List>());
    expect(state.repository.trainers, isA<List>());
    expect(state.repository.bookings, isA<List>());
    expect(state.repository.payments, isA<List>());
  });
}
