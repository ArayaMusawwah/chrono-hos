import 'package:flutter/material.dart';

/// Pixel-perfect, symmetrical dialog to pick sunrise offset with 1-minute precision.
/// Strictly follows WCAG AA contrast and OCD-compliant visual symmetry.
class SunriseOffsetDialog extends StatefulWidget {
  const SunriseOffsetDialog({
    super.key,
    required this.initialOffsetMinutes,
  });

  final int initialOffsetMinutes;

  static Future<int?> show(BuildContext context, int currentOffset) {
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SunriseOffsetDialog(initialOffsetMinutes: currentOffset),
    );
  }

  @override
  State<SunriseOffsetDialog> createState() => _SunriseOffsetDialogState();
}

class _SunriseOffsetDialogState extends State<SunriseOffsetDialog> {
  late int _offset;

  @override
  void initState() {
    super.initState();
    _offset = widget.initialOffsetMinutes.clamp(-120, 0);
  }

  String _getPhaseDescription(int mins) {
    if (mins == 0) return "☀️ Tepat saat tepi atas matahari menyentuh ufuk";
    if (mins >= -10) return "Sesaat sebelum piringan matahari muncul";
    if (mins >= -25) return "🌅 Fajar terang (Civil dawn) — langit sudah terang";
    if (mins >= -50) return "Fajar nautika — garis cakrawala terlihat jelas";
    return "Fajar astronomi (Subuh) — pendar cahaya pertama";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wb_twilight_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Offset Sunrise",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 330,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            // ── Big Value Display (WCAG AA High Contrast) ───────────────
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
              child: Column(
                children: [
                  Text(
                    _offset == 0 ? "0 menit" : "${_offset.abs()} menit sebelum",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPhaseDescription(_offset),
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Stepper + Slider (1-minute precision) ───────────────────
            Row(
              children: [
                _buildStepperButton(
                  icon: Icons.remove,
                  tooltip: "-1 menit",
                  onPressed: _offset > -120
                      ? () => setState(() => _offset = (_offset - 1).clamp(-120, 0))
                      : null,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: colorScheme.primary,
                      inactiveTrackColor: colorScheme.outlineVariant.withOpacity(0.3),
                      thumbColor: colorScheme.primary,
                      overlayColor: colorScheme.primary.withOpacity(0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _offset.toDouble(),
                      min: -90,
                      max: 0,
                      divisions: 90,
                      label: "$_offset m",
                      onChanged: (v) => setState(() => _offset = v.round()),
                    ),
                  ),
                ),
                _buildStepperButton(
                  icon: Icons.add,
                  tooltip: "+1 menit",
                  onPressed: _offset < 0
                      ? () => setState(() => _offset = (_offset + 1).clamp(-120, 0))
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Symmetrical 4x2 Grid of Presets (Zero Floating Chips) ───
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Pilihan Cepat",
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Row 1: -25m (Civil) | -15m
            Row(
              children: [
                Expanded(child: _buildGridButton(-25, "-25m Fajar terang 🌅", isHighlight: true)),
                const SizedBox(width: 8),
                Expanded(child: _buildGridButton(-15, "-15m Sebelum")),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: -30m | -20m
            Row(
              children: [
                Expanded(child: _buildGridButton(-30, "-30m Sebelum")),
                const SizedBox(width: 8),
                Expanded(child: _buildGridButton(-20, "-20m Sebelum")),
              ],
            ),
            const SizedBox(height: 8),

            // Row 3: -45m (Nautical) | -60m (1 hr)
            Row(
              children: [
                Expanded(child: _buildGridButton(-45, "-45m Fajar nautika")),
                const SizedBox(width: 8),
                Expanded(child: _buildGridButton(-60, "-60m (1 jam)")),
              ],
            ),
            const SizedBox(height: 8),

            // Row 4: -75m (Subuh) | 0m (Pas terbit)
            Row(
              children: [
                Expanded(child: _buildGridButton(-75, "-75m Subuh")),
                const SizedBox(width: 8),
                Expanded(child: _buildGridButton(0, "0m Pas terbit ☀️")),
              ],
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Batal",
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _offset),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text("Terapkan", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: onPressed != null
            ? colorScheme.surfaceContainerHighest.withOpacity(0.6)
            : colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        color: colorScheme.onSurface,
        disabledColor: colorScheme.onSurface.withOpacity(0.2),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildGridButton(int value, String label, {bool isHighlight = false}) {
    final isSelected = _offset == value;
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest.withOpacity(0.35);

    final borderColor = isSelected
        ? colorScheme.primary
        : isHighlight
            ? colorScheme.primary.withOpacity(0.4)
            : colorScheme.outlineVariant.withOpacity(0.35);

    final textColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface.withOpacity(0.85);

    return InkWell(
      onTap: () => setState(() => _offset = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected || isHighlight ? FontWeight.bold : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
