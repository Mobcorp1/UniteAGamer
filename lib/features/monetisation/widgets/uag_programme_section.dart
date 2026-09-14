import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

/// A digestible, keyboard-accessible section using the existing ARC surfaces.
/// Children mount only when opened, avoiding hidden live dashboard listeners.
class UagProgrammeSection extends StatefulWidget {
  const UagProgrammeSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<UagProgrammeSection> createState() => _UagProgrammeSectionState();
}

class _UagProgrammeSectionState extends State<UagProgrammeSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: _expanded,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: ArcUiTokens.panelPadding,
                minimumSize: const Size(48, 64),
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(widget.icon, color: ArcUiTokens.primaryAccent),
                  const SizedBox(width: ArcUiTokens.gapM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: ArcUiTokens.cardTitle()),
                        const SizedBox(height: ArcUiTokens.gapXS),
                        Text(widget.subtitle, style: ArcUiTokens.bodySmall()),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(padding: ArcUiTokens.panelPadding, child: widget.child),
        ],
      ),
    );
  }
}
