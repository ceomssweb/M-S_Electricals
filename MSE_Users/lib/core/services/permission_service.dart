import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralized service handling location and notification permission prompts.
class PermissionService {
  /// Request location and notification permissions proactively on startup/booking
  static Future<void> requestInitialPermissions() async {
    if (kIsWeb) return;
    try {
      final statuses = await [
        Permission.location,
        Permission.notification,
      ].request();

      debugPrint('Location permission status: ${statuses[Permission.location]}');
      debugPrint('Notification permission status: ${statuses[Permission.notification]}');
    } catch (e) {
      debugPrint('Error requesting initial permissions: $e');
    }
  }

  /// Request location permission specifically for auto-fetching current address
  static Future<bool> requestLocationPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.location.request();
      return status.isGranted || status.isLimited;
    } catch (_) {
      return true;
    }
  }
}
