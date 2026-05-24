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
        color: AppColors.warning.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.22),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medicamentos por tomar',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayMedicationName(firstIntake),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          color: AppColors.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          firstIntake.timeLabel ?? 'Horario pendiente',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (intakes.length > 1) ...[
                          const SizedBox(width: 8),
                          Text(
                            '+${intakes.length - 1} mas',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  onPressed: isUpdating
                      ? null
                      : () => _updateIntakeStatus(firstIntake, 'omitted'),
                  icon: const Icon(Icons.cancel_outlined, size: 17),
                  label: const Text(
                    'Omitida',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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
