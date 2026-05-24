import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/medication_intake.dart';
import '../../services/intake_notification_manager.dart';

class InAppIntakeNotificationHost extends StatefulWidget {
  const InAppIntakeNotificationHost({super.key});

  @override
  State<InAppIntakeNotificationHost> createState() =>
      _InAppIntakeNotificationHostState();
}

class _InAppIntakeNotificationHostState
    extends State<InAppIntakeNotificationHost> {
  final IntakeNotificationManager _manager = IntakeNotificationManager();
  final Set<int> _updatingIntakeIds = {};

  Future<void> _updateStatus(MedicationIntake intake, String status) async {
    setState(() => _updatingIntakeIds.add(intake.id));

    final success = await _manager.respondToInAppAlert(intake, status);

    if (!mounted) {
      return;
    }

    setState(() => _updatingIntakeIds.remove(intake.id));

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    if (!success) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar la toma. Intenta de nuevo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final statusLabel = status == 'taken' ? 'tomada' : 'omitida';
    final medicationLabel = _displayMedicationName(intake);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$medicationLabel marcado como $statusLabel'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: status == 'taken'
              ? AppColors.success
              : AppColors.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        if (!_manager.usesInAppAlerts || _manager.inAppAlerts.isEmpty) {
          return const SizedBox.shrink();
        }

        final intake = _manager.inAppAlerts.first;
        final extraCount = _manager.inAppAlerts.length - 1;
        final isUpdating = _updatingIntakeIds.contains(intake.id);
        final medicationLabel = _displayMedicationName(intake);

        return Positioned(
          left: 16,
          right: 16,
          top: MediaQuery.of(context).viewPadding.top + 14,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.notifications_active_outlined,
                                color: AppColors.warning,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Toma pendiente',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    medicationLabel,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Programado: ${intake.timeLabel ?? 'Horario pendiente'}'
                                    '${extraCount > 0 ? '  |  +$extraCount mas' : ''}',
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(
                                    color: AppColors.error.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  minimumSize: const Size(0, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isUpdating
                                    ? null
                                    : () => _updateStatus(intake, 'omitted'),
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
                                    : () => _updateStatus(intake, 'taken'),
                                icon: isUpdating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                label: const Text('Tomada'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
