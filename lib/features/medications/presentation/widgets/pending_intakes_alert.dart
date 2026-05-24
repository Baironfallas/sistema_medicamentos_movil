import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/medication_intake.dart';
import '../../services/intake_notification_manager.dart';
import 'info_banner.dart';

class PendingIntakesAlert extends StatefulWidget {
  const PendingIntakesAlert({super.key});

  @override
  State<PendingIntakesAlert> createState() => _PendingIntakesAlertState();
}

class _PendingIntakesAlertState extends State<PendingIntakesAlert> {
  final IntakeNotificationManager _manager = IntakeNotificationManager();
  final Set<int> _updatingIntakeIds = {};

  @override
  void initState() {
    super.initState();
    _manager.start();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _updateIntakeStatus(
    MedicationIntake intake,
    String status,
  ) async {
    setState(() => _updatingIntakeIds.add(intake.id));

    final success = await _manager.updateIntakeStatus(intake, status);
    if (!mounted) {
      return;
    }

    setState(() => _updatingIntakeIds.remove(intake.id));

    if (success) {
      final statusLabel = status == 'taken' ? 'tomada' : 'omitida';
      final medicationName = _displayMedicationName(intake);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('$medicationName marcada como $statusLabel'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: status == 'taken'
                ? AppColors.success
                : AppColors.error,
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar la toma. Intenta de nuevo.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, child) {
        if (!_manager.hasLoadedTodayIntakes) {
          return const Column(
            children: [
              SizedBox(height: 16),
              LinearProgressIndicator(),
            ],
          );
        }

        if (_manager.todayIntakesError != null) {
          return Column(
            children: [
              const SizedBox(height: 16),
              InfoBanner(message: _manager.todayIntakesError!),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _manager.refreshScheduledNotifications,
                      child: const Text('Reintentar'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        final pendingIntakes = _manager.duePendingIntakes;

        if (pendingIntakes.isEmpty) {
          return const SizedBox(height: 8);
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            _buildPendingIntakesCard(pendingIntakes),
          ],
        );
      },
    );
  }

  Widget _buildPendingIntakesCard(List<MedicationIntake> intakes) {
    final firstIntake = intakes.first;
    final isUpdating = _updatingIntakeIds.contains(firstIntake.id);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning.withValues(alpha: 0.12),
            AppColors.warning.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medicamentos por tomar',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${intakes.length} ${intakes.length == 1 ? 'toma pendiente' : 'tomas pendientes'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayMedicationName(firstIntake),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      firstIntake.timeLabel ?? 'Horario pendiente',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (intakes.length > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+ ${intakes.length - 1} mas',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isUpdating
                      ? null
                      : () => _updateIntakeStatus(firstIntake, 'omitted'),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Omitida'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isUpdating
                      ? null
                      : () => _updateIntakeStatus(firstIntake, 'taken'),
                  icon: isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Tomada',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _displayMedicationName(MedicationIntake intake) {
    final name = intake.medicationName.trim();
    if (name.isEmpty || name.startsWith('Toma #')) {
      return 'Medicamento programado';
    }
    return name;
  }
}
