import 'package:clock_app/bedtime/logic/sunrise_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SunriseService offline calculation', () {
    test('calculateOffline returns valid sunrise and sunset for Jakarta', () {
      // Jakarta coordinates
      const lat = -6.2088;
      const lon = 106.8456;

      final data = SunriseService.calculateOffline(lat, lon);

      expect(data.fromOffline, isTrue);
      expect(data.sunrise, isNotNull);
      expect(data.sunset, isNotNull);
      // Sunrise in Jakarta is typically between 5:30 and 6:15 local time
      expect(data.sunrise.hour, isIn([5, 6]));
      // Sunset in Jakarta is typically between 17:30 and 18:30 local time
      expect(data.sunset.hour, isIn([17, 18]));
      expect(data.sunset.isAfter(data.sunrise), isTrue);
    });

    test('SunriseData JSON roundtrip', () {
      final original = SunriseData(
        sunrise: DateTime(2025, 5, 1, 5, 45),
        sunset: DateTime(2025, 5, 1, 18, 10),
        fromOffline: true,
      );

      final json = original.toJson();
      final restored = SunriseData.fromJson(json);

      expect(restored.sunrise, equals(original.sunrise));
      expect(restored.sunset, equals(original.sunset));
      expect(restored.fromOffline, equals(original.fromOffline));
    });
  });

  group('formatOffset helper', () {
    test('formats zero offset as Sunrise', () {
      expect(formatOffset(0), equals('Sunrise'));
    });

    test('formats negative offset correctly', () {
      expect(formatOffset(-15), equals('-15m'));
      expect(formatOffset(-60), equals('-1h'));
      expect(formatOffset(-75), equals('-1h15m'));
    });

    test('formats positive offset correctly', () {
      expect(formatOffset(15), equals('+15m'));
      expect(formatOffset(60), equals('+1h'));
    });
  });
}
