import 'package:flutter/material.dart';

import 'arc_ui_tokens.dart';

/// Shared compact visual language for account/profile forms.
///
/// This keeps setup/edit/availability/away surfaces aligned without changing
/// their repositories, persistence, validation or entitlement behaviour.
class ArcFormPageLead extends StatelessWidget {
  const ArcFormPageLead({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: accent,
        borderOpacity: 0.24,
        radius: ArcUiTokens.radiusL,
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 38 : 42,
            height: compact ? 38 : 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
              color: accent.withValues(alpha: 0.10),
              border: Border.all(color: accent.withValues(alpha: 0.34)),
            ),
            child: Icon(icon, color: accent, size: compact ? 21 : 23),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.sectionTitle(
                    fontSize: compact ? 16 : 18,
                    color: ArcUiTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.bodySmall(
                    color: ArcUiTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class ArcFormSectionCard extends StatelessWidget {
  const ArcFormSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.accent = ArcUiTokens.primaryAccent,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final String? subtitle;
  final Color accent;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: ArcUiTokens.compactPanelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: accent,
        borderOpacity: 0.16,
        radius: ArcUiTokens.radiusL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: ArcUiTokens.sectionTitle(
                    fontSize: 15,
                    color: ArcUiTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textTertiary),
            ),
          ],
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// Shared disclosure component for long UAG forms and information surfaces.
///
/// Keeps at-a-glance information visible while allowing detailed configuration
/// to stay collapsed until the Raider needs it. This is intentionally reusable
/// beyond Profile so Raid Planner, Community and Plans can converge later.
class ArcExpandableFormSection extends StatefulWidget {
  const ArcExpandableFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.summary,
    this.accent = ArcUiTokens.primaryAccent,
    this.initiallyExpanded = false,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final String? subtitle;
  final String? summary;
  final Color accent;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry margin;

  @override
  State<ArcExpandableFormSection> createState() =>
      _ArcExpandableFormSectionState();
}

class _ArcExpandableFormSectionState extends State<ArcExpandableFormSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: widget.accent,
        borderOpacity: _expanded ? 0.24 : 0.14,
        radius: ArcUiTokens.radiusL,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
                      color: widget.accent.withValues(alpha: 0.09),
                      border: Border.all(
                        color: widget.accent.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Icon(widget.icon, color: widget.accent, size: 17),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: ArcUiTokens.sectionTitle(
                            fontSize: 14,
                            color: ArcUiTokens.textPrimary,
                          ),
                        ),
                        if (!_expanded &&
                            widget.summary != null &&
                            widget.summary!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.summary!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ArcUiTokens.bodySmall(
                              color: ArcUiTokens.textTertiary,
                            ),
                          ),
                        ] else if (_expanded &&
                            widget.subtitle != null &&
                            widget.subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ArcUiTokens.bodySmall(
                              color: ArcUiTokens.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _expanded
                          ? widget.accent
                          : ArcUiTokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}
