import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_medicamentos_movil/core/utils/server_date_time.dart';

void main() {
  group('parseServerDateTime', () {
    test('keeps timezone-less date-times as local wall-clock time', () {
      final parsed = parseServerDateTime('2026-06-04T12:51:00');

      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isFalse);
      expect(parsed.year, 2026);
      expect(parsed.month, 6);
      expect(parsed.day, 4);
      expect(parsed.hour, 12);
      expect(parsed.minute, 51);
    });

    test('converts date-times with explicit timezone to local time', () {
      final parsed = parseServerDateTime('2026-06-04T12:51:00Z');

      expect(parsed, DateTime.parse('2026-06-04T12:51:00Z').toLocal());
    });
  });

  group('formatServerTime', () {
    test('formats timezone-less time without shifting it', () {
      expect(formatServerTime('2026-06-04T12:51:00'), '12:51');
    });
  });
}
