import 'package:clock_app/alarm/logic/schedule_alarm.dart';
import 'package:clock_app/bedtime/logic/bedtime_notifications.dart';
import 'package:clock_app/bedtime/logic/sunrise_service.dart';
import 'package:clock_app/common/types/notification_type.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:get_storage/get_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fixed schedule IDs
// ─────────────────────────────────────────────────────────────────────────────

const int kBedtimeDndOnId = 90001;
const int kBedtimeDndOffId = 90002;
const int kBedtimeReminderId = 90003;

/// Schedule all active bedtime alarms.
/// Call on app startup, boot completed, settings change, and DND grant.
Future<void> updateBedtimeAlarms() async {
  if (!_isEnabled()) {
    await cancelAllBedtimeAlarms();
    return;
  }

  await cancelAllBedtimeAlarms();

  final nextBed = _nextBedtime();
  final nextWake = _nextWakeTime();

  if (nextBed == null) return;

  final reminderTime = nextBed.subtract(Duration(
      minutes: _reminderLeadMinutes()));

  if (_dndOnAtBedtime()) {
    await _schedule(kBedtimeDndOnId, nextBed, 'dnd_on');
  }

  if (_dndOffAtWake() && nextWake != null) {
    await _schedule(kBedtimeDndOffId, nextWake, 'dnd_off');
  }

  if (_reminderEnabled() && reminderTime.isAfter(DateTime.now())) {
    await _schedule(kBedtimeReminderId, reminderTime, 'reminder');
  }
}

Future<void> cancelAllBedtimeAlarms() async {
  // Also drop the AwesomeNotifications reminder so it cannot fire stale.
  await cancelBedtimeReminder(kBedtimeReminderId);
  await cancelAlarm(kBedtimeDndOnId, ScheduledNotificationType.bedtime);
  await cancelAlarm(kBedtimeDndOffId, ScheduledNotificationType.bedtime);
  await cancelAlarm(kBedtimeReminderId, ScheduledNotificationType.bedtime);
}

/// Refresh today's sunrise cache. Call on app start / background tick.
Future<void> refreshSunriseCache() async {
  if (!_sunriseEnabled()) return;
  final coords = await GeolocatorService.getPosition();
  if (coords == null) return;
  await SunriseService.getSunrise(coords.$1, coords.$2);
}

// ─────────────────────────────────────────────────────────────────────────────

Future<void> _schedule(int id, DateTime time, String action) async {
  if (!time.isAfter(DateTime.now())) {
    time = time.add(const Duration(days: 1));
  }
  await scheduleAlarm(
    id,
    time,
    'Bedtime $action',
    alarmClock: false,
    type: ScheduledNotificationType.bedtime,
    extraParams: {'bedtime_action': action},
  );

  // Fallback path: Parallel AwesomeNotifications reminder so the user gets
  // visible feedback even if the background isolate is killed. DND itself
  // needs the isolate, but the reminder must always reach the user.
  if (action == 'reminder') {
    await scheduleBedtimeReminder(
      id,
      time,
      'Time to wind down',
      'Bedtime is coming up soon.',
    );
  }
}

DateTime? _nextBedtime() {
  final raw =
      appSettings.getGroup('Bedtime').getGroup('Sleep Schedule')
          .getSetting('Bedtime').value;
  final dt = _extractTime(raw);
  if (dt == null) return null;
  return _nextOccurrence(dt);
}

DateTime? _nextWakeTime() {
  final g = appSettings.getGroup('Bedtime');

  if (_sunriseEnabled()) {
    final sunrise = _getCachedSunrise();
    if (sunrise != null) {
      final wake = sunrise.sunrise.add(Duration(minutes: _sunriseOffset()));
      final next = _nextOccurrence(wake);
      if (next != null) return next;
    }
  }

  final raw =
      g.getGroup('Sleep Schedule').getSetting('Wake Time').value;
  return _nextOccurrence(_extractTime(raw));
}

DateTime? _nextOccurrence(DateTime? timeOfDay) {
  if (timeOfDay == null) return null;
  final now = DateTime.now();
  var next = DateTime(now.year, now.month, now.day,
      timeOfDay.hour, timeOfDay.minute);
  if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
  return next;
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings helpers
// ─────────────────────────────────────────────────────────────────────────────

bool _isEnabled() =>
    appSettings.getGroup('Bedtime').getSetting('Bedtime Enabled').value == true;

bool _sunriseEnabled() =>
    appSettings
        .getGroup('Bedtime')
        .getGroup('Sunrise Wake')
        .getSetting('Wake Relative to Sunrise')
        .value ==
        true;

bool _dndOnAtBedtime() =>
    appSettings
            .getGroup('Bedtime')
            .getGroup('Do Not Disturb')
            .getSetting('Auto DND at Bedtime')
            .value ==
        true;

bool _dndOffAtWake() =>
    appSettings
            .getGroup('Bedtime')
            .getGroup('Do Not Disturb')
            .getSetting('Auto DND at Wake')
            .value ==
        true;

bool _reminderEnabled() =>
    appSettings
            .getGroup('Bedtime')
            .getGroup('Reminder')
            .getSetting('Pre-Sleep Reminder')
            .value ==
        true;

int _reminderLeadMinutes() {
  final v = appSettings
      .getGroup('Bedtime')
      .getGroup('Reminder')
      .getSetting('Reminder Lead Time')
      .value;
  return (v as num?)?.round() ?? 15;
}

int _sunriseOffset() {
  final v = appSettings
      .getGroup('Bedtime')
      .getGroup('Sunrise Wake')
      .getSetting('Sunrise Offset')
      .value;
  return (v as num?)?.round() ?? -15;
}

SunriseData? _getCachedSunrise() {
  final key =
      'bedtime_sunrise_cache_${DateTime.now().toIso8601String().substring(0, 10)}';
  final raw = GetStorage().read<String>(key);
  if (raw == null) return null;
  try {
    final sunrise = DateTime.parse(raw);
    return SunriseData(sunrise: sunrise, sunset: sunrise, fromOffline: true);
  } catch (_) {
    return null;
  }
}

DateTime? _extractTime(dynamic raw) {
  if (raw is! List || raw.isEmpty) return null;
  final v = raw.first;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return null;
}
