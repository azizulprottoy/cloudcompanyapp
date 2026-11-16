/// Build-time configuration. Point the app at a local server with:
///   flutter run --dart-define=API_URL=http://10.0.2.2:5050 --dart-define=WS_URL=ws://10.0.2.2:5050
/// (10.0.2.2 is the host machine from the Android emulator.)
class AppConstants {
  AppConstants._();

  static const String appName = 'Cloud Company';

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:5050',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://10.0.2.2:5050',
  );

  static const String siteUrl = 'https://cloudcompany.cc';
  static const String supportEmail = 'support@cloudcompany.cc';
  static const String whatsappNumber = '8801841911105';
}
