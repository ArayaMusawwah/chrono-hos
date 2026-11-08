import 'package:clock_app/settings/types/setting.dart';
import 'package:flutter/material.dart';

/// A compact time display tile used in the Bedtime screen.
///
/// Renders a label, current time value, and an optional action button.
class BedtimeSettingsTile extends StatelessWidget {
  const BedtimeSettingsTile({
    super.key,
    required this.setting,
    this.icon,
    this.onTap,
  });

  final Setting setting;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = setting.value?.toString() ?? "";

    return ListTile(
      leading: icon != null ? Icon(icon, color: theme.colorScheme.primary) : null,
      title: Text(setting.getLocalizedName(context)),
      trailing: Text(
        value,
        style: theme.textTheme.titleMedium
            ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
      ),
      enabled: onTap != null,
      onTap: onTap,
    );
  }
}
