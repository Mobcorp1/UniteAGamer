import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_cinematic_background.dart';

import 'arc_ui_tokens.dart';

/// Canonical scroll viewport for profile/account forms.
///
/// Width and page padding come from the ARC Operations OS layout system so
/// setup, edit, availability and away screens no longer carry their own
/// competing max-width and edge-spacing rules.
class ArcFormScrollView extends StatelessWidget {
  const ArcFormScrollView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.physics,
  });

  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return ArcPageViewport(
      width: ArcPageWidth.form,
      padding: EdgeInsets.zero,
      child: ListView(
        controller: controller,
        physics: physics,
        padding: padding ?? ArcLayoutTokens.pagePadding(context),
        children: children,
      ),
    );
  }
}

/// Responsive stat lane for profile/account support screens.
///
/// On Sony-class widths this resolves to one readable column. Tablet/desktop
/// progressively gain columns without allowing tiny, cramped stat cards.
class ArcFormStatGrid extends StatelessWidget {
  const ArcFormStatGrid({
    super.key,
    required this.children,
    this.minTileWidth = 190,
    this.maxColumns = 3,
  });

  final List<Widget> children;
  final double minTileWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return ArcAdaptiveGrid(
      minTileWidth: minTileWidth,
      maxColumns: maxColumns,
      children: children,
    );
  }
}

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
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        compact ? 12 : 14,
        compact ? 12 : 16,
        compact ? 12 : 14,
      ),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: accent,
        borderOpacity: 0.30,
        radius: ArcUiTokens.radiusXXL,
        glow: true,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.14,
              child: Image.asset(
                UagVisualAssets.arcBackground,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    ArcUiTokens.surfaceRaised.withValues(alpha: 0.98),
                    ArcUiTokens.surfaceRaised.withValues(alpha: 0.80),
                    ArcUiTokens.background.withValues(alpha: 0.56),
                  ],
                  stops: const [0.0, 0.62, 1.0],
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: compact ? 46 : 52,
                height: compact ? 46 : 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.20),
                      accent.withValues(alpha: 0.055),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
                  border: Border.all(color: accent.withValues(alpha: 0.42)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.08),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Icon(icon, color: accent, size: compact ? 23 : 26),
              ),
              SizedBox(width: compact ? 11 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ARC OPERATIONS',
                      style: ArcUiTokens.label(
                        color: accent,
                      ).copyWith(letterSpacing: 1.15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArcUiTokens.sectionTitle(
                        fontSize: compact ? 18 : 20,
                        color: ArcUiTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: compact ? 3 : 2,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: widget.margin,
      decoration: ArcUiTokens.surfaceDecoration(
        role: _expanded ? ArcSurfaceRole.raised : ArcSurfaceRole.panel,
        accent: widget.accent,
        borderOpacity: _expanded ? 0.34 : 0.15,
        radius: ArcUiTokens.radiusXXL,
        selected: _expanded,
        glow: _expanded,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.accent.withValues(
                            alpha: _expanded ? 0.22 : 0.13,
                          ),
                          widget.accent.withValues(alpha: 0.045),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                      border: Border.all(
                        color: widget.accent.withValues(
                          alpha: _expanded ? 0.46 : 0.25,
                        ),
                      ),
                    ),
                    child: Icon(widget.icon, color: widget.accent, size: 19),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: ArcUiTokens.sectionTitle(
                            fontSize: 15,
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
                              color: ArcUiTokens.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accent.withValues(
                        alpha: _expanded ? 0.12 : 0.05,
                      ),
                      border: Border.all(
                        color: widget.accent.withValues(
                          alpha: _expanded ? 0.34 : 0.12,
                        ),
                      ),
                    ),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 21,
                        color: _expanded
                            ? widget.accent
                            : ArcUiTokens.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        widget.accent.withValues(alpha: 0.34),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.children,
                  ),
                ),
              ],
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
