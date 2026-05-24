import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/services/local_notification_service.dart';
import '../data/medication_service.dart';
import '../models/medication_intake.dart';

enum NotificationDeliveryMode { system, inApp }

class IntakeNotificationManager extends ChangeNotifier {
  static final IntakeNotificationManager _instance =
      IntakeNotificationManager._internal();

  factory IntakeNotificationManager() {
    return _instance;
  }

  IntakeNotificationManager._internal();

  final MedicationService _medicationService = MedicationService();
  final LocalNotificationService _notificationService =
      LocalNotificationService();

  Timer? _syncTimer;
  Timer? _nextInAppTimer;
  final Set<int> _notifiedNowIntakeIds = {};
  final Set<int> _shownInAppIntakeIds = {};
  final Map<int, MedicationIntake> _inAppAlertsById = {};
  bool _isRunning = false;

  static const int _mobileSyncIntervalHours = 1;
  static const int _inAppSyncIntervalSeconds = 30;
  static const int _notificationAdvanceMinutes = 0;

  NotificationDeliveryMode get deliveryMode {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return NotificationDeliveryMode.system;
    }

    return NotificationDeliveryMode.inApp;
  }

  bool get usesInAppAlerts => deliveryMode == NotificationDeliveryMode.inApp;

  List<MedicationIntake> get inAppAlerts =>
      List.unmodifiable(_inAppAlertsById.values);

  Future<void> start() async {
    if (_isRunning) return;

    _isRunning = true;
    debugPrint(
      '[IntakeNotificationManager] Iniciando gestor de notificaciones',
    );

    await refreshScheduledNotifications();

    final interval = usesInAppAlerts
        ? const Duration(seconds: _inAppSyncIntervalSeconds)
        : const Duration(hours: _mobileSyncIntervalHours);

    _syncTimer = Timer.periodic(
      interval,
      (_) => refreshScheduledNotifications(),
    );
  }

  Future<void> stop() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    _nextInAppTimer?.cancel();
    _nextInAppTimer = null;
    _isRunning = false;
    _notifiedNowIntakeIds.clear();
    _shownInAppIntakeIds.clear();
    _clearInAppAlerts();
    debugPrint(
      '[IntakeNotificationManager] Deteniendo gestor de notificaciones',
    );
  }

  Future<void> refreshScheduledNotifications() async {
    try {
      final todayIntakes = await _medicationService.getTodayIntakes();
      final now = DateTime.now();

      _removeResolvedInAppAlerts(todayIntakes);

      if (usesInAppAlerts) {
        _syncInAppAlerts(todayIntakes, now);
        return;
      }

      await _syncSystemNotifications(todayIntakes, now);
    } catch (error) {
      debugPrint(
        '[IntakeNotificationManager] Error sincronizando notificaciones: $error',
      );
    }
  }

  Future<bool> respondToInAppAlert(
    MedicationIntake intake,
    String status,
  ) async {
    if (status != 'taken' && status != 'omitted') {
      return false;
    }

    try {
      await _medicationService.confirmIntake(intake.id, status: status);
      _inAppAlertsById.remove(intake.id);
      _shownInAppIntakeIds.add(intake.id);
      _notifiedNowIntakeIds.add(intake.id);
      await _notificationService.cancelNotification(intake.id);
      notifyListeners();
      await refreshScheduledNotifications();
      return true;
    } catch (error) {
      debugPrint(
        '[IntakeNotificationManager] Error respondiendo alerta interna: $error',
      );
      return false;
    }
  }

  Future<void> _syncSystemNotifications(
    List<MedicationIntake> todayIntakes,
    DateTime now,
  ) async {
    final pendingNotificationIds = await _notificationService
        .pendingMedicationReminderIds();
    final pendingIntakeIds = todayIntakes
        .where((intake) => intake.status.toLowerCase() == 'pending')
        .map((intake) => intake.id)
        .toSet();

    for (final notificationId in pendingNotificationIds) {
      if (!pendingIntakeIds.contains(notificationId)) {
        await _notificationService.cancelNotification(notificationId);
      }
    }

    for (final intake in todayIntakes) {
      if (intake.status.toLowerCase() != 'pending') {
        await _notificationService.cancelNotification(intake.id);
        continue;
      }

      final scheduledDateTime = _scheduledDateTimeFor(intake);
      if (scheduledDateTime == null) {
        continue;
      }

      final notificationTime = scheduledDateTime.subtract(
        Duration(minutes: _notificationAdvanceMinutes),
      );
      final notificationWindowEnd = scheduledDateTime.add(
        const Duration(minutes: 2),
      );

      if (notificationTime.isAfter(now)) {
        if (!pendingNotificationIds.contains(intake.id)) {
          await _scheduleNotification(intake, notificationTime);
        }
        continue;
      }

      if (now.isBefore(notificationWindowEnd) &&
          !_notifiedNowIntakeIds.contains(intake.id)) {
        await _showNotification(intake);
        _notifiedNowIntakeIds.add(intake.id);
      }
    }
  }

  void _syncInAppAlerts(List<MedicationIntake> todayIntakes, DateTime now) {
    var changed = false;
    DateTime? nextNotificationTime;

    for (final intake in todayIntakes) {
      if (intake.status.toLowerCase() != 'pending') {
        if (_inAppAlertsById.remove(intake.id) != null) {
          changed = true;
        }
        continue;
      }

      final scheduledDateTime = _scheduledDateTimeFor(intake);
      if (scheduledDateTime == null) {
        continue;
      }

      final notificationTime = scheduledDateTime.subtract(
        Duration(minutes: _notificationAdvanceMinutes),
      );

      if (_shownInAppIntakeIds.contains(intake.id) ||
          _inAppAlertsById.containsKey(intake.id)) {
        continue;
      }

      if (now.isBefore(notificationTime)) {
        if (nextNotificationTime == null ||
            notificationTime.isBefore(nextNotificationTime)) {
          nextNotificationTime = notificationTime;
        }
        continue;
      }

      _inAppAlertsById[intake.id] = intake;
      _shownInAppIntakeIds.add(intake.id);
      changed = true;
    }

    _scheduleNextInAppRefresh(nextNotificationTime);

    if (changed) {
      notifyListeners();
    }
  }

  void _scheduleNextInAppRefresh(DateTime? nextNotificationTime) {
    _nextInAppTimer?.cancel();
    _nextInAppTimer = null;

    if (nextNotificationTime == null || !usesInAppAlerts) {
      return;
    }

    final delay = nextNotificationTime.difference(DateTime.now());
    _nextInAppTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      refreshScheduledNotifications,
    );
  }

  void _removeResolvedInAppAlerts(List<MedicationIntake> todayIntakes) {
    if (_inAppAlertsById.isEmpty) {
      return;
    }

    final pendingIds = todayIntakes
        .where((intake) => intake.status.toLowerCase() == 'pending')
        .map((intake) => intake.id)
        .toSet();

    final beforeCount = _inAppAlertsById.length;
    _inAppAlertsById.removeWhere((id, _) => !pendingIds.contains(id));

    if (_inAppAlertsById.length != beforeCount) {
      notifyListeners();
    }
  }

  void _clearInAppAlerts() {
    if (_inAppAlertsById.isEmpty) {
      return;
    }

    _inAppAlertsById.clear();
    notifyListeners();
  }

  Future<void> _scheduleNotification(
    MedicationIntake intake,
    DateTime notificationTime,
  ) async {
    try {
      final timeLabel = intake.timeLabel ?? 'Hora programada';

      await _notificationService.scheduleMedicationReminder(
        id: intake.id,
        medicationName: intake.medicationName,
        scheduledAt: notificationTime,
        scheduledTime: timeLabel,
        dosage: intake.dosage,
      );

      debugPrint(
        '[IntakeNotificationManager] Notificacion agendada: ${intake.medicationName} a las $timeLabel',
      );
    } catch (error) {
      debugPrint(
        '[IntakeNotificationManager] Error agendando notificacion: $error',
      );
    }
  }

  Future<void> _showNotification(MedicationIntake intake) async {
    try {
      final timeLabel = intake.timeLabel ?? 'Hora programada';

      await _notificationService.showMedicationReminder(
        id: intake.id,
        medicationName: intake.medicationName,
        scheduledTime: timeLabel,
        dosage: intake.dosage,
      );

      debugPrint(
        '[IntakeNotificationManager] Notificacion mostrada: ${intake.medicationName} a las $timeLabel',
      );
    } catch (error) {
      debugPrint(
        '[IntakeNotificationManager] Error mostrando notificacion: $error',
      );
    }
  }

  DateTime? _scheduledDateTimeFor(MedicationIntake intake) {
    final scheduledAt = intake.scheduledAt;
    if (scheduledAt == null) {
      return null;
    }

    try {
      return DateTime.parse(scheduledAt);
    } catch (error) {
      debugPrint(
        '[IntakeNotificationManager] Error parseando scheduledAt: $scheduledAt - $error',
      );
      return null;
    }
  }

  void clearNotifiedIntakes() {
    _notifiedNowIntakeIds.clear();
    _shownInAppIntakeIds.clear();
    _clearInAppAlerts();
  }

  bool isIntakeNotified(int intakeId) {
    return _notifiedNowIntakeIds.contains(intakeId) ||
        _shownInAppIntakeIds.contains(intakeId);
  }

  bool get isRunning => _isRunning;
}
