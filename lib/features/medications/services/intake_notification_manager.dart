import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/services/local_notification_service.dart';
import '../data/medication_service.dart';
import '../models/medication_intake.dart';

class IntakeNotificationManager {
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
  final Set<int> _notifiedNowIntakeIds = {};
  bool _isRunning = false;

  static const int _syncIntervalHours = 1;
  static const int _notificationAdvanceMinutes = 0;

  Future<void> start() async {
    if (_isRunning) return;

    _isRunning = true;
    debugPrint(
      '[IntakeNotificationManager] Iniciando gestor de notificaciones',
    );

    await refreshScheduledNotifications();

    _syncTimer = Timer.periodic(
      Duration(hours: _syncIntervalHours),
      (_) => refreshScheduledNotifications(),
    );
  }

  Future<void> stop() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isRunning = false;
    debugPrint(
      '[IntakeNotificationManager] Deteniendo gestor de notificaciones',
    );
  }

  Future<void> refreshScheduledNotifications() async {
    try {
      final todayIntakes = await _medicationService.getTodayIntakes();
      final now = DateTime.now();
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

        final scheduledAt = intake.scheduledAt;
        if (scheduledAt == null) {
          continue;
        }

        final scheduledDateTime = _parseScheduledTime(scheduledAt);
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
    } catch (error) {
      debugPrint(
        '[IntakeNotificationManager] Error sincronizando notificaciones: $error',
      );
    }
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

  DateTime? _parseScheduledTime(String scheduledAt) {
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
  }

  bool isIntakeNotified(int intakeId) {
    return _notifiedNowIntakeIds.contains(intakeId);
  }

  bool get isRunning => _isRunning;
}
