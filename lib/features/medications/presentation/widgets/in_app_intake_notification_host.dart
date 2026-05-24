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
  static const Color _softPrimary = Color(0xFFCCFBF1);
  static const Color _timePillBackground = Color(0xFFF1F5F9);

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
        final hasAlert =
            _manager.usesInAppAlerts && _manager.inAppAlerts.isNotEmpty;
        return Positioned(
          left: 12,
          right: 12,
          top: MediaQuery.of(context).viewPadding.top + 10,
          child: IgnorePointer(
            ignoring: !hasAlert,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              reverseDuration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(0, -0.18),
                  end: Offset.zero,
                ).animate(animation);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: child,
                  ),
                );
              },
              child: hasAlert
                  ? _buildToast(
                      context,
                      _manager.inAppAlerts.first,
                      _manager.inAppAlerts.length - 1,
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToast(
    BuildContext context,
    MedicationIntake intake,
    int extraCount,
  ) {
    final isUpdating = _updatingIntakeIds.contains(intake.id);
    final medicationLabel = _displayMedicationName(intake);
    final timeLabel = intake.timeLabel ?? 'Horario pendiente';

    return Center(
      key: ValueKey('intake-${intake.id}'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _softPrimary,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useStackedButtons = constraints.maxWidth < 340;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _softPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Toma pendiente',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  medicationLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTimePill(timeLabel, extraCount),
                        ],
                      ),
                      const SizedBox(height: 10),
                      useStackedButtons
                          ? Column(
                              children: [
                                _buildOmitButton(intake, isUpdating),
                                const SizedBox(height: 8),
                                _buildTakenButton(intake, isUpdating),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildOmitButton(intake, isUpdating),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTakenButton(intake, isUpdating),
                                ),
                              ],
                            ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePill(String timeLabel, int extraCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _timePillBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_outlined,
            color: AppColors.textSecondary,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            extraCount > 0 ? '$timeLabel +$extraCount' : timeLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOmitButton(MedicationIntake intake, bool isUpdating) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        backgroundColor: AppColors.surface,
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.34)),
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      onPressed: isUpdating ? null : () => _updateStatus(intake, 'omitted'),
      icon: const Icon(Icons.cancel_outlined, size: 17),
      label: const Text(
        'Omitida',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildTakenButton(MedicationIntake intake, bool isUpdating) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      onPressed: isUpdating ? null : () => _updateStatus(intake, 'taken'),
      icon: isUpdating
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.check_circle_outline, size: 17),
      label: const Text(
        'Tomada',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
