import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/medications/data/medication_service.dart';

const String _medicationTakenActionId = 'medication_taken';
const String _medicationOmittedActionId = 'medication_omitted';
const String _medicationIntakeCategoryId = 'medication_intake_actions';

@pragma('vm:entry-point')
void medicationNotificationBackgroundHandler(NotificationResponse response) {
  LocalNotificationService.handleNotificationResponse(response);
}

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

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          notificationCategories: [
            DarwinNotificationCategory(
              _medicationIntakeCategoryId,
              actions: [
                DarwinNotificationAction.plain(
                  _medicationTakenActionId,
                  'Tomada',
                  options: {DarwinNotificationActionOption.foreground},
                ),
                DarwinNotificationAction.plain(
                  _medicationOmittedActionId,
                  'Omitida',
                  options: {
                    DarwinNotificationActionOption.destructive,
                    DarwinNotificationActionOption.foreground,
                  },
                ),
              ],
            ),
          ],
        );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
      onDidReceiveBackgroundNotificationResponse:
          medicationNotificationBackgroundHandler,
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
          actions: const [
            AndroidNotificationAction(
              _medicationTakenActionId,
              'Tomada',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              _medicationOmittedActionId,
              'Omitida',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        );

    final DarwinNotificationDetails iosDetails =
        const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _medicationIntakeCategoryId,
        );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final String title = 'Hora de tomar medicamento';
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
    await handleNotificationResponse(response);
  }

  static Future<void> handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final actionStatus = _statusFromAction(response.actionId);
    if (actionStatus == null) {
      return;
    }

    final intakeId = _intakeIdFromPayload(response.payload);
    if (intakeId == null) {
      debugPrint(
        '[LocalNotificationService] Payload invalido: ${response.payload}',
      );
      return;
    }

    try {
      await MedicationService().confirmIntake(intakeId, status: actionStatus);
      debugPrint(
        '[LocalNotificationService] Toma $intakeId marcada como $actionStatus',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[LocalNotificationService] Error actualizando toma $intakeId: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static String? _statusFromAction(String? actionId) {
    return switch (actionId) {
      _medicationTakenActionId => 'taken',
      _medicationOmittedActionId => 'omitted',
      _ => null,
    };
  }

  static int? _intakeIdFromPayload(String? payload) {
    if (payload == null || !payload.startsWith('intake_')) {
      return null;
    }
    return int.tryParse(payload.substring('intake_'.length));
  }
}
