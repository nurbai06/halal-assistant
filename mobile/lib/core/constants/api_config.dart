import 'package:flutter/foundation.dart';

/// The one place that decides where the FastAPI backend lives.
///
/// Override it at build time for a physical device (use the Mac's address on
/// the local network) or a deployed server:
///
///     flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
abstract final class ApiConfig {
  static const _override = String.fromEnvironment('API_BASE_URL');

  static const port = 8000;

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    // The Android emulator reaches the host machine through 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$port';
    }
    // The iOS simulator and the web build share the host's localhost.
    return 'http://localhost:$port';
  }

  static const connectTimeout = Duration(seconds: 8);
  static const receiveTimeout = Duration(seconds: 20);
}
