import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/services/local_notification_service.dart';
import '../data/medication_service.dart';
import '../models/medication.dart';
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
  Timer? _nextDueTimer;
  final Set<int> _notifiedNowIntakeIds = {};
  final Set<int> _shownInAppIntakeIds = {};
  final Set<int> _duePendingIntakeIds = {};
  final Map<int, MedicationIntake> _inAppAlertsById = {};
  List<MedicationIntake> _todayIntakes = [];
  String? _todayIntakesError;
  bool _hasLoadedTodayIntakes = false;
  bool _isRunning = false;

  static const int _mobileSyncIntervalHours = 1;
  static const int _inAppSyncIntervalSeconds = 30;
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

  List<MedicationIntake> get todayIntakes => List.unmodifiable(_todayIntakes);

  List<MedicationIntake> get duePendingIntakes {
    return _todayIntakes
        .where((intake) => _duePendingIntakeIds.contains(intake.id))
        .toList();
  }

  String? get todayIntakesError => _todayIntakesError;

  bool get hasLoadedTodayIntakes => _hasLoadedTodayIntakes;

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
    _nextDueTimer?.cancel();
    _nextDueTimer = null;
    _isRunning = false;
    _notifiedNowIntakeIds.clear();
    _shownInAppIntakeIds.clear();
    _duePendingIntakeIds.clear();
    _clearInAppAlerts();
    debugPrint(
      '[IntakeNotificationManager] Deteniendo gestor de notificaciones',
    );
  }

  Future<void> refreshScheduledNotifications() async {
    try {
      final todayIntakes = await _enrichIntakesWithMedicationDetails(
        await _medicationService.getTodayIntakes(),
      );
      final now = DateTime.now();
      final intakesChanged = _setTodayIntakes(todayIntakes, error: null);
      final dueChanged = _updateDuePendingIntakes(todayIntakes, now);
      _scheduleNextDueRefresh(todayIntakes, now);

      _removeResolvedInAppAlerts(todayIntakes, now);

      if (usesInAppAlerts) {
        _syncInAppAlerts(todayIntakes, now);
        if (intakesChanged || dueChanged) {
          notifyListeners();
        }
        return;
      }

      await _syncSystemNotifications(todayIntakes, now);
      if (intakesChanged || dueChanged) {
        notifyListeners();
      }
    } catch (error) {
      final message = error.toString();
      final changed =
          _todayIntakesError != message || !_hasLoadedTodayIntakes;
      _todayIntakesError = message;
      _hasLoadedTodayIntakes = true;
      if (changed) {
        notifyListeners();
      }
      debugPrint(
        '[IntakeNotificationManager] Error sincronizando notificaciones: $error',
      );
    }
  }

  Future<List<MedicationIntake>> _enrichIntakesWithMedicationDetails(
    List<MedicationIntake> intakes,
  ) async {
    final needsEnrichment = intakes.any(
      (intake) =>
          intake.dosage == null ||
          intake.dosage!.trim().isEmpty ||
          intake.quantityPerIntake == null,
    );

    if (!needsEnrichment) {
      return intakes;
    }

    final medications = await _medicationService.getMedications();
    final medicationById = <int, Medication>{
      for (final medication in medications) medication.id: medication,
    };
    final medicationByName = <String, Medication>{
      for (final medication in medications)
        _normalizeMedicationKey(medication.name): medication,
    };

    return intakes.map((intake) {
      final medication = intake.medicationId != null
          ? medicationById[intake.medicationId]
          : null;
      final fallbackMedication = medication ??
          medicationByName[_normalizeMedicationKey(intake.medicationName)];
      final resolvedMedication = fallbackMedication;
      if (resolvedMedication == null) {
        return intake;
      }

      return intake.copyWith(
        dosage: intake.dosage ?? resolvedMedication.dose,
        quantityPerIntake:
            intake.quantityPerIntake ?? resolvedMedication.quantityPerIntake.toInt(),
      );
    }).toList();
  }

  String _normalizeMedicationKey(String value) {
    return value.trim().toLowerCase();
  }

  Future<bool> updateIntakeStatus(MedicationIntake intake, String status) async {
    if (status != 'taken' && status != 'omitted') {
      return false;
    }

    try {
      await _medicationService.confirmIntake(intake.id, status: status);
      _todayIntakes = _todayIntakes
          .map(
            (item) => item.id == intake.id
                ? item.copyWith(status: status, isConfirmed: true)
                : item,
          )
          .toList();
      _duePendingIntakeIds.remove(intake.id);
      _inAppAlertsById.remove(intake.id);
      _shownInAppIntakeIds.add(intake.id);
      _notifiedNowIntakeIds.add(intake.id);
      await _notificationService.cancelNotification(intake.id);
      notifyListeners();
      await refreshScheduledNotifications();
      return true;
    } catch (error) {
      debugPrint(
        '[IntakeNotificationManager] Error actualizando toma: $error',
      );
      return false;
    }
  }

  Future<bool> respondToInAppAlert(
    MedicationIntake intake,
    String status,
  ) async {
    return updateIntakeStatus(intake, status);
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

      if (scheduledDateTime.isAfter(now)) {
        if (!pendingNotificationIds.contains(intake.id)) {
          await _scheduleNotification(intake, scheduledDateTime);
        }
        continue;
      }

      if (!_notifiedNowIntakeIds.contains(intake.id)) {
        await _showNotification(intake);
        _notifiedNowIntakeIds.add(intake.id);
      }
    }
  }

  void _syncInAppAlerts(List<MedicationIntake> todayIntakes, DateTime now) {
    var changed = false;

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

      if (_shownInAppIntakeIds.contains(intake.id) ||
          _inAppAlertsById.containsKey(intake.id)) {
        continue;
      }

      if (scheduledDateTime.isAfter(now)) {
        continue;
      }

      _inAppAlertsById[intake.id] = intake;
      _shownInAppIntakeIds.add(intake.id);
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void _removeResolvedInAppAlerts(
    List<MedicationIntake> todayIntakes,
    DateTime now,
  ) {
    if (_inAppAlertsById.isEmpty && _shownInAppIntakeIds.isEmpty) {
      return;
    }

    final duePendingIds = todayIntakes
        .where((intake) => _isPendingDue(intake, now))
        .map((intake) => intake.id)
        .toSet();

    final beforeCount = _inAppAlertsById.length;
    final beforeShownCount = _shownInAppIntakeIds.length;
    _inAppAlertsById.removeWhere((id, _) => !duePendingIds.contains(id));
    _shownInAppIntakeIds.removeWhere((id) => !duePendingIds.contains(id));

    if (_inAppAlertsById.length != beforeCount ||
        _shownInAppIntakeIds.length != beforeShownCount) {
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

  bool _updateDuePendingIntakes(
    List<MedicationIntake> intakes,
    DateTime now,
  ) {
    final nextDueIds = intakes
        .where((intake) => _isPendingDue(intake, now))
        .map((intake) => intake.id)
        .toSet();

    if (setEquals(_duePendingIntakeIds, nextDueIds)) {
      return false;
    }

    _duePendingIntakeIds
      ..clear()
      ..addAll(nextDueIds);
    return true;
  }

  void _scheduleNextDueRefresh(
    List<MedicationIntake> intakes,
    DateTime now,
  ) {
    _nextDueTimer?.cancel();
    _nextDueTimer = null;

    DateTime? nextDueTime;
    for (final intake in intakes) {
      if (intake.status.toLowerCase() != 'pending') {
        continue;
      }

      final scheduledDateTime = _scheduledDateTimeFor(intake);
      if (scheduledDateTime == null || !scheduledDateTime.isAfter(now)) {
        continue;
      }

      if (nextDueTime == null || scheduledDateTime.isBefore(nextDueTime)) {
        nextDueTime = scheduledDateTime;
      }
    }

    if (nextDueTime == null) {
      return;
    }

    final delay = nextDueTime.difference(DateTime.now());
    _nextDueTimer = Timer(
      (delay.isNegative ? Duration.zero : delay) +
          const Duration(milliseconds: 200),
      refreshScheduledNotifications,
    );
  }

  bool _setTodayIntakes(List<MedicationIntake> intakes, {String? error}) {
    final changed =
        !_hasLoadedTodayIntakes ||
        _todayIntakesError != error ||
        !_sameIntakeList(_todayIntakes, intakes);

    _todayIntakes = List<MedicationIntake>.from(intakes);
    _todayIntakesError = error;
    _hasLoadedTodayIntakes = true;

    return changed;
  }

  bool _sameIntakeList(
    List<MedicationIntake> current,
    List<MedicationIntake> next,
  ) {
    if (current.length != next.length) {
      return false;
    }

    for (var index = 0; index < current.length; index += 1) {
      final left = current[index];
      final right = next[index];
      if (left.id != right.id ||
          left.status != right.status ||
          left.scheduledAt != right.scheduledAt ||
          left.medicationName != right.medicationName ||
          left.timeLabel != right.timeLabel) {
        return false;
      }
    }

    return true;
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
        dateLabel: intake.dateLabel,
        quantityTaken: intake.quantityTaken,
        remainingPills: intake.remainingPills,
        quantityPerIntake: intake.quantityPerIntake,
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
        dateLabel: intake.dateLabel,
        quantityTaken: intake.quantityTaken,
        remainingPills: intake.remainingPills,
        quantityPerIntake: intake.quantityPerIntake,
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

  bool _isPendingDue(MedicationIntake intake, DateTime now) {
    if (intake.status.toLowerCase() != 'pending') {
      return false;
    }

    final scheduledDateTime = _scheduledDateTimeFor(intake);
    if (scheduledDateTime == null) {
      return false;
    }

    return !now.isBefore(scheduledDateTime);
  }

  DateTime? _scheduledDateTimeFor(MedicationIntake intake) {
    final scheduledDateTime = intake.scheduledDateTime;
    if (scheduledDateTime == null && intake.scheduledAt != null) {
      debugPrint(
        '[IntakeNotificationManager] Error parseando scheduledAt: ${intake.scheduledAt}',
      );
    }
    return scheduledDateTime;
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
