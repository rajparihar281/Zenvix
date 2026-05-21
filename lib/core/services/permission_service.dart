import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();

  static Future<bool> requestStorage() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> hasStorage() => Permission.storage.isGranted;

  static Future<bool> hasCamera() => Permission.camera.isGranted;

  static String deniedMessage(String permissionName) =>
      '$permissionName permission denied. Please grant'
      ' access in your device'
      ' Settings.';
}
