import 'package:clock_app/bedtime/logic/dnd_onboarding.dart';
import 'package:clock_app/bedtime/logic/dnd_service.dart';
import 'package:clock_app/bedtime/logic/schedule_bedtime.dart';
import 'package:clock_app/bedtime/logic/sunrise_service.dart';
import 'package:clock_app/bedtime/logic/update_bedtime_widget.dart';
import 'package:clock_app/bedtime/widgets/sunrise_offset_dialog.dart';
import 'package:clock_app/common/widgets/card_container.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/settings/types/setting.dart';
import 'package:clock_app/settings/types/setting_group.dart';
import 'package:flutter/material.dart';

class BedtimeScreen extends StatefulWidget {
  const BedtimeScreen({super.key});

  @override
  State<BedtimeScreen> createState() => _BedtimeScreenState();
}

class _BedtimeScreenState extends State<BedtimeScreen> {
  late SettingGroup _bedtime;
  late Setting _enabled;
  late Setting _dndOn;
  late Setting _dndOff;
  late Setting _sunriseEnabled;
  late Setting _sunriseOffset;
  late Setting _reminderEnabled;
  late Setting _reminderLeadTime;
  late Setting _bedtimeTime;
  late Setting _wakeTime;

  bool _dndAllowed = false;
  SunriseData? _todaySunrise;

  void update(value) {
    if (mounted) setState(() {});
  }

  Future<void> _refreshDnd() async {
    final allowed = await DndService.isAllowed();
    if (mounted) setState(() => _dndAllowed = allowed);
  }

  Future<void> _refreshSunrise() async {
    try {
      final coords = await GeolocatorService.getPosition();
      if (coords != null && mounted) {
        final data = await SunriseService.getSunrise(coords.$1, coords.$2);
        if (mounted) setState(() => _todaySunrise = data);
      }
    } catch (_) {}
  }

  Future<void> _setSetting(Setting setting, dynamic val) async {
    setting.setValue(context, val);
    await appSettings.save();
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _bedtime = appSettings.getGroup("Bedtime");
    _enabled = _bedtime.getSetting("Bedtime Enabled");
    final schedule = _bedtime.getGroup("Sleep Schedule");
    final dnd = _bedtime.getGroup("Do Not Disturb");
    final sunrise = _bedtime.getGroup("Sunrise Wake");
    final reminder = _bedtime.getGroup("Reminder");

    _bedtimeTime = schedule.getSetting("Bedtime");
    _wakeTime = schedule.getSetting("Wake Time");
    _dndOn = dnd.getSetting("Auto DND at Bedtime");
    _dndOff = dnd.getSetting("Auto DND at Wake");
    _sunriseEnabled = sunrise.getSetting("Wake Relative to Sunrise");
    _sunriseOffset = sunrise.getSetting("Sunrise Offset");
    _reminderEnabled = reminder.getSetting("Pre-Sleep Reminder");
    _reminderLeadTime = reminder.getSetting("Reminder Lead Time");

    for (final s in [
      _enabled,
      _dndOn,
      _dndOff,
      _sunriseEnabled,
      _reminderEnabled,
      _bedtimeTime,
      _wakeTime,
      _sunriseOffset,
      _reminderLeadTime,
    ]) {
      s.addListener(update);
    }
    _refreshDnd();
    _refreshSunrise();
  }

  @override
  void dispose() {
    for (final s in [
      _enabled,
      _dndOn,
      _dndOff,
      _sunriseEnabled,
      _reminderEnabled,
      _bedtimeTime,
      _wakeTime,
      _sunriseOffset,
      _reminderLeadTime,
    ]) {
      s.removeListener(update);
    }
    super.dispose();
  }

