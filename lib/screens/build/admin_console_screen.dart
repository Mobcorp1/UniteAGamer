import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_beta_first_run.dart';
import 'package:uag_arc_raiders_hub/screens/build/feedback_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class AdminConsoleScreen extends StatelessWidget {
  static const routeName = '/admin-console';

  const AdminConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
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
            backgroundColor: Colors.transparent,
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

        return _AdminConsoleBody(uid: uid);
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
  const _AdminConsoleBody({required this.uid});

  final String uid;

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
      backgroundColor: Colors.transparent,
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
                    _sectionHeader(
                      title: 'Closed Beta Tools',
                      subtitle:
                          'Admin-only reset controls for onboarding, tutorial replay and beta testing utilities.',
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                    const ArcBetaDeveloperToolsCard(),
                    const SizedBox(height: AppTheme.spaceL),
                    _ClosedBetaDiagnosticsCard(uid: uid),
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

class _ClosedBetaDiagnosticsCard extends StatelessWidget {
  const _ClosedBetaDiagnosticsCard({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ClosedBetaDiagnosticsData>(
      future: _load(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: AppTheme.sectionCardPadding,
            decoration: AppTheme.tradingCardDecoration(),
            child: const LinearProgressIndicator(color: AppTheme.neonCyan),
          );
        }

        if (snapshot.hasError) {
          return _AdminConsoleBody._messageCard(
            'Closed beta diagnostics could not be loaded.',
            AppTheme.tradingDanger,
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return _AdminConsoleBody._messageCard(
            'Closed beta diagnostics are unavailable.',
            AppTheme.tradingDanger,
          );
        }

        return Container(
          width: double.infinity,
          padding: AppTheme.sectionCardPadding,
          decoration: AppTheme.tradingCardDecoration(
            borderColor: AppTheme.neonCyan.withValues(alpha: 0.24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.monitor_heart_outlined,
                    color: AppTheme.neonCyan,
                  ),
                  const SizedBox(width: AppTheme.spaceS),
                  Expanded(
                    child: Text(
                      'Closed Beta Diagnostics',
                      style: AppTheme.tradingHeading(fontSize: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                'Read-only production checks for season, tracker, Operations and Reward Vault state.',
                style: AppTheme.bodyTextStyle(
                  fontSize: 13,
                  color: AppTheme.tradingMutedText,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Wrap(
                spacing: AppTheme.spaceM,
                runSpacing: AppTheme.spaceM,
                children: [
                  _diagnosticMetric('User', data.uid),
                  _diagnosticMetric('Season', data.currentSeasonId),
                  _diagnosticMetric('Reset', data.resetStatus),
                  _diagnosticMetric('Version', data.resetVersion.toString()),
                  _diagnosticMetric(
                    'Onboarding',
                    data.onboardingComplete ? 'Complete' : 'Incomplete',
                  ),
                  _diagnosticMetric(
                    'Profile',
                    data.profileComplete ? 'Complete' : 'Incomplete',
                  ),
                  _diagnosticMetric(
                    'Legal',
                    data.legalComplete ? 'Accepted' : 'Missing',
                  ),
                  _diagnosticMetric(
                    'Tracker docs',
                    data.trackerStateCount.toString(),
                  ),
                  _diagnosticMetric(
                    'Operations',
                    '${data.completedOperations}/${data.operationCount} done',
                  ),
                  _diagnosticMetric(
                    'Claimed',
                    data.claimedOperations.toString(),
                  ),
                  _diagnosticMetric('Rewards', data.ownedRewards.toString()),
                  _diagnosticMetric(
                    'Current rewards',
                    data.currentSeasonRewards.toString(),
                  ),
                  _diagnosticMetric(
                    'Historical',
                    data.historicalRewards.toString(),
                  ),
                  _diagnosticMetric(
                    'Equipped',
                    data.equippedCosmeticCount.toString(),
                  ),
                  _diagnosticMetric(
                    'Beta',
                    data.betaEligible ? 'Eligible' : 'Not flagged',
                  ),
                  _diagnosticMetric(
                    'Founder',
                    data.founderEligible ? 'Eligible' : 'Not flagged',
                  ),
                ],
              ),
              if (data.missingProfileFields.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceM),
                _diagnosticNote(
                  'Missing profile fields',
                  data.missingProfileFields.join(', '),
                ),
              ],
              if (data.lastResetId.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceM),
                _diagnosticNote('Last reset', data.lastResetId),
              ],
              if (data.lastReconciliation.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceM),
                _diagnosticNote('Last reconciliation', data.lastReconciliation),
              ],
              const SizedBox(height: AppTheme.spaceM),
              _candidateDiagnostics(data.candidates),
            ],
          ),
        );
      },
    );
  }

  static Widget _diagnosticMetric(String label, String value) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 250),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTheme.bodyTextStyle(
                fontSize: 11,
                color: AppTheme.tradingMutedText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 14,
                color: Colors.white,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _diagnosticNote(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTheme.bodyTextStyle(
            fontSize: 13,
            color: AppTheme.tradingMutedText,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  static Widget _candidateDiagnostics(List<_CommandCandidateDiagnostic> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Command Centre Candidate Diagnostics',
            style: AppTheme.tradingHeading(
              fontSize: 18,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.included
                        ? Icons.check_circle_rounded
                        : Icons.remove_circle_outline_rounded,
                    color: item.included
                        ? AppTheme.neonCyan
                        : AppTheme.tradingMutedText,
                    size: 16,
                  ),
                  const SizedBox(width: AppTheme.spaceS),
                  Expanded(
                    child: Text(
                      '${item.id} - ${item.title} | ${item.status} | ${item.reason}',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Future<_ClosedBetaDiagnosticsData> _load(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(uid);
    final profileRef = userRef.collection('trading_activity').doc('profile');
    final seasonRef = userRef.collection('arc_season_state').doc('current');
    final trackerRef = userRef.collection('arc_scrappy_states');
    final operationSummaryRef = firestore
        .collection('arc_operation_progress')
        .doc(uid);
    final operationsRef = operationSummaryRef.collection('operations');
    final rewardRef = firestore
        .collection('arc_rewards_inventory')
        .doc(uid)
        .collection('items');
    final equippedRef = firestore.collection('arc_equipped_cosmetics').doc(uid);
    final telemetryRef = firestore
        .collection('arc_operation_telemetry')
        .doc(uid);

    final userData = (await userRef.get()).data() ?? const <String, dynamic>{};
    final profileData =
        (await profileRef.get()).data() ?? const <String, dynamic>{};
    final seasonData =
        (await seasonRef.get()).data() ?? const <String, dynamic>{};
    final trackerDocs = (await trackerRef.get()).docs;
    final operationSummary =
        (await operationSummaryRef.get()).data() ?? const <String, dynamic>{};
    final operationDocs = (await operationsRef.get()).docs;
    final rewardDocs = (await rewardRef.get()).docs;
    final equippedData =
        (await equippedRef.get()).data() ?? const <String, dynamic>{};
    final telemetryData =
        (await telemetryRef.get()).data() ?? const <String, dynamic>{};

    final profileCompletion = _map(
      profileData['profileCompletion'],
      _map(userData['profileCompletion']),
    );
    final arcOnboarding = _map(userData['arcOnboarding']);
    final legalAccepted = _map(userData['legalAccepted']);
    final missingProfileFields = _stringList(
      profileCompletion['missingFieldLabels'],
    );

    final completedOperations = operationDocs.where((doc) {
      final data = doc.data();
      final progress = (data['progress'] as num?)?.toInt() ?? 0;
      final target = (data['target'] as num?)?.toInt() ?? 1;
      return target > 0 && progress >= target;
    }).length;
    final claimedOperations = operationDocs
        .where((doc) => doc.data()['claimed'] == true)
        .length;
    final equippedCosmeticCount = <String>[
      _string(equippedData['equippedBadgeId']),
      _string(equippedData['equippedTitleId']),
      _string(equippedData['equippedProfileFrameId']),
      _string(equippedData['equippedProfileBannerId']),
      _string(profileData['equippedBadgeId']),
      _string(profileData['equippedTitleId']),
      _string(profileData['equippedProfileFrameId']),
      _string(profileData['equippedProfileBannerId']),
    ].where((value) => value.isNotEmpty).toSet().length;

    return _ClosedBetaDiagnosticsData(
      uid: uid,
      currentSeasonId: _string(seasonData['currentSeasonId']).isNotEmpty
          ? _string(seasonData['currentSeasonId'])
          : 'closed-beta-season-1',
      resetStatus: _string(seasonData['resetStatus']).isNotEmpty
          ? _string(seasonData['resetStatus'])
          : 'idle',
      resetVersion: (seasonData['resetVersion'] as num?)?.toInt() ?? 0,
      lastResetId: _string(seasonData['lastResetId']),
      lastReconciliation: _formatReconciliation(
        operationSummary['lastRewardReconciliation'],
      ),
      onboardingComplete:
          arcOnboarding['completed'] == true ||
          arcOnboarding['completedAt'] != null,
      profileComplete:
          profileCompletion['complete'] == true ||
          profileData['isProfileComplete'] == true,
      legalComplete:
          legalAccepted['termsAccepted'] == true &&
          legalAccepted['privacyAccepted'] == true,
      trackerStateCount: trackerDocs.length,
      operationCount: operationDocs.length,
      completedOperations: completedOperations,
      claimedOperations: claimedOperations,
      ownedRewards: rewardDocs.length,
      currentSeasonRewards: rewardDocs
          .where((doc) => doc.data()['currentSeasonUnlock'] != false)
          .length,
      historicalRewards: rewardDocs
          .where((doc) => doc.data()['currentSeasonUnlock'] == false)
          .length,
      equippedCosmeticCount: equippedCosmeticCount,
      betaEligible:
          _truthy(userData['closedBetaParticipant']) ||
          _truthy(userData['betaParticipant']) ||
          _truthy(telemetryData['closedBetaParticipant']),
      founderEligible:
          _truthy(userData['founder']) ||
          _truthy(userData['founderEligible']) ||
          _truthy(userData['earlySupporter']),
      missingProfileFields: missingProfileFields,
      candidates: _buildCandidateDiagnostics(
        profileComplete:
            profileCompletion['complete'] == true ||
            profileData['isProfileComplete'] == true,
        trackerStateCount: trackerDocs.length,
        operationDocs: operationDocs,
        rewardDocs: rewardDocs,
        userData: userData,
      ),
    );
  }

  static List<_CommandCandidateDiagnostic> _buildCandidateDiagnostics({
    required bool profileComplete,
    required int trackerStateCount,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> operationDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> rewardDocs,
    required Map<String, dynamic> userData,
  }) {
    final readyOperations = operationDocs.where((doc) {
      final data = doc.data();
      final progress = (data['progress'] as num?)?.toInt() ?? 0;
      final target = (data['target'] as num?)?.toInt() ?? 1;
      return progress >= target && data['claimed'] != true;
    }).length;
    final activeOperations = operationDocs.where((doc) {
      final data = doc.data();
      final progress = (data['progress'] as num?)?.toInt() ?? 0;
      final target = (data['target'] as num?)?.toInt() ?? 1;
      return progress > 0 && progress < target;
    }).length;
    final currentRewards = rewardDocs
        .where((doc) => doc.data()['currentSeasonUnlock'] != false)
        .length;
    final hasLoadout =
        _truthy(userData['favouriteLoadoutSaved']) ||
        _truthy(userData['hasFavouriteLoadout']);
    return [
      _candidate(
        id: 'complete-profile',
        title: 'Complete Profile',
        type: 'profile',
        included: !profileComplete,
        reason: profileComplete
            ? 'Excluded: persisted profile completion is true.'
            : 'Included: profile completion is missing.',
        priority: profileComplete ? 0 : 100,
      ),
      _candidate(
        id: 'active-quest',
        title: 'Active Quest',
        type: 'quest',
        included: trackerStateCount > 0,
        reason: trackerStateCount > 0
            ? 'Included: quest/tracker documents exist.'
            : 'Excluded: no quest tracker progress documents found.',
        priority: trackerStateCount > 0 ? 70 : 0,
      ),
      _candidate(
        id: 'scrappy',
        title: 'Scrappy',
        type: 'tracker',
        included: trackerStateCount > 0,
        reason: trackerStateCount > 0
            ? 'Included: tracker state can produce Scrappy guidance.'
            : 'Excluded: no Scrappy tracker state exists yet.',
        priority: trackerStateCount > 0 ? 68 : 0,
      ),
      _candidate(
        id: 'bench',
        title: 'Bench',
        type: 'tracker',
        included: trackerStateCount > 0,
        reason: trackerStateCount > 0
            ? 'Included: bench intelligence can read tracker documents.'
            : 'Excluded: no bench tracker state exists yet.',
        priority: trackerStateCount > 0 ? 66 : 0,
      ),
      _candidate(
        id: 'operation',
        title: 'Operation',
        type: 'operation',
        included: readyOperations > 0 || activeOperations > 0,
        reason: readyOperations > 0
            ? 'Included: $readyOperations Operation reward ready to claim.'
            : activeOperations > 0
            ? 'Included: $activeOperations Operation in progress.'
            : 'Excluded: no active or ready Operation progress.',
        priority: readyOperations > 0
            ? 80
            : activeOperations > 0
            ? 60
            : 0,
      ),
      _candidate(
        id: 'favourite-loadout',
        title: 'Favourite Loadout',
        type: 'loadout',
        included: !hasLoadout,
        reason: hasLoadout
            ? 'Excluded: user has durable loadout proof.'
            : 'Included: no durable loadout proof found in user summary.',
        priority: hasLoadout ? 0 : 55,
      ),
      _candidate(
        id: 'blueprint-tracker',
        title: 'Blueprint Tracker',
        type: 'blueprint',
        included: true,
        reason: 'Included when blueprint state is available to Command Centre.',
        priority: 50,
      ),
      _candidate(
        id: 'trade-offer',
        title: 'Trade Offer',
        type: 'trade',
        included: false,
        reason:
            'Excluded in diagnostics snapshot: trade offer stream is not loaded here.',
        priority: 0,
      ),
      _candidate(
        id: 'blueprint-watch',
        title: 'Blueprint Watch',
        type: 'trade',
        included: false,
        reason:
            'Excluded in diagnostics snapshot: watch stream is not loaded here.',
        priority: 0,
      ),
      _candidate(
        id: 'listing-queue',
        title: 'Listing Queue',
        type: 'trade',
        included: false,
        reason:
            'Excluded in diagnostics snapshot: queue stream is not loaded here.',
        priority: 0,
      ),
      _candidate(
        id: 'match-rider',
        title: 'Match Rider',
        type: 'matchmaking',
        included: false,
        reason:
            'Excluded unless Match Rider repository reports active requests in Command Centre.',
        priority: 0,
      ),
      _candidate(
        id: 'reward-vault',
        title: 'Reward Vault',
        type: 'reward',
        included: currentRewards > 0,
        reason: currentRewards > 0
            ? 'Included: $currentRewards current-season reward records.'
            : 'Excluded: no current-season reward records.',
        priority: currentRewards > 0 ? 45 : 0,
      ),
    ];
  }

  static _CommandCandidateDiagnostic _candidate({
    required String id,
    required String title,
    required String type,
    required bool included,
    required String reason,
    required int priority,
  }) {
    return _CommandCandidateDiagnostic(
      id: id,
      title: title,
      type: type,
      status: included ? 'included' : 'excluded',
      reason: reason,
      priority: priority,
      included: included,
      suppressionKey: '$type:$id',
    );
  }

  static Map<String, dynamic> _map(dynamic value, [dynamic fallback]) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    if (fallback != null) return _map(fallback);
    return const <String, dynamic>{};
  }

  static List<String> _stringList(dynamic value) {
    if (value is! Iterable) return const <String>[];
    return value.map(_string).where((item) => item.isNotEmpty).toList();
  }

  static String _string(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static bool _truthy(dynamic value) {
    if (value == true) return true;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == 'yes';
    }
    return false;
  }

  static String _formatReconciliation(dynamic value) {
    final map = _map(value);
    if (map.isEmpty) return '';
    final version = _string(map['version']);
    final granted = _stringList(map['grantedRewardIds']).length;
    final owned = _stringList(map['alreadyOwnedRewardIds']).length;
    final updatedAt = _string(map['updatedAt']);
    final parts = <String>[
      if (version.isNotEmpty) 'v$version',
      '$granted granted',
      '$owned already owned',
      if (updatedAt.isNotEmpty) updatedAt,
    ];
    return parts.join(' - ');
  }
}

class _ClosedBetaDiagnosticsData {
  const _ClosedBetaDiagnosticsData({
    required this.uid,
    required this.currentSeasonId,
    required this.resetStatus,
    required this.resetVersion,
    required this.lastResetId,
    required this.lastReconciliation,
    required this.onboardingComplete,
    required this.profileComplete,
    required this.legalComplete,
    required this.trackerStateCount,
    required this.operationCount,
    required this.completedOperations,
    required this.claimedOperations,
    required this.ownedRewards,
    required this.currentSeasonRewards,
    required this.historicalRewards,
    required this.equippedCosmeticCount,
    required this.betaEligible,
    required this.founderEligible,
    required this.missingProfileFields,
    required this.candidates,
  });

  final String uid;
  final String currentSeasonId;
  final String resetStatus;
  final int resetVersion;
  final String lastResetId;
  final String lastReconciliation;
  final bool onboardingComplete;
  final bool profileComplete;
  final bool legalComplete;
  final int trackerStateCount;
  final int operationCount;
  final int completedOperations;
  final int claimedOperations;
  final int ownedRewards;
  final int currentSeasonRewards;
  final int historicalRewards;
  final int equippedCosmeticCount;
  final bool betaEligible;
  final bool founderEligible;
  final List<String> missingProfileFields;
  final List<_CommandCandidateDiagnostic> candidates;
}

class _CommandCandidateDiagnostic {
  const _CommandCandidateDiagnostic({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.reason,
    required this.priority,
    required this.included,
    required this.suppressionKey,
  });

  final String id;
  final String title;
  final String type;
  final String status;
  final String reason;
  final int priority;
  final bool included;
  final String suppressionKey;
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
