import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/legal/models/uag_policy_catalog.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/arc_data_attribution_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/privacy_policy_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/terms_of_use_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Legal',
          style: ArcUiTokens.pageTitle(color: ArcUiTokens.primaryAccent),
        ),
      ),
      body: ArcTacticalPageList(
        width: ArcPageWidth.standard,
        maxWidth: 980,
        padding: ArcLayoutTokens.pagePadding(context),
        children: [
          const ArcTacticalPanel(
            icon: Icons.policy_outlined,
            title: 'Policy Command',
            subtitle:
                'Operational terms, privacy controls and source attribution for the UAG ARC Raiders Hub.',
            accent: ArcUiTokens.primaryAccent,
            child: SizedBox.shrink(),
          ),
          _LegalTile(
            title: 'Terms of Use',
            subtitle: 'Trading rules, account rules, and platform terms.',
            icon: Icons.description_outlined,
            onTap: () => _open(context, const TermsOfUseScreen()),
          ),
          _LegalTile(
            title: 'Privacy Policy',
            subtitle: 'How app data is handled inside the companion platform.',
            icon: Icons.privacy_tip_outlined,
            onTap: () => _open(context, const PrivacyPolicyScreen()),
          ),
          _LegalTile(
            title: 'Data Attribution',
            subtitle:
                'Community data, licensing, fan-project notice, and source use.',
            icon: Icons.dataset_linked_outlined,
            onTap: () => _open(context, const ArcDataAttributionScreen()),
          ),
          const ArcTacticalPanel(
            icon: Icons.folder_copy_outlined,
            title: 'Policy Catalogue',
            subtitle: 'Additional operational policy records and beta notices.',
            accent: ArcUiTokens.secondaryAccent,
            child: SizedBox.shrink(),
          ),
          for (final policy in UagPolicyCatalog.documents.where(
            (document) => !const <String>{
              'terms_of_use',
              'privacy_policy',
              'data_attribution',
            }.contains(document.id),
          ))
            _LegalTile(
              title: policy.title,
              subtitle: policy.summary,
              icon: policy.requiresLegalReview
                  ? Icons.gavel_outlined
                  : Icons.verified_user_outlined,
              onTap: () => _open(context, _PolicyDocumentScreen(policy)),
            ),
          ArcTacticalPanel(
            icon: Icons.info_outline_rounded,
            title: 'Fan Project Notice',
            accent: ArcUiTokens.secondaryAccent,
            child: Text(
              UagFanProjectNotice.text,
              style: ArcUiTokens.body(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyDocumentScreen extends StatelessWidget {
  const _PolicyDocumentScreen(this.policy);

  final UagPolicyDocument policy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          policy.title,
          style: ArcUiTokens.pageTitle(color: ArcUiTokens.primaryAccent),
        ),
      ),
      body: ArcTacticalPageList(
        width: ArcPageWidth.standard,
        maxWidth: 920,
        padding: ArcLayoutTokens.pagePadding(context),
        children: [
          ArcTacticalPanel(
            icon: policy.requiresLegalReview
                ? Icons.gavel_outlined
                : Icons.verified_user_outlined,
            title: policy.title,
            subtitle:
                'Version ${policy.version} - Effective ${policy.effectiveDate}',
            accent: policy.requiresLegalReview
                ? ArcUiTokens.warning
                : ArcUiTokens.primaryAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  policy.summary,
                  style: ArcUiTokens.sectionTitle(fontSize: 18),
                ),
                const SizedBox(height: ArcUiTokens.gapM),
                Text(policy.body, style: ArcUiTokens.body(fontSize: 13)),
                if (policy.requiresLegalReview) ...[
                  const SizedBox(height: ArcUiTokens.gapM),
                  Text(
                    UagPolicyCatalog.legalReviewNotice,
                    style: ArcUiTokens.body(
                      color: ArcUiTokens.warning,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(ArcUiTokens.gapL),
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.interactive,
            accent: ArcUiTokens.primaryAccent,
            borderOpacity: 0.18,
          ),
          child: Row(
            children: [
              Icon(icon, color: ArcUiTokens.primaryAccent, size: 22),
              const SizedBox(width: ArcUiTokens.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ArcUiTokens.cardTitle(fontSize: 16)),
                    const SizedBox(height: ArcUiTokens.gapXS),
                    Text(subtitle, style: ArcUiTokens.bodySmall()),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ArcUiTokens.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
