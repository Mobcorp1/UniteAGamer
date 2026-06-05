import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcKanbanColumn extends StatelessWidget {
  const ArcKanbanColumn({
    super.key,
    required this.title,
    required this.children,
    this.accent = AppTheme.neonCyan,
  });

  final String title;
  final List<Widget> children;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ArcGlassPanel(
      accent: accent,
      padding: const EdgeInsets.all(10),
      radius: 18,
      glow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTheme.neonTextStyle(fontSize: 13, color: accent),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
