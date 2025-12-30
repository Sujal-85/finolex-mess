import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  static const String _notifSoftAskKey = 'notif_soft_ask_shown';

  /// Returns true if notification permission is granted.
  Future<bool> isNotificationGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Checks if we should show the "soft ask" dialog.
  Future<bool> shouldShowSoftAsk() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return false;

    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(_notifSoftAskKey) ?? false;
    return !alreadyShown;
  }

  /// Marks the soft ask as shown.
  Future<void> markSoftAskAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifSoftAskKey, true);
  }

  /// Requests the actual system permission.
  Future<PermissionStatus> requestNotification() async {
    return await Permission.notification.request();
  }
}
