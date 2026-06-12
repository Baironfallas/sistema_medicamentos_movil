import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_medicamentos_movil/features/medications/models/medication_intake.dart';

void main() {
  group('MedicationIntake', () {
    test('uses local hour and date labels before scheduledAt', () {
      final intake = MedicationIntake.fromJson({
        'id': 1,
        'medicationName': 'Prueba',
        'status': 'pending',
        'scheduledAt': '2026-06-04T08:52:00Z',
        'date': '2026-06-04',
        'hour': '20:52:00',
      });

      expect(intake.timeLabel, '20:52');
      expect(intake.dateLabel, '2026-06-04');
      expect(intake.scheduledDateTime, DateTime(2026, 6, 4, 20, 52));
    });

    test('can build scheduled time from time-only backend field', () {
      final intake = MedicationIntake.fromJson({
        'id': 2,
        'medicationName': 'Prueba',
        'status': 'pending',
        'date': '2026-06-04',
        'time': '12:51:00',
      });

      expect(intake.timeLabel, '12:51');
      expect(intake.scheduledDateTime, DateTime(2026, 6, 4, 12, 51));
    });

    test('shows timezone instants as Costa Rica medication time', () {
      final intake = MedicationIntake.fromJson({
        'id': 3,
        'medicationName': 'Prueba',
        'status': 'pending',
        'scheduledAt': '2026-06-05T03:11:00.000Z',
      });

      expect(intake.timeLabel, '21:11');
      expect(intake.dateLabel, '2026-06-04');
      expect(intake.scheduledDateTime, DateTime(2026, 6, 4, 21, 11));
    });
  });
}
