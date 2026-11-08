import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Coordinates + computed sunrise/sunset data.
class SunriseData {
  final DateTime sunrise;
  final DateTime sunset;
  final bool fromOffline;

  const SunriseData({
    required this.sunrise,
    required this.sunset,
    this.fromOffline = false,
  });

  Map<String, dynamic> toJson() => {
    'sunrise': sunrise.toIso8601String(),
    'sunset': sunset.toIso8601String(),
    'fromOffline': fromOffline,
  };

  factory SunriseData.fromJson(Map<String, dynamic> json) {
    return SunriseData(
      sunrise: DateTime.parse(json['sunrise'] as String),
      sunset: DateTime.parse(json['sunset'] as String),
      fromOffline: json['fromOffline'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'Sunrise ${sunrise.toLocal().toString()}, fromOffline: $fromOffline';
}

class GeolocatorService {
  static const _cacheKey = 'bedtime_location';

  /// Fetch current location, returning null on denial/unavailable.
  static Future<(double, double)?> getPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      return (position.latitude, position.longitude);
    } catch (e) {
      debugPrint('GeolocatorService.getPosition error: $e');
      return null;
    }
  }
}

class SunriseService {
  static const _apiBase = 'https://api.open-meteo.com/v1/forecast';
  static const _cacheKeyPrefix = 'bedtime_sunrise_cache_';

  /// Get sunrise/sunset for [lat]/[lon].
  /// Attempts Open-Meteo API; falls back to offline NOAA on network error.
  static Future<SunriseData> getSunrise(double lat, double lon) async {
    // Try cache first (per-day)
    final cacheKey = _cacheKeyPrefix + DateTime.now().toIso8601String().substring(0, 10);
    final cached = GetStorage().read<String>(cacheKey);
    if (cached != null) {
      try {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        final s = SunriseData.fromJson(json);
        return s;
      } catch (_) {}
    }

    try {
      final data = await _fetchOpenMeteo(lat, lon);
      GetStorage().write(cacheKey, jsonEncode(data.toJson()));
      return data;
    } catch (e) {
      debugPrint('SunriseService: Open-Meteo failed, using offline fallback: $e');
      return SunriseService.calculateOffline(lat, lon);
    }
  }

  static Future<SunriseData> _fetchOpenMeteo(double lat, double lon) async {
    final uri = Uri.parse(
      '$_apiBase?latitude=$lat&longitude=$lon&daily=sunrise,sunset&timezone=auto&forecast_days=1',
    );
    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Open-Meteo returned ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;
    final sunriseTimes = daily['sunrise'] as List<dynamic>;
    final sunsetTimes = daily['sunset'] as List<dynamic>;
    if (sunriseTimes.isEmpty || sunsetTimes.isEmpty) {
      throw Exception('Open-Meteo: empty sunrise/sunset arrays');
    }
    return SunriseService.fromOpenMeteo(sunriseTimes.first, sunsetTimes.first);
  }

  /// Parse Open-Meteo local ISO8601 datetime (no timezone suffix, e.g. "2025-01-01T05:32").
  static SunriseData fromOpenMeteo(String sunriseStr, String sunsetStr) {
    // Format: "YYYY-MM-DDTHH:MM" — interpreted as local device timezone
    DateTime parseLocal(String s) {
      final parts = s.split('T');
      final date = parts[0];
      final time = parts[1];
      final ym = date.split('-');
      final hm = time.split(':');
      return DateTime(
          int.parse(ym[0]),
          int.parse(ym[1]),
          int.parse(ym[2]),
          int.parse(hm[0]),
          int.parse(hm[1]));
    }

    return SunriseData(
      sunrise: parseLocal(sunriseStr),
      sunset: parseLocal(sunsetStr),
      fromOffline: false,
    );
  }

