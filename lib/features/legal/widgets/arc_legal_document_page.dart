import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class ArcLegalDocumentPage extends StatelessWidget {
  const ArcLegalDocumentPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.sections,
    this.footerText =
        'By continuing, you confirm you understand these terms as part of using the UAG Traders Hub beta.',
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<ArcLegalSection> sections;
  final String footerText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: ArcUiTokens.pageTitle(fontSize: 20, color: accent),
        ),
      ),
      body: ArcTacticalPageList(
        width: ArcPageWidth.standard,
        maxWidth: 980,
        padding: ArcLayoutTokens.pagePadding(context),
        children: [
          _LegalHero(title: title, subtitle: subtitle, accent: accent),
          for (final section in sections)
            _LegalSectionCard(section: section, accent: accent),
          _LegalFooter(accent: accent, text: footerText),
        ],
      ),
    );
  }
}

class ArcLegalSection {
  const ArcLegalSection(this.title, this.body, this.icon);

  final String title;
  final String body;
  final IconData icon;
}

class _LegalHero extends StatelessWidget {
  const _LegalHero({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    return ArcTacticalPanel(
      icon: Icons.policy_outlined,
      title: title,
      subtitle: subtitle,
      accent: accent,
      padding: EdgeInsets.all(compact ? ArcUiTokens.gapM : ArcUiTokens.gapXL),
      child: Wrap(
        spacing: ArcUiTokens.gapS,
        runSpacing: ArcUiTokens.gapS,
        children: [
          _LegalChip(label: 'TACTICAL LEGAL BRIEF', accent: accent),
          _LegalChip(label: 'BETA FRAMEWORK', accent: ArcUiTokens.warning),
          _LegalChip(label: 'COMMUNITY TRUST', accent: ArcUiTokens.success),
        ],
      ),
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({required this.section, required this.accent});

  final ArcLegalSection section;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return ArcTacticalPanel(
      accent: accent,
      padding: EdgeInsets.all(compact ? ArcUiTokens.gapM : ArcUiTokens.gapL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 34 : 38,
            height: compact ? 34 : 38,
            decoration: ArcUiTokens.surfaceDecoration(
              role: ArcSurfaceRole.interactive,
              accent: accent,
              radius: ArcUiTokens.radiusS,
              borderOpacity: 0.34,
            ),
            child: Icon(section.icon, color: accent, size: compact ? 18 : 21),
          ),
          const SizedBox(width: ArcUiTokens.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: ArcUiTokens.cardTitle(
                    fontSize: compact ? 14 : 16,
                    color: ArcUiTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapS),
                Text(section.body, style: ArcUiTokens.body(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalChip extends StatelessWidget {
  const _LegalChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ArcUiTokens.chipPadding,
      decoration: ArcUiTokens.chipDecoration(color: accent),
      child: Text(label, style: ArcUiTokens.label(color: accent)),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({required this.accent, required this.text});

  final Color accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ArcTacticalPanel(
      accent: accent,
      padding: const EdgeInsets.all(ArcUiTokens.gapM),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
      ),
    );
  }
}
