import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking_app/core/constants/app_constants.dart';

void main() {
  test('prefers an explicit API base URL override', () {
    final value = AppConstants.resolveApiBaseUrl(fromEnv: 'https://api.example.com');

    expect(value, 'https://api.example.com');
  });

  test('uses the Android emulator host by default', () {
    final value = AppConstants.resolveApiBaseUrl(isAndroid: true);

    expect(value, 'http://10.0.2.2:8000');
  });

  test('uses localhost for web builds', () {
    final value = AppConstants.resolveApiBaseUrl(isWeb: true);

    expect(value, 'http://localhost:8000');
  });
}
