import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../build/app_drawer.dart';
import '../../../../widgets/theme.dart';
import '../widgets/arc_companion_bottom_dock.dart';
import '../widgets/arc_raiders_screen_shell.dart';
import '../widgets/foundation/arc_ui_tokens.dart';

class ArcFutureHubScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/future-hub';
  const ArcFutureHubScreen({super.key});

  @override
  State<ArcFutureHubScreen> createState() => _ArcFutureHubScreenState();
}

class _ArcFutureHubScreenState extends State<ArcFutureHubScreen> {
  static const _ideas = [
    (
      'DOA?',
      'EXFIL SURVIVAL INTELLIGENCE',
      'Estimate whether you can reach extraction in time, then grow into fastest/safest route intelligence.',
      Icons.timer_outlined,
      'IN DEVELOPMENT',
    ),
    (
      'TRADE LOCKER',
      'SURPLUS & DUPLICATE INVENTORY',
      'Track what you own, what you will trade and what you still need.',
      Icons.inventory_2_outlined,
      'EXPLORING',
    ),
    (
      'UAG GIVES',
      'COMMUNITY IMPACT',
      'Start with tangible giving such as verified hospital wish lists, then publish what the UAG community actually helped provide.',
      Icons.volunteer_activism_outlined,
      'EXPLORING',
    ),
    (
      'COMMUNITY IDEAS',
      'YOU HELP SHAPE UAG',
      'Submit feature ideas and vote on suggestions from other Raiders.',
      Icons.lightbulb_outline_rounded,
      'LIVE',
    ),
  ];

  Future<void> _suggest() async {
    final controller = TextEditingController();
    final details = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ArcUiTokens.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
          side: BorderSide(
            color: ArcUiTokens.secondaryAccent.withValues(alpha: 0.34),
          ),
        ),
        title: Text(
          'SUGGEST A UAG FEATURE',
          style: ArcUiTokens.sectionTitle(
            fontSize: 18,
            color: ArcUiTokens.secondaryAccent,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLength: 80,
                style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                decoration: ArcUiTokens.inputDecoration(
                  labelText: 'Idea title',
                  hintText: 'What should UAG add?',
                  prefixIcon: Icons.lightbulb_outline_rounded,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: details,
                maxLength: 500,
                maxLines: 5,
                style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                decoration: ArcUiTokens.inputDecoration(
                  labelText: 'What should it do?',
                  hintText:
                      'Describe the player problem and the useful outcome.',
                  prefixIcon: Icons.notes_rounded,
                ).copyWith(alignLabelWithHint: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: ArcUiTokens.textButtonStyle(
              accent: ArcUiTokens.textSecondary,
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: ArcUiTokens.textButtonStyle(
              accent: ArcUiTokens.secondaryAccent,
              primary: true,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );

    final title = controller.text.trim();
    final detailText = details.text.trim();
    controller.dispose();
    details.dispose();

    if (result != true || title.length < 3) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to submit a community idea.')),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('uag_community_suggestions')
          .add({
            'title': title,
            'details': detailText,
            'uid': user.uid,
            'status': 'open',
            'createdAt': FieldValue.serverTimestamp(),
            'voteCount': 0,
          });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Suggestion submitted.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not submit your suggestion. Try again.'),
          ),
        );
      }
    }
  }

