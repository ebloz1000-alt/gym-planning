class AppConstants {
  const AppConstants._();

  static const appName = 'Gym Equipment & Trainer Booking Management Mobile Application';
  static const appVersion = '1.0.0';
  static const supportEmail = 'support@fitflow.local';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  static const supportPhone = '+254 700 000 111';
  static const currency = 'KES';

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
