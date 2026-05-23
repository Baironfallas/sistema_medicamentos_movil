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

  Timer? _pollingTimer;
  final Set<int> _notifiedIntakeIds = {};
  bool _isRunning = false;

  // Intervalo de verificación en segundos (cada 30 segundos)
  static const int _pollingIntervalSeconds = 30;

  // Minutos antes de la hora programada para mostrar la notificación
  static const int _notificationAdvanceMinutes = 0;

  Future<void> start() async {
    if (_isRunning) return;

    _isRunning = true;
    debugPrint(
      '[IntakeNotificationManager] Iniciando gestor de notificaciones',
    );

    // Ejecutar la primera verificación inmediatamente
    await _checkAndNotifyPendingIntakes();

    // Luego ejecutar cada X segundos
    _pollingTimer = Timer.periodic(
      Duration(seconds: _pollingIntervalSeconds),
      (_) => _checkAndNotifyPendingIntakes(),
    );
  }

  Future<void> stop() async {
    _pollingTimer?.cancel();
    _isRunning = false;
    debugPrint(
      '[IntakeNotificationManager] Deteniendo gestor de notificaciones',
    );
  }

  Future<void> _checkAndNotifyPendingIntakes() async {
    try {
      final List<MedicationIntake> todayIntakes = await _medicationService
          .getTodayIntakes();

      final now = DateTime.now();

      for (final intake in todayIntakes) {
        // Solo procesar tomas pendientes
        if (intake.status.toLowerCase() != 'pending') {
          continue;
        }

        // Si ya se notificó, saltar
        if (_notifiedIntakeIds.contains(intake.id)) {
          continue;
        }

        // Parsear la hora programada (skip si scheduledAt es null)
        if (intake.scheduledAt == null) {
          continue;
        }

        final scheduledDateTime = _parseScheduledTime(intake.scheduledAt!);
        if (scheduledDateTime == null) {
          continue;
        }

        // Calcular cuándo mostrar la notificación
        final notificationTime = scheduledDateTime.subtract(
          Duration(minutes: _notificationAdvanceMinutes),
        );

        // Si es hora de notificar (dentro de una ventana de 2 minutos)
        if (now.isAfter(notificationTime) &&
            now.isBefore(scheduledDateTime.add(const Duration(minutes: 2)))) {
          await _showNotification(intake);
          _notifiedIntakeIds.add(intake.id);
        }
      }
    } catch (error) {
      debugPrint('[IntakeNotificationManager] Error verificando tomas: $error');
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
        '[IntakeNotificationManager] Notificación mostrada: ${intake.medicationName} a las $timeLabel',
      );
    } catch (error) {
      debugPrint(
        '[IntakeNotificationManager] Error mostrando notificación: $error',
      );
    }
  }

  /// Parsea la hora programada desde el string de la base de datos
  /// Formato esperado: 'YYYY-MM-DD HH:MM:SS'
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

  /// Limpiar intakes notificadas (útil cuando se descarga nueva lista)
  void clearNotifiedIntakes() {
    _notifiedIntakeIds.clear();
  }

  /// Verificar si una toma ya fue notificada
  bool isIntakeNotified(int intakeId) {
    return _notifiedIntakeIds.contains(intakeId);
  }

  bool get isRunning => _isRunning;
}