  TimeOfDay _getTime(Setting setting, TimeOfDay fallback) {
    final list = setting.value as List<dynamic>? ?? [];
    if (list.isEmpty) return fallback;
    final v = list.first;
    if (v is DateTime) return TimeOfDay.fromDateTime(v);
    if (v is int) {
      return TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(v));
    }
    return fallback;
  }

  String _formatSleepDuration(TimeOfDay bed, TimeOfDay wake) {
    int bedMin = bed.hour * 60 + bed.minute;
    int wakeMin = wake.hour * 60 + wake.minute;
    if (wakeMin <= bedMin) {
      wakeMin += 24 * 60;
    }
    final diff = wakeMin - bedMin;
    final h = diff ~/ 60;
    final m = diff % 60;
    if (m == 0) return "$h jam";
    return "${h}j ${m}m";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isActive = _enabled.value as bool? ?? false;
    final dndAtBedtime = _dndOn.value as bool? ?? false;
    final dndAtWake = _dndOff.value as bool? ?? false;
    final sunriseMode = _sunriseEnabled.value as bool? ?? false;
    final offsetMin = (_sunriseOffset.value as num?)?.round() ?? -15;
    final reminderOn = _reminderEnabled.value as bool? ?? false;
    final reminderMin = (_reminderLeadTime.value as num?)?.round() ?? 15;

    final bedTimeOfDay = _getTime(_bedtimeTime, const TimeOfDay(hour: 22, minute: 0));
    final wakeTimeOfDay = _getTime(_wakeTime, const TimeOfDay(hour: 6, minute: 0));

    // Calculate effective wake time display
    TimeOfDay effectiveWake = wakeTimeOfDay;
    if (sunriseMode && _todaySunrise != null) {
      final wakeDt = _todaySunrise!.sunrise.add(Duration(minutes: offsetMin));
      effectiveWake = TimeOfDay.fromDateTime(wakeDt);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // ── 1. HERO SLEEP STATUS CARD (HyperOS 3 Symmetrical Design) ──────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: CardContainer(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Title + Master Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.bedtime_rounded,
                              size: 20,
                              color: isActive
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Rutinitas Tidur",
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                isActive ? "Aktif berjalan" : "Nonaktif",
                                style: textTheme.bodySmall?.copyWith(
                                  color: isActive
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: isActive,
                        onChanged: (v) async {
                          await _setSetting(_enabled, v);
                          await updateBedtimeAlarms();
                          if (v && !_dndAllowed && context.mounted) {
                            showDndOnboarding(context);
                          }
                          updateBedtimeWidget();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Symmetrical Sleep Duration Card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Left: Bedtime
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.nightlight_round,
                                      size: 14, color: colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Tidur",
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  bedTimeOfDay.format(context),
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Center: Duration Badge
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatSleepDuration(bedTimeOfDay, effectiveWake),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Right: Wake Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    sunriseMode
                                        ? Icons.wb_twilight_rounded
                                        : Icons.wb_sunny_rounded,
                                    size: 14,
                                    color: Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    sunriseMode ? "Sunrise" : "Bangun",
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  effectiveWake.format(context),
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── 2. SLEEP SCHEDULE SECTION ─────────────────────────────────────
        const _SectionHeader(title: "Jadwal Jam Tidur & Bangun"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: CardContainer(
            child: Column(
              children: [
                _BedtimeActionRow(
                  icon: Icons.bedtime_outlined,
                  iconColor: colorScheme.primary,
                  title: "Waktu Tidur",
                  subtitle: "Jam mulai rutinitas malam",
                  trailingText: bedTimeOfDay.format(context),
                  enabled: isActive,
                  onTap: () => _pickTime(_bedtimeTime, "Pilih Jam Tidur"),
                ),
                _divider(colorScheme),
                _BedtimeActionRow(
                  icon: Icons.alarm_rounded,
                  iconColor: Colors.amber.shade700,
                  title: "Jam Bangun Tetap",
                  subtitle: sunriseMode
                      ? "Dinonaktifkan (mengikuti matahari terbit)"
                      : "Jam alarm pagi berdering",
                  trailingText: wakeTimeOfDay.format(context),
                  enabled: isActive && !sunriseMode,
                  onTap: () => _pickTime(_wakeTime, "Pilih Jam Bangun"),
                ),
              ],
            ),
          ),
        ),

        // ── 3. SUNRISE WAKE SECTION ───────────────────────────────────────
        const _SectionHeader(title: "Alarm Relatif Matahari Terbit"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: CardContainer(
            child: Column(
              children: [
                _BedtimeSwitchRow(
                  icon: Icons.wb_sunny_outlined,
                  iconColor: Colors.orange.shade600,
                  title: "Ikuti Waktu Terbit",
                  subtitle: "Bangun otomatis sebelum matahari terbit",
                  value: sunriseMode,
                  enabled: isActive,
                  onChanged: (v) async {
                    await _setSetting(_sunriseEnabled, v);
                    await updateBedtimeAlarms();
                    updateBedtimeWidget();
                  },
                ),
                if (sunriseMode) ...[
                  _divider(colorScheme),
                  _BedtimeActionRow(
                    icon: Icons.tune_rounded,
                    iconColor: colorScheme.tertiary,
                    title: "Offset Sebelum Terbit",
                    subtitle: _todaySunrise != null
                        ? "Terbit ${_todaySunrise!.sunrise.hour.toString().padLeft(2, '0')}:${_todaySunrise!.sunrise.minute.toString().padLeft(2, '0')} · Target bangun ${effectiveWake.format(context)}"
                        : "Ketuk untuk atur menit bangun sebelum terbit",
                    trailingText: formatOffset(offsetMin),
                    enabled: isActive,
                    onTap: _pickOffset,
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── 4. DO NOT DISTURB SECTION ─────────────────────────────────────
        const _SectionHeader(title: "Mode Jangan Ganggu (DND)"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: CardContainer(
            child: Column(
              children: [
                _BedtimeSwitchRow(
                  icon: Icons.do_not_disturb_on_outlined,
                  iconColor: Colors.deepPurpleAccent,
                  title: "Nyalakan DND Saat Tidur",
                  subtitle: "Otomatis heningkan notifikasi di jam tidur",
                  value: dndAtBedtime,
                  enabled: isActive,
                  onChanged: (v) async {
                    await _setSetting(_dndOn, v);
                    await updateBedtimeAlarms();
                  },
                ),
                _divider(colorScheme),
                _BedtimeSwitchRow(
                  icon: Icons.notifications_active_outlined,
                  iconColor: Colors.teal,
                  title: "Matikan DND Saat Bangun",
                  subtitle: "Otomatis normalkan suara di jam bangun",
                  value: dndAtWake,
                  enabled: isActive,
                  onChanged: (v) async {
                    await _setSetting(_dndOff, v);
                    await updateBedtimeAlarms();
                  },
                ),
                if (!_dndAllowed) ...[
                  _divider(colorScheme),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => showDndOnboarding(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade700, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.amber.shade800, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Izin DND belum aktif. Ketuk untuk membuka panduan pengaturan.",
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── 5. PRE-SLEEP REMINDER SECTION ─────────────────────────────────
        const _SectionHeader(title: "Pengingat Persiapan Tidur"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: CardContainer(
            child: Column(
              children: [
                _BedtimeSwitchRow(
                  icon: Icons.notifications_outlined,
                  iconColor: Colors.blueAccent,
                  title: "Notifikasi Pengingat",
                  subtitle: "$reminderMin menit sebelum jadwal tidur",
                  value: reminderOn,
                  enabled: isActive,
                  onChanged: (v) async {
                    await _setSetting(_reminderEnabled, v);
                    await updateBedtimeAlarms();
                  },
                ),
                if (reminderOn) ...[
                  _divider(colorScheme),
                  _BedtimeActionRow(
                    icon: Icons.timer_outlined,
                    iconColor: colorScheme.secondary,
                    title: "Waktu Tunggu Pengingat",
                    subtitle: "Berapa menit sebelum tidur",
                    trailingText: "$reminderMin menit",
                    enabled: isActive,
                    onTap: _pickLeadTime,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _divider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 48,
      endIndent: 16,
      color: colorScheme.outlineVariant.withOpacity(0.3),
    );
  }

  Future<void> _pickTime(Setting setting, String title) async {
    final current = (setting.value as List?)?.isNotEmpty == true
        ? (setting.value as List).first as dynamic
        : null;
    final dt = current is DateTime
        ? current
        : current is int
            ? DateTime.fromMillisecondsSinceEpoch(current)
            : DateTime(2000, 1, 1, 22, 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(dt),
      helpText: title,
    );
    if (picked != null) {
      await _setSetting(
          setting, [DateTime(2000, 1, 1, picked.hour, picked.minute)]);
      if (mounted) setState(() {});
      await updateBedtimeAlarms();
      updateBedtimeWidget();
    }
  }

  Future<void> _pickOffset() async {
    final currentMin = (_sunriseOffset.value as num?)?.round() ?? -15;
    final picked = await SunriseOffsetDialog.show(context, currentMin);
    if (picked != null) {
      await _setSetting(_sunriseOffset, picked.toDouble());
      await updateBedtimeAlarms();
      updateBedtimeWidget();
    }
  }

  Future<void> _pickLeadTime() async {
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Pengingat Sebelum Tidur"),
        children: [
          for (final mins in const [5, 10, 15, 20, 25, 30, 45, 60])
            ListTile(
              title: Text("$mins menit sebelum tidur"),
              onTap: () => Navigator.pop(ctx, mins.toDouble()),
            ),
        ],
      ),
    );
    if (result != null) {
      await _setSetting(_reminderLeadTime, result);
      await updateBedtimeAlarms();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pixel-Perfect Symmetrical Row Components (Strict OCD & WCAG AA)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _BedtimeActionRow extends StatelessWidget {
  const _BedtimeActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailingText;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: enabled ? iconColor : colorScheme.onSurface.withOpacity(0.38),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.38),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: enabled ? colorScheme.onSurfaceVariant : colorScheme.onSurface.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: enabled ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                trailingText,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: enabled ? colorScheme.onPrimaryContainer : colorScheme.onSurface.withOpacity(0.38),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BedtimeSwitchRow extends StatelessWidget {
  const _BedtimeSwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: enabled ? iconColor : colorScheme.onSurface.withOpacity(0.38),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.38),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: enabled ? colorScheme.onSurfaceVariant : colorScheme.onSurface.withOpacity(0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
