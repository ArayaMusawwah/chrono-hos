import 'package:clock_app/bedtime/logic/dnd_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Shows a step-by-step DND permission onboarding dialog.
///
/// Call [showDndOnboarding] when [DndService.isAllowed()] returns false.
Future<void> showDndOnboarding(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final title = l10n?.bedtimeDndPermissionTitle ?? "Grant Do Not Disturb access";
  final body =
      l10n?.bedtimeDndPermissionDescription ??
      "Go to Settings > Sound > Do Not Disturb > Allow apps.";

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.notifications_none, color: Theme.of(ctx).colorScheme.tertiary),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body),
          const SizedBox(height: 12),
          const _Step(1, "Open Settings → Sound → Do Not Disturb"),
          const _Step(2, "Tap 'Allow apps to control DND'"),
          const _Step(3, "Enable this app (Chrono)"),
          const SizedBox(height: 4),
          Text(
            "HyperOS: also disable battery optimization and add to autostart "
            "(Security → Autostart) so the wake alarm is not killed.",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Later"),
        ),
        FilledButton(
          onPressed: () async {
            await DndService.requestAccess();
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text("Open Settings"),
        ),
      ],
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step(this.n, this.text);
  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          CircleAvatar(radius: 10, backgroundColor: Colors.blue.shade900,
              child: Text("$n", style: const TextStyle(fontSize: 11, color: Colors.white))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
