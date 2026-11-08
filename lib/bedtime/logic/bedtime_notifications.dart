import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:clock_app/notifications/data/notification_channel.dart';
import 'package:clock_app/developer/logic/logger.dart';

/// Schedule a bedtime routine reminder via AwesomeNotifications.
/// This relies on the plugin's own exact-alarm scheduling, which is more
/// resilient on HyperOS than registering callbacks through the background
/// isolate (whose process may be killed before the alarm fires).
Future<void> scheduleBedtimeReminder(
  int id,
  DateTime time,
  String title,
  String body,
) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: id,
      channelKey: reminderNotificationChannelKey,
      title: title,
      body: body,
      category: NotificationCategory.Reminder,
    ),
    schedule: NotificationCalendar.fromDate(
      date: time,
      preciseAlarm: true,
      allowWhileIdle: true,
    ),
  );
  logger.t(
      '[bedtime] Scheduled AwesomeNotifications reminder $id at $time');
}

Future<void> cancelBedtimeReminder(int id) async {
  await AwesomeNotifications().cancel(id);
  logger.t('[bedtime] Cancelled AwesomeNotifications reminder $id');
}
