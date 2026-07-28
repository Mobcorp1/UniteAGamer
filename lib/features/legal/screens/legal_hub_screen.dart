import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/legal/models/uag_policy_catalog.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/arc_data_attribution_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/privacy_policy_screen.dart';
import 'package:uag_arc_raiders_hub/features/legal/screens/terms_of_use_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

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
        title: const Text('Legal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        children: [
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
          const SizedBox(height: AppTheme.spaceM),
          Text(
            'Policy Catalogue',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
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
          const SizedBox(height: AppTheme.spaceM),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            decoration: AppTheme.tradingCardDecoration(
              borderColor: AppTheme.neonPink.withValues(alpha: 0.14),
            ),
            child: const Text(
              UagFanProjectNotice.text,
              style: TextStyle(color: Colors.white70, height: 1.45),
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
        title: Text(policy.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            decoration: AppTheme.tradingCardDecoration(
              borderColor: AppTheme.neonCyan.withValues(alpha: 0.16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version ${policy.version} - Effective ${policy.effectiveDate}',
                  style: const TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: AppTheme.spaceM),
                Text(
                  policy.summary,
                  style: AppTheme.tradingHeading(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                Text(
                  policy.body,
                  style: const TextStyle(color: Colors.white70, height: 1.45),
                ),
                if (policy.requiresLegalReview) ...[
                  const SizedBox(height: AppTheme.spaceM),
                  Text(
                    UagPolicyCatalog.legalReviewNotice,
                    style: TextStyle(
                      color: AppTheme.neonPink.withValues(alpha: 0.9),
                      height: 1.35,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          decoration: AppTheme.tradingCardDecoration(
            borderColor: AppTheme.neonCyan.withValues(alpha: 0.14),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.neonCyan),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.tradingHeading(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
