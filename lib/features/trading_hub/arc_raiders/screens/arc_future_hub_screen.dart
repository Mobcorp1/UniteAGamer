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
      'Maintain what you own, what you will trade and what you need once — then let Smart Trade use it.',
      Icons.inventory_2_outlined,
      'PLANNED',
    ),
    (
      'UAG GIVES',
      'COMMUNITY IMPACT',
      'Start with tangible giving such as verified hospital wish lists, then publish what the UAG community actually helped provide.',
      Icons.volunteer_activism_outlined,
      'ROADMAP',
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
        backgroundColor: ArcUiTokens.surface,
        title: const Text('Suggest a UAG feature'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Idea title'),
              ),
              TextField(
                controller: details,
                maxLength: 500,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'What should it do?',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
    if (result != true || controller.text.trim().length < 3) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('uag_community_suggestions')
        .add({
          'title': controller.text.trim(),
          'details': details.text.trim(),
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
  }

  Future<void> _toggleVote(String id, bool voted) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('uag_community_suggestions')
        .doc(id)
        .collection('votes')
        .doc(user.uid);
    if (voted) {
      await ref.delete();
    } else {
      await ref.set({
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
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
              final width = c.maxWidth > 980 ? 980.0 : c.maxWidth;
              return Center(
                child: SizedBox(
                  width: width,
                  child: ListView(
                    padding: ArcUiTokens.screenPadding,
                    children: [
                      Text(
                        'FUTURE HUB',
                        style: AppTheme.heroTextStyle(
                          fontSize: 32,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'WHAT UAG IS BUILDING TOWARD',
                        style: AppTheme.bodyTextStyle(
                          fontSize: 13,
                          color: AppTheme.neonPink,
                          isBold: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Not everything here is another app feature. The roadmap includes smarter ARC tools, stronger community systems and a wider positive impact as UAG grows.',
                        style: AppTheme.bodyTextStyle(
                          fontSize: 14,
                          color: AppTheme.tradingMutedText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._ideas.map((idea) => _RoadmapCard(idea: idea)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'COMMUNITY SUGGESTIONS',
                              style: AppTheme.heroTextStyle(
                                fontSize: 22,
                                color: AppTheme.neonCyan,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _suggest,
                            icon: const Icon(Icons.add),
                            label: const Text('SUGGEST'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: ArcUiTokens.surface.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.neonCyan.withValues(alpha: .22)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(idea.$4, color: AppTheme.neonCyan, size: 30),
        const SizedBox(width: 12),
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
                        fontSize: 20,
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
                  color: AppTheme.neonPink,
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
        if (snap.hasError) {
          return Text(
            'Suggestions are temporarily unavailable.',
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: AppTheme.tradingMutedText,
            ),
          );
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return Text(
            'No suggestions yet. Be the first Raider to add one.',
            style: AppTheme.bodyTextStyle(
              fontSize: 13,
              color: AppTheme.tradingMutedText,
            ),
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ArcUiTokens.surface.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(12),
                  ),
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
