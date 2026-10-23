import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications used for the optional reading reminder.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const _channel = AndroidNotificationChannel(
    'reading_reminders',
    'Pengingat membaca',
    description: 'Pengingat untuk melanjutkan bacaan di Yomu',
    importance: Importance.defaultImportance,
  );

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_yomu'),
    );
    await _plugin.initialize(settings);
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);
    _initialized = true;
  }

  /// Requests Android 13+ notification permission and sends a visible test
  /// reminder. Returns false when the user rejects the permission.
  Future<bool> showReadingReminder() async {
    if (!isSupported) {
      throw UnsupportedError('Notifikasi tersedia pada aplikasi Android.');
    }
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final allowed = await android?.requestNotificationsPermission();
    if (allowed == false) return false;

    await _plugin.show(
      1001,
      'Lanjutkan bacaanmu',
      'Komik favoritmu menunggu untuk dilanjutkan di Yomu.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_reminders',
          'Pengingat membaca',
          channelDescription: 'Pengingat untuk melanjutkan bacaan di Yomu',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_stat_yomu',
        ),
      ),
    );
    return true;
  }
}
