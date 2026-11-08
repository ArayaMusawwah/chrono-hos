import 'package:clock_app/developer/logic/logger.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:home_widget/home_widget.dart';

/// Writes bedtime-related widget data to the shared widget store
/// and triggers the native widget provider to refresh.
Future<void> setBedtimeWidgetData() async {
  try {
    final bedtime = appSettings.getGroup('Bedtime');
    final enabled = bedtime.getSetting('Bedtime Enabled').value as bool;

    final rawBedtime = (bedtime
            .getGroup('Sleep Schedule')
            .getSetting('Bedtime')
            .value as List<dynamic>?) ??
        [];
    final rawWake = (bedtime
            .getGroup('Sleep Schedule')
            .getSetting('Wake Time')
            .value as List<dynamic>?) ??
        [];

    String formatTime(List<dynamic> raw) {
      if (raw.isEmpty) return '--:--';
      final v = raw.first;
      final dt = v is DateTime
          ? v
          : v is int
              ? DateTime.fromMillisecondsSinceEpoch(v)
              : null;
      if (dt == null) return '--:--';
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    await HomeWidget.saveWidgetData<bool>('bedtime_enabled', enabled);
    await HomeWidget.saveWidgetData<String>(
        'bedtime_time', formatTime(rawBedtime));
    await HomeWidget.saveWidgetData<String>(
        'bedtime_wake', formatTime(rawWake));

    updateBedtimeWidget();
  } catch (e) {
    logger.e("Couldn't update Bedtime Widget: $e");
  }
}

void updateBedtimeWidget() {
  HomeWidget.updateWidget(
    androidName: 'BedtimeWidgetProvider',
    name: 'BedtimeWidgetProvider',
    qualifiedAndroidName: 'com.vicolo.chrono.BedtimeWidgetProvider',
  );
}
