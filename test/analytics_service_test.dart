import 'package:flutter_test/flutter_test.dart';

import 'package:edutrack_phs/services/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    test('date range preset resolves to a valid range', () {
      final range = AnalyticsService.resolveDateRange(
        preset: AnalyticsDatePreset.thisMonth,
      );

      expect(range.start.isBefore(range.end), isTrue);
      expect(range.end.isAfter(range.start), isTrue);
    });

    test('percentage helpers return expected values', () {
      expect(AnalyticsService.safePercentage(8, 20), 40.0);
      expect(AnalyticsService.safePercentage(0, 0), 0.0);
    });
  });
}
