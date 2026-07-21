import 'package:flutter/foundation.dart';

class AppConstants {
  const AppConstants._();

  static const appName = 'Gym Equipment & Trainer Booking Management Mobile Application';
  static const appVersion = '1.0.0';
  static const supportEmail = 'support@fitflow.local';
  static const supportPhone = '+254 700 000 111';
  static const currency = 'KES';

  static String get apiBaseUrl => resolveApiBaseUrl();

  static String resolveApiBaseUrl({
    String? fromEnv,
    bool? isAndroid,
    bool? isWeb,
  }) {
    final explicitUrl = fromEnv ?? const String.fromEnvironment('API_BASE_URL');
    if (explicitUrl.isNotEmpty) {
      return explicitUrl;
    }

    final web = isWeb ?? kIsWeb;
    if (web) {
      return 'http://localhost:8000';
    }

    final android = isAndroid ?? defaultTargetPlatform == TargetPlatform.android;
    if (android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static const timeSlots = <String>[
    '06:00',
    '07:00',
    '08:00',
    '10:00',
    '12:00',
    '14:00',
    '16:00',
    '18:00',
    '20:00',
  ];

  static const equipmentCategories = <String>[
    'All',
    'Cardio',
    'Strength',
    'Functional',
    'Recovery',
  ];
}
