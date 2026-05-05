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
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

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
        .limit(6);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'Admin Console',
        subtitle: 'Feature releases, tester feedback and control tools.',
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: ListView(
                  padding: AppTheme.pagePadding,
                  children: [
                    Text(
                      'Feature Access',
                      style: AppTheme.tradingHeading(fontSize: 26),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    Text(
                      'Flip these live to open or close testing without redeploying the app.',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 14,
                        color: AppTheme.tradingMutedText,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: configRef.snapshots(),
                      builder: (context, snapshot) {
                        final data =
                            snapshot.data?.data() ?? <String, dynamic>{};
                        return Column(
                          children: [
                            _FeatureToggleCard(
                              title: 'Scrappy Tracker',
                              subtitle:
                                  'Resource tracking and collection testing.',
                              value: data['scrappyTrackerEnabled'] == true,
                              onChanged: (value) => configRef.set({
                                'scrappyTrackerEnabled': value,
                              }, SetOptions(merge: true)),
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            _FeatureToggleCard(
                              title: 'Trader Hub',
                              subtitle:
                                  'Listings, offers, sessions and alerts.',
                              value: data['traderHubEnabled'] == true,
                              onChanged: (value) => configRef.set({
                                'traderHubEnabled': value,
                              }, SetOptions(merge: true)),
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            _FeatureToggleCard(
                              title: 'Match Raider',
                              subtitle:
                                  'Private matchmaking and objective pairing.',
                              value: data['matchRaiderEnabled'] == true,
                              onChanged: (value) => configRef.set({
                                'matchRaiderEnabled': value,
                              }, SetOptions(merge: true)),
                            ),
                            const SizedBox(height: AppTheme.spaceM),
                            _FeatureToggleCard(
                              title: 'PlayLocker Pro',
                              subtitle:
                                  'Performance and prep tools for future testing.',
                              value: data['playLockerProEnabled'] == true,
                              onChanged: (value) => configRef.set({
                                'playLockerProEnabled': value,
                              }, SetOptions(merge: true)),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spaceXL),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Latest Feedback',
                            style: AppTheme.tradingHeading(fontSize: 26),
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
                          label: const Text('Open Inbox'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    Text(
                      'See where messages are coming from and jump straight into the inbox to reply.',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 14,
                        color: AppTheme.tradingMutedText,
                      ),
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
                          return Container(
                            padding: AppTheme.sectionCardPadding,
                            decoration: AppTheme.tradingCardDecoration(
                              borderColor: AppTheme.tradingDanger.withValues(
                                alpha: 0.35,
                              ),
                            ),
                            child: Text(
                              'Could not load feedback overview.',
                              style: AppTheme.bodyTextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          );
                        }

                        final docs =
                            snapshot.data?.docs ??
                            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                        if (docs.isEmpty) {
                          return Container(
                            padding: AppTheme.sectionCardPadding,
                            decoration: AppTheme.tradingCardDecoration(),
                            child: Text(
                              'No feedback has been submitted yet.',
                              style: AppTheme.bodyTextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: docs
                              .map((doc) {
                                final data = doc.data();
                                final status = (data['status'] ?? 'new')
                                    .toString();
                                final category = (data['category'] ?? 'Other')
                                    .toString();
                                final summary = (data['summary'] ?? '')
                                    .toString();
                                final email = (data['email'] ?? '').toString();
                                final updatedAt =
                                    (data['updatedAt'] as Timestamp?)?.toDate();
                                final when = updatedAt == null
                                    ? 'Pending timestamp'
                                    : updatedAt.toLocal().toString().substring(
                                        0,
                                        16,
                                      );

                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(
                                    bottom: AppTheme.spaceM,
                                  ),
                                  padding: AppTheme.sectionCardPadding,
                                  decoration: AppTheme.tradingCardDecoration(),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _pill(category, AppTheme.neonCyan),
                                          _pill(
                                            status.toUpperCase(),
                                            AppTheme.neonPink,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppTheme.spaceM),
                                      Text(
                                        summary,
                                        style: AppTheme.tradingHeading(
                                          fontSize: 20,
                                        ),
                                      ),
                                      const SizedBox(height: AppTheme.spaceS),
                                      Text(
                                        email.isNotEmpty
                                            ? email
                                            : 'Unknown sender',
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
                                    ],
                                  ),
                                );
                              })
                              .toList(growable: false),
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

class _FeatureToggleCard extends StatelessWidget {
  const _FeatureToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.tradingHeading(fontSize: 22)),
                const SizedBox(height: 6),
                Text(
                  subtitle,
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