  Future<void> _toggleVote(String id, bool voted) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to vote on community ideas.')),
        );
      }
      return;
    }
    final ref = FirebaseFirestore.instance
        .collection('uag_community_suggestions')
        .doc(id)
        .collection('votes')
        .doc(user.uid);
    try {
      if (voted) {
        await ref.delete();
      } else {
        await ref.set({
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update your vote. Try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      bottomNavigationBar: const ArcCompanionBottomDock(activeLabel: 'systems'),
      backgroundColor: Colors.transparent,
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final width = c.maxWidth > 1180 ? 1180.0 : c.maxWidth;
              return Center(
                child: SizedBox(
                  width: width,
                  child: ListView(
                    padding: ArcUiTokens.screenPadding,
                    children: [
                      const ArcRaidersPageHeader(
                        title: 'FUTURE HUB',
                        subtitle: 'Roadmap signals and community ideas.',
                        icon: Icons.timeline_rounded,
                        accent: ArcUiTokens.secondaryAccent,
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          ArcTacticalStatusPill(
                            label: 'Community votes',
                            icon: Icons.how_to_vote_rounded,
                            accent: ArcUiTokens.primaryAccent,
                          ),
                          ArcTacticalStatusPill(
                            label: 'Identity safe',
                            icon: Icons.verified_user_outlined,
                            accent: ArcUiTokens.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 980
                              ? 4
                              : constraints.maxWidth >= 640
                              ? 2
                              : 1;
                          const spacing = 10.0;
                          final cardWidth =
                              (constraints.maxWidth - spacing * (columns - 1)) /
                              columns;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              for (final idea in _ideas)
                                SizedBox(
                                  width: cardWidth,
                                  child: _RoadmapCard(idea: idea),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppTheme.spaceL),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'COMMUNITY SUGGESTIONS',
                              style: ArcUiTokens.sectionTitle(
                                fontSize: 17,
                                color: ArcUiTokens.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _suggest,
                            icon: const Icon(Icons.add),
                            label: const Text('SUGGEST'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceS),
                      _SuggestionsFeed(onToggleVote: _toggleVote),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoadmapCard extends StatelessWidget {
  const _RoadmapCard({required this.idea});
  final (String, String, String, IconData, String) idea;
  @override
  Widget build(BuildContext context) => ArcRaidersSectionCard(
    accent: idea.$5 == 'LIVE'
        ? ArcUiTokens.success
        : idea.$5 == 'IN DEVELOPMENT'
        ? ArcUiTokens.secondaryAccent
        : ArcUiTokens.primaryAccent,
    padding: const EdgeInsets.all(ArcUiTokens.gapM),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(idea.$4, color: ArcUiTokens.primaryAccent, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      idea.$1,
                      style: AppTheme.heroTextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _StatusChip(idea.$5),
                ],
              ),
              Text(
                idea.$2,
                style: AppTheme.bodyTextStyle(
                  fontSize: 11,
                  color: ArcUiTokens.secondaryAccent,
                  isBold: true,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                idea.$3,
                style: AppTheme.bodyTextStyle(
                  fontSize: 13,
                  color: AppTheme.tradingMutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.neonCyan.withValues(alpha: .5)),
    ),
    child: Text(
      text,
      style: AppTheme.bodyTextStyle(
        fontSize: 9,
        color: AppTheme.neonCyan,
        isBold: true,
      ),
    ),
  );
}

class _SuggestionsFeed extends StatelessWidget {
  const _SuggestionsFeed({required this.onToggleVote});
  final Future<void> Function(String, bool) onToggleVote;
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('uag_community_suggestions')
          .where('status', isEqualTo: 'open')
          .limit(30)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const ArcRaidersStatePanel(
            title: 'Loading suggestions',
            message: 'Checking the current community queue.',
            icon: Icons.sync_rounded,
            compact: true,
          );
        }
        if (snap.hasError) {
          return const ArcRaidersStatePanel(
            title: 'Suggestions unavailable',
            message: 'Community suggestions could not load right now.',
            icon: Icons.cloud_off_rounded,
            accent: ArcUiTokens.warning,
            compact: true,
          );
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const ArcRaidersStatePanel(
            title: 'No suggestions yet',
            message: 'Add the first idea for the next UAG system.',
            icon: Icons.lightbulb_outline_rounded,
            accent: ArcUiTokens.primaryAccent,
            compact: true,
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: doc.reference.collection('votes').snapshots(),
              builder: (context, votesSnap) {
                final votes = votesSnap.data?.docs ?? const [];
                final voted =
                    uid != null && votes.any((vote) => vote.id == uid);
                return ArcRaidersSectionCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(ArcUiTokens.gapM),
                  accent: voted
                      ? ArcUiTokens.secondaryAccent
                      : ArcUiTokens.primaryAccent,
                  child: Row(
                    children: [
                      Column(
                        children: [
                          IconButton(
                            onPressed: uid == null
                                ? null
                                : () => onToggleVote(doc.id, voted),
                            icon: Icon(
                              voted
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_upward_outlined,
                              color: voted
                                  ? AppTheme.neonPink
                                  : AppTheme.neonCyan,
                            ),
                          ),
                          Text(
                            '${votes.length}',
                            style: AppTheme.bodyTextStyle(
                              fontSize: 11,
                              color: AppTheme.neonCyan,
                              isBold: true,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['title'] ?? 'Community idea'}',
                              style: AppTheme.bodyTextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                isBold: true,
                              ),
                            ),
                            if ('${data['details'] ?? ''}'.trim().isNotEmpty)
                              Text(
                                '${data['details']}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.bodyTextStyle(
                                  fontSize: 12,
                                  color: AppTheme.tradingMutedText,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
