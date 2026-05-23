import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() {
    return _instance;
  }

  LocalNotificationService._internal();

  late final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    // Inicialización Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Inicialización iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );

    _isInitialized = true;
  }

  Future<void> showMedicationReminder({
    required int id,
    required String medicationName,
    required String scheduledTime,
    String? dosage,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'medication_reminders',
          'Recordatorios de Medicamentos',
          channelDescription:
              'Notificaciones para recordar tomar medicamentos a tiempo',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
        );

    final DarwinNotificationDetails iosDetails =
        const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final String title = '💊 Hora de tomar medicamento';
    final String body =
        '$medicationName'
        '${dosage != null ? ' - $dosage' : ''}'
        '\n'
        'Programado: $scheduledTime';

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: 'intake_$id',
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> _onSelectNotification(
    NotificationResponse response,
  ) async {
    // Manejador cuando el usuario toca la notificación
  }
}
