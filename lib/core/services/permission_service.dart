import 'package:permission_handler/permission_handler.dart';

// ignore_for_file: avoid_classes_with_only_static_members

/// Centralized permission handling with user-friendly messages.
class PermissionService {
  PermissionService._();

  /// Request storage permission. Returns `true` if granted.
  static Future<bool> requestStorage() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Request camera permission. Returns `true` if granted.
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check if storage is granted without requesting.
  static Future<bool> hasStorage() => Permission.storage.isGranted;

  /// Check if camera is granted without requesting.
  static Future<bool> hasCamera() => Permission.camera.isGranted;

  /// Returns a user-friendly message for a denied permission.
  static String deniedMessage(String permissionName) =>
      '$permissionName permission denied. Please grant access in your device Settings.';
}