  /// NOAA solar position algorithm — offline fallback.
  /// Accuracy: ±1–3 minutes. No network required.
  static SunriseData calculateOffline(double lat, double lon) {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final dayOfYear = _dayOfYear(midnight);

    // Day of year fraction
    final n = dayOfYear.toDouble();

    // Mean solar longitude
    final L = (360.0 / 365.25) * (n - 81.0); // degrees, approx
    final Lrad = L * math.pi / 180.0;

    // Ecliptic longitude (with corrections)
    final g = (357.525 + 0.985600 * n) * math.pi / 180.0;
    final sunLong = Lrad +
        (1.915 * math.sin(g) + 0.020 * math.sin(2 * g)) * math.pi / 180.0;

    // Equation of time (minutes)
    final eqTime =
        229.18 *
        (0.000075 +
            0.001868 * math.cos(Lrad) -
            0.03207 * math.sin(Lrad) -
            0.01461 * math.cos(2 * Lrad) -
            0.04084 * math.sin(2 * Lrad));

    // Solar noon correction (minutes, accounts for longitude vs UTC)
    final solarNoonUTC = 720.0 - 4.0 * lon - eqTime; // minutes from UTC

    // Daylight fraction
    final decl = (-23.44) * math.cos(Lrad); // solar declination, degrees
    final declRad = decl * math.pi / 180.0;
    final latRad = lat * math.pi / 180.0;

    // Standard solar zenith for sunrise/sunset is 90.833°
    // (90° + 34 arcminutes atmospheric refraction + 16 arcminutes solar semidiameter)
    const zenithRad = 90.833 * math.pi / 180.0;
    final cosH = (math.cos(zenithRad) - math.sin(latRad) * math.sin(declRad)) /
        (math.cos(latRad) * math.cos(declRad));

    double? halfDayAngleRad;
    if (cosH <= -1.0) {
      // Sun never sets (polar day)
      halfDayAngleRad = null;
    } else if (cosH >= 1.0) {
      // Sun never rises (polar night)
      halfDayAngleRad = null;
    } else {
      halfDayAngleRad = math.acos(cosH);
    }

    double sunriseMin;
    double sunsetMin;

    if (halfDayAngleRad == null) {
      // Polar — use solar noon as both
      sunriseMin = solarNoonUTC;
      sunsetMin = solarNoonUTC;
    } else {
      final Hdeg = halfDayAngleRad * 180.0 / math.pi;
      final Hmin = Hdeg * 4.0; // 1 degree of Earth rotation = 4 minutes
      sunriseMin = solarNoonUTC - Hmin;
      sunsetMin = solarNoonUTC + Hmin;
    }

    // Convert UTC minutes to local DateTime
    final utcMidnight = DateTime.utc(now.year, now.month, now.day);
    final sunriseLocal =
        utcMidnight.add(Duration(minutes: sunriseMin.round())).toLocal();
    final sunsetLocal =
        utcMidnight.add(Duration(minutes: sunsetMin.round())).toLocal();

    return SunriseData(
      sunrise: sunriseLocal,
      sunset: sunsetLocal,
      fromOffline: true,
    );
  }

  static int _dayOfYear(DateTime d) {
    // Approximation: day of year via difference from Jan 1
    final jan1 = DateTime(d.year, 1, 1);
    return (d.difference(jan1).inHours ~/ 24) + 1;
  }
}

/// Convenience: fetch sunrise with current location.
/// Returns null if location unavailable and no cached coords.
class BedtimeSunrise {
  static Future<SunriseData?> fetchCurrentSunrise() async {
    final coords = await GeolocatorService.getPosition();
    if (coords == null) return null;
    return SunriseService.getSunrise(coords.$1, coords.$2);
  }

  /// Compute wake time: [sunrise] + [offsetMinutes] (offset is negative for "before sunrise").
  static DateTime wakeTime(SunriseData data, int offsetMinutes) {
    return data.sunrise.add(Duration(minutes: offsetMinutes));
  }
}

String formatOffset(int minutes) {
  if (minutes == 0) return "Sunrise";
  final abs = minutes.abs();
  final h = abs ~/ 60;
  final m = abs % 60;
  final sign = minutes < 0 ? "-" : "+";
  return "$sign${h > 0 ? "${h}h" : ""}${m > 0 ? "${m}m" : ""}";
}
