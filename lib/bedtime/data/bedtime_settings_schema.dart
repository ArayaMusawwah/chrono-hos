import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clock_app/settings/types/setting.dart';
import 'package:clock_app/settings/types/setting_enable_condition.dart';
import 'package:clock_app/settings/types/setting_group.dart';
import 'package:flutter/material.dart';

const bedtimeSchemaVersion = 1;

/// Bedtime routine settings.
///
/// Add to [appSettings] in settings_schema.dart as `bedtimeSettingsSchema`.
///
/// All values are persisted via the shared settings JSON store.
/// Keys are stable identifiers — do not rename without a version bump.
SettingGroup bedtimeSettingsSchema = SettingGroup(
  "Bedtime",
  (context) => AppLocalizations.of(context)?.bedtimeTitle ?? "Bedtime",
  [
    // ── Master toggle ──────────────────────────────────────────────────────
    SwitchSetting(
      "Bedtime Enabled",
      (context) => AppLocalizations.of(context)?.bedtimeEnabledSetting ?? "Enabled",
      false,
      getDescription: (context) =>
          AppLocalizations.of(context)?.bedtimeEnabledDescription ??
          "Master switch for the bedtime routine",
      searchTags: ["bedtime", "routine", "enable"],
    ),

    // ── Sleep schedule ─────────────────────────────────────────────────────
    SettingGroup(
      "Sleep Schedule",
      (context) => AppLocalizations.of(context)?.bedtimeScheduleGroup ?? "Sleep Schedule",
      [
        // Fixed bedtime time (defaults to 22:00)
        DateTimeSetting(
          "Bedtime",
          (context) => AppLocalizations.of(context)?.bedtimeTimeSetting ?? "Bedtime",
          [DateTime(2000, 1, 1, 22, 0)],
          searchTags: ["bedtime", "time", "sleep"],
        ),

        // Fixed wake time (defaults to 06:00)
        DateTimeSetting(
          "Wake Time",
          (context) => AppLocalizations.of(context)?.bedtimeWakeTimeSetting ?? "Wake time",
          [DateTime(2000, 1, 1, 6, 0)],
          searchTags: ["wake", "time", "sunrise"],
        ),
      ],
      icon: Icons.bedtime,
      searchTags: ["schedule", "time"],
    ),

    // ── DND controls ───────────────────────────────────────────────────────
    SettingGroup(
      "Do Not Disturb",
      (context) => AppLocalizations.of(context)?.bedtimeDndGroup ?? "Do Not Disturb",
      [
        SwitchSetting(
          "Auto DND at Bedtime",
          (context) => AppLocalizations.of(context)?.bedtimeDndOnSetting ?? "Turn on DND at bedtime",
          false,
          getDescription: (context) =>
              AppLocalizations.of(context)?.bedtimeDndOnDescription ??
              "DND is automatically activated at bedtime",
        ),
        SwitchSetting(
          "Auto DND at Wake",
          (context) => AppLocalizations.of(context)?.bedtimeDndOffSetting ?? "Turn off DND at wake time",
          false,
        ),
      ],
      icon: Icons.notifications_none_outlined,
      searchTags: ["dnd", "quiet", "disturb"],
    ),

    // ── Sunrise-relative wake ──────────────────────────────────────────────
    SettingGroup(
      "Sunrise Wake",
      (context) => AppLocalizations.of(context)?.bedtimeSunriseGroup ?? "Sunrise wake",
      [
        SwitchSetting(
          "Wake Relative to Sunrise",
          (context) => AppLocalizations.of(context)?.bedtimeSunriseEnabledSetting ?? "Follow sunrise",
          false,
          getDescription: (context) =>
              AppLocalizations.of(context)?.bedtimeSunriseEnabledDescription ??
              "Wake time is calculated from local sunrise each day",
        ),
        SliderSetting(
          "Sunrise Offset",
          (context) => AppLocalizations.of(context)?.bedtimeSunriseOffsetSetting ?? "Offset before sunrise",
          -90,
          0,
          -15, // default: 15 min before sunrise
          unit: "m",
          snapLength: 5,
          enableConditions: [
            ValueCondition(["Wake Relative to Sunrise"], (v) => v == true),
          ],
        ),
      ],
      icon: Icons.wb_sunny_outlined,
      searchTags: ["sunrise", "wake", "offset"],
    ),

    // ── Pre-sleep reminder ─────────────────────────────────────────────────
    SettingGroup(
      "Reminder",
      (context) => AppLocalizations.of(context)?.bedtimeReminderGroup ?? "Reminder",
      [
        SwitchSetting(
          "Pre-Sleep Reminder",
          (context) => AppLocalizations.of(context)?.bedtimeReminderSetting ?? "15 min before bedtime",
          true,
          getDescription: (context) =>
              AppLocalizations.of(context)?.bedtimeReminderDescription ??
              "Notification shortly before the scheduled bedtime",
        ),
        SliderSetting(
          "Reminder Lead Time",
          (context) => AppLocalizations.of(context)?.bedtimeReminderLeadTimeSetting ?? "Lead time",
          5,
          60,
          15,
          unit: "m",
          snapLength: 5,
          enableConditions: [
            ValueCondition(["Pre-Sleep Reminder"], (v) => v == true),
          ],
        ),
      ],
      icon: Icons.notifications_active_outlined,
      searchTags: ["reminder", "notification"],
    ),
  ],
  icon: Icons.bedtime,
  searchTags: ["bedtime", "sleep", "dnd", "sunrise"],
);
