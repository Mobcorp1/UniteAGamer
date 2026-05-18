import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_traders_hub/build/app_bar.dart';
import 'package:uag_traders_hub/build/app_drawer.dart';
import 'package:uag_traders_hub/screens/build/feedback_screen.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class AdminConsoleScreen extends StatelessWidget {
  static const routeName = '/admin-console';

  const AdminConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: const UagAppBar(
          title: 'Admin Console',
          subtitle: 'Sign in required.',
        ),
        drawer: const AppDrawer(),
        body: const Center(
          child: Text(
            'Sign in to access admin tools.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() ?? <String, dynamic>{};
        final canAccess =
            userData['isAdmin'] == true || userData['isDev'] == true;

        if (!canAccess) {
          return Scaffold(
            backgroundColor: AppTheme.darkBackground,
            appBar: const UagAppBar(
              title: 'Admin Console',
              subtitle: 'Restricted to admin and dev accounts.',
            ),
            drawer: const AppDrawer(),
            body: Stack(
              children: [
                const Positioned.fill(child: StaticWatermark()),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: AppTheme.pagePadding,
                      child: Container(
                        width: double.infinity,
                        padding: AppTheme.sectionCardPadding,
                        decoration: AppTheme.tradingCardDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: AppTheme.neonPink,
                              size: 36,
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            Text(
                              'Access Restricted',
                              style: AppTheme.tradingHeading(fontSize: 26),
                            ),
                            const SizedBox(height: AppTheme.spaceS),
                            Text(
                              'This area is only available to admin or dev accounts.',
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyTextStyle(
                                fontSize: 15,
                                color: AppTheme.tradingMutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const _AdminConsoleBody();
      },
    );
  }
}

class _AdminFeature {
  const _AdminFeature({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
}

const List<_AdminFeature> _featureToggles = [
  _AdminFeature(
    key: 'blueprintTrackerEnabled',
    title: 'Blueprint Tracker',
    subtitle: 'Soft-launch safe core blueprint collection grid.',
    icon: Icons.grid_view_rounded,
  ),
  _AdminFeature(
    key: 'intelExplorerEnabled',
    title: 'Intel Explorer',
    subtitle: 'Community drop reports, confidence and report drilldowns.',
    icon: Icons.travel_explore_rounded,
  ),
  _AdminFeature(
    key: 'raidPlannerEnabled',
    title: 'Raid Planner',
    subtitle: 'Blueprint-to-event planning and route intelligence.',
    icon: Icons.map_rounded,
  ),
  _AdminFeature(
    key: 'scrappyTrackerEnabled',
    title: 'Scrappy Tracker',
    subtitle: 'Scrappy item tracking, surplus and upgrade collection.',
    icon: Icons.inventory_2_rounded,
  ),
  _AdminFeature(
    key: 'benchTrackerEnabled',
    title: 'Bench Tracker',
    subtitle: 'Bench upgrade resources and crafting progression.',
    icon: Icons.handyman_rounded,
  ),
  _AdminFeature(
    key: 'questTrackerEnabled',
    title: 'Quest Tracker',
    subtitle: 'Quest requirement collection tracking.',
    icon: Icons.assignment_turned_in_rounded,
  ),
  _AdminFeature(
    key: 'traderHubEnabled',
    title: 'Trader Hub',
    subtitle: 'Listings, offers, trade sessions and trader reputation.',
    icon: Icons.swap_horiz_rounded,
  ),
  _AdminFeature(
    key: 'matchRaiderEnabled',
    title: 'Match Raider',
    subtitle: 'Private player matching and objective pairing.',
    icon: Icons.groups_rounded,
  ),
  _AdminFeature(
    key: 'playLockerProEnabled',
    title: 'Play Like A Pro',
    subtitle: 'Prep, tilt control and performance coaching tools.',
    icon: Icons.sports_esports_rounded,
  ),
  _AdminFeature(
    key: 'voiceAssistantEnabled',
    title: 'Voice Assistant',
    subtitle: 'Voice search, item lookups and assistant access.',
    icon: Icons.mic_rounded,
  ),
  _AdminFeature(
    key: 'monetisationEnabled',
    title: 'Monetisation',
    subtitle: 'Plan screens, entitlement testing and paid-access controls.',
    icon: Icons.workspace_premium_rounded,
  ),
];

class _AdminConsoleBody extends StatelessWidget {
  const _AdminConsoleBody();

  @override
  Widget build(BuildContext context) {
    final configRef = FirebaseFirestore.instance
        .collection('config')
        .doc('feature_access');

    final feedbackQuery = FirebaseFirestore.instance
        .collection('beta_feedback')
        .orderBy('updatedAt', descending: true)
        .limit(12);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'Admin Console',
        subtitle: 'Feature releases, tester feedback and beta controls.',
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: ListView(
                  padding: AppTheme.pagePadding,
                  children: [
                    _sectionHeader(
                      title: 'Feature Access',
                      subtitle:
                          'Turn modules on or off live without redeploying. Use this for soft-launch control and staged testing.',
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: configRef.snapshots(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data() ?? {};
                        return Wrap(
                          spacing: AppTheme.spaceM,
                          runSpacing: AppTheme.spaceM,
                          children: [
                            for (final feature in _featureToggles)
                              SizedBox(
                                width: 520,
                                child: _FeatureToggleCard(
                                  feature: feature,
                                  value: data[feature.key] == true,
                                  onChanged: (value) async {
                                    await configRef.set({
                                      feature.key: value,
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    }, SetOptions(merge: true));
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spaceXL),
                    Row(
                      children: [
                        Expanded(
                          child: _sectionHeader(
                            title: 'Latest Feedback',
                            subtitle:
                                'Action, reopen or delete tester feedback without leaving the admin console.',
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              FeedbackScreen.routeName,
                              arguments: const FeedbackScreenArgs(
                                initialTabIndex: 2,
                              ),
                            );
                          },
                          icon: const Icon(Icons.inbox_outlined),
                          label: const Text('Open Full Inbox'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: feedbackQuery.snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.neonCyan,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return _messageCard(
                            'Could not load feedback overview.',
                            AppTheme.tradingDanger,
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return _messageCard(
                            'No feedback has been submitted yet.',
                            AppTheme.neonCyan,
                          );
                        }

                        return Column(
                          children: [
                            for (final doc in docs)
                              _FeedbackAdminCard(
                                id: doc.id,
                                data: doc.data(),
                                onActioned: () => _updateFeedbackStatus(
                                  context,
                                  doc.reference,
                                  'actioned',
                                ),
                                onReopen: () => _updateFeedbackStatus(
                                  context,
                                  doc.reference,
                                  'new',
                                ),
                                onDelete: () =>
                                    _deleteFeedback(context, doc.reference),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.tradingHeading(fontSize: 26)),
        const SizedBox(height: AppTheme.spaceS),
        Text(
          subtitle,
          style: AppTheme.bodyTextStyle(
            fontSize: 14,
            color: AppTheme.tradingMutedText,
          ),
        ),
      ],
    );
  }

  static Widget _messageCard(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: color.withValues(alpha: 0.35),
      ),
      child: Text(
        text,
        style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70),
      ),
    );
  }

  static Future<void> _updateFeedbackStatus(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
    String status,
  ) async {
    await ref.set({
      'status': status,
      'actionedAt': status == 'actioned' ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Feedback marked $status.')));
  }

  static Future<void> _deleteFeedback(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackgroundDeep,
          title: Text(
            'Delete feedback?',
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.tradingDanger,
            ),
          ),
          content: const Text(
            'This removes the feedback entry from Firestore. Use this for spam, duplicate test entries or fully handled noise.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tradingDanger,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ref.delete();

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feedback deleted.')));
  }
}

class _FeatureToggleCard extends StatelessWidget {
  const _FeatureToggleCard({
    required this.feature,
    required this.value,
    required this.onChanged,
  });

  final _AdminFeature feature;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = value ? AppTheme.neonPink : AppTheme.neonCyan;
    return Container(
      width: double.infinity,
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: color.withValues(alpha: value ? 0.42 : 0.18),
      ),
      child: Row(
        children: [
          Icon(feature.icon, color: color, size: 28),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: AppTheme.tradingHeading(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  feature.subtitle,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 14,
                    color: AppTheme.tradingMutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceM),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppTheme.neonPink,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FeedbackAdminCard extends StatelessWidget {
  const _FeedbackAdminCard({
    required this.id,
    required this.data,
    required this.onActioned,
    required this.onReopen,
    required this.onDelete,
  });

  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onActioned;
  final VoidCallback onReopen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'new').toString();
    final category = (data['category'] ?? 'Other').toString();
    final summary = (data['summary'] ?? data['message'] ?? '').toString();
    final email = (data['email'] ?? data['userEmail'] ?? '').toString();
    final screen = (data['screen'] ?? data['source'] ?? '').toString();
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
    final when = updatedAt == null
        ? 'Pending timestamp'
        : updatedAt.toLocal().toString().substring(0, 16);

    final isActioned = status.toLowerCase() == 'actioned';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: isActioned
            ? Colors.lightGreenAccent.withValues(alpha: 0.28)
            : AppTheme.neonPink.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(category, AppTheme.neonCyan),
              _pill(status.toUpperCase(), AppTheme.neonPink),
              if (screen.isNotEmpty) _pill(screen, Colors.amberAccent),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            summary.isEmpty ? 'No summary provided.' : summary,
            style: AppTheme.tradingHeading(fontSize: 20),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            email.isNotEmpty ? email : 'Unknown sender',
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: AppTheme.tradingMutedText,
              isBold: true,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Updated: $when',
            style: AppTheme.bodyTextStyle(
              fontSize: 12,
              color: AppTheme.tradingFaintText,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: [
              OutlinedButton.icon(
                onPressed: isActioned ? onReopen : onActioned,
                icon: Icon(
                  isActioned
                      ? Icons.replay_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                label: Text(isActioned ? 'Reopen' : 'Mark Actioned'),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.tradingDanger,
                  side: BorderSide(
                    color: AppTheme.tradingDanger.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: AppTheme.pillPadding,
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
