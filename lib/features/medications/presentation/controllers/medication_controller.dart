import 'package:flutter/foundation.dart';

import '../../data/medication_exception.dart';
import '../../data/medication_service.dart';
import '../../models/medication.dart';
import '../../models/medication_intake.dart';
import '../../services/intake_notification_manager.dart';

class MedicationController extends ChangeNotifier {
  MedicationController({MedicationService? service})
    : _service = service ?? MedicationService();

  final MedicationService _service;

  List<Medication> medications = [];
  List<MedicationIntake> todayIntakes = [];

  bool isLoadingMedications = false;
  bool isLoadingIntakes = false;
  bool isSaving = false;
  bool isDeleting = false;
  bool isConfirming = false;

  String? medicationsError;
  String? intakesError;

  Future<void> loadMedications() async {
    isLoadingMedications = true;
    medicationsError = null;
    notifyListeners();

    try {
      medications = await _service.getMedications();
    } catch (error) {
      medicationsError = _errorMessage(error);
    } finally {
      isLoadingMedications = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayIntakes() async {
    isLoadingIntakes = true;
    intakesError = null;
    notifyListeners();

    try {
      todayIntakes = await _service.getTodayIntakes();
    } catch (error) {
      intakesError = _errorMessage(error);
    } finally {
      isLoadingIntakes = false;
      notifyListeners();
    }
  }

  Future<bool> createMedication(MedicationDraft draft) async {
    isSaving = true;
    medicationsError = null;
    notifyListeners();

    try {
      await _service.createMedication(draft);
      await IntakeNotificationManager().refreshScheduledNotifications();
      await loadMedications();
      return true;
    } catch (error) {
      medicationsError = _errorMessage(error);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateMedication(int id, MedicationDraft draft) async {
    isSaving = true;
    medicationsError = null;
    notifyListeners();

    try {
      await _service.updateMedication(id, draft);
      await IntakeNotificationManager().refreshScheduledNotifications();
      await loadMedications();
      return true;
    } catch (error) {
      medicationsError = _errorMessage(error);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMedication(int id) async {
    isDeleting = true;
    medicationsError = null;
    notifyListeners();

    try {
      await _service.deleteMedication(id);
      await IntakeNotificationManager().refreshScheduledNotifications();
      await loadMedications();
      return true;
    } catch (error) {
      medicationsError = _errorMessage(error);
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  Future<bool> confirmIntake(int intakeId) async {
    return updateIntakeStatus(intakeId, 'taken');
  }

  Future<bool> omitIntake(int intakeId) async {
    return updateIntakeStatus(intakeId, 'omitted');
  }

  Future<bool> updateIntakeStatus(int intakeId, String status) async {
    isConfirming = true;
    intakesError = null;
    notifyListeners();

    try {
      await _service.confirmIntake(intakeId, status: status);
      await IntakeNotificationManager().refreshScheduledNotifications();
      await loadTodayIntakes();
      return true;
    } catch (error) {
      intakesError = _errorMessage(error);
      return false;
    } finally {
      isConfirming = false;
      notifyListeners();
    }
  }

  String _errorMessage(Object error) {
    if (error is MedicationException) {
      return error.message;
    }
    return 'Ocurrio un error inesperado.';
  }
}
