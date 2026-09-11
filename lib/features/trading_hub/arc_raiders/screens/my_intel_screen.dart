import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class MyIntelScreen extends StatelessWidget {
  const MyIntelScreen({super.key});

  static const routeName = '/my-intel';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      drawer: const AppDrawer(),
      bottomNavigationBar: const ArcCompanionBottomDock(
        activeLabel: 'My Intel',
      ),
      appBar: const UagAppBar(
        title: 'My Intel',
        subtitle: 'Your submitted ARC intelligence reports',
        showLogout: false,
      ),
      body: ArcRaidersScreenShell(
        showAdBanner: false,
        child: SafeArea(
          child: user == null
              ? const Center(
                  child: ArcRaidersStatePanel(
                    title: 'Sign in required',
                    message:
                        'Sign in to review the intelligence reports linked to your Raider profile.',
                    icon: Icons.lock_person_outlined,
                    accent: ArcUiTokens.warning,
                  ),
                )
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('arc_blueprint_drop_reports')
                      .where('userId', isEqualTo: user.uid)
                      .limit(30)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: ArcRaidersStatePanel(
                            title: 'My Intel unavailable',
                            message:
                                'Your submitted reports could not load right now.',
                            icon: Icons.cloud_off_rounded,
                            accent: ArcUiTokens.warning,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: ArcRaidersStatePanel(
                            title: 'Syncing your intel',
                            message:
                                'Loading your latest submitted field reports.',
                            icon: Icons.radar_rounded,
                            accent: ArcUiTokens.primaryAccent,
                            compact: true,
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs.toList()
                      ..sort((a, b) {
                        final aTime = _readTime(a.data());
                        final bTime = _readTime(b.data());
                        return bTime.compareTo(aTime);
                      });

                    final latest = docs.take(5).toList();

                    if (latest.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: ArcRaidersStatePanel(
                            title: 'No intel reports yet',
                            message:
                                'Your latest community intelligence submissions will appear here.',
                            icon: Icons.radar_rounded,
                            accent: ArcUiTokens.primaryAccent,
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const ArcRaidersPageHeader(
                                title: 'MY INTEL',
                                subtitle:
                                    'Recent reports attached to your Raider identity.',
                                icon: Icons.radar_rounded,
                                accent: ArcUiTokens.primaryAccent,
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              _IntelHero(totalReports: docs.length),
                              const SizedBox(height: AppTheme.spaceM),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ArcTacticalStatusPill(
                                    label: '${docs.length} submitted',
                                    icon: Icons.article_outlined,
                                    accent: ArcUiTokens.primaryAccent,
                                  ),
                                  ArcTacticalStatusPill(
                                    label: '${latest.length} shown',
                                    icon: Icons.history_rounded,
                                    accent: ArcUiTokens.secondaryAccent,
                                  ),
                                  const ArcTacticalStatusPill(
                                    label: 'Raider linked',
                                    icon: Icons.verified_user_outlined,
                                    accent: ArcUiTokens.success,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              for (final doc in latest) ...[
                                _IntelReportCard(doc: doc),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  static DateTime _readTime(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final foundAt = data['foundAt'];
    final lastConfirmedAt = data['lastConfirmedAt'];

    if (createdAt is Timestamp) return createdAt.toDate();
    if (lastConfirmedAt is Timestamp) return lastConfirmedAt.toDate();
    if (foundAt is Timestamp) return foundAt.toDate();

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _IntelHero extends StatelessWidget {
  const _IntelHero({required this.totalReports});

  final int totalReports;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: ArcUiTokens.primaryAccent,
        radius: ArcUiTokens.radiusL,
        borderOpacity: 0.24,
        glow: true,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.radar_rounded,
            color: ArcUiTokens.primaryAccent,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LATEST INTEL // $totalReports REPORT${totalReports == 1 ? '' : 'S'}',
                  style: ArcUiTokens.sectionTitle(fontSize: 17),
                ),
                const SizedBox(height: 5),
                Text(
                  'Review or correct your latest field reports before they feed your personal intelligence history.',
                  style: ArcUiTokens.bodySmall(
                    color: ArcUiTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntelReportCard extends StatelessWidget {
  const _IntelReportCard({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  String _text(String key, {String fallback = 'Unknown'}) {
    final value = doc.data()[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  int _int(String key) {
    final value = doc.data()[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final blueprintId = _text('blueprintId', fallback: 'Unknown Blueprint');
    final mapName = _text('mapName');
    final location = _text(
      'locationName',
      fallback: _text('poiName', fallback: _text('enemySourceName')),
    );
    final container = _text(
      'containerTypeLabel',
      fallback: 'Container unknown',
    );
    final condition = _text(
      'conditionLabel',
      fallback: _text(
        'mapEventLabel',
        fallback: _text('weatherConditionLabel', fallback: 'No condition'),
      ),
    );
    final notes = _text('notes', fallback: '');
    final confirmations = _int('confirmationCount');

    return ArcRaidersSectionCard(
      accent: ArcUiTokens.primaryAccent,
      radius: ArcUiTokens.radiusL,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.article_outlined,
                color: ArcUiTokens.primaryAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  blueprintId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.sectionTitle(
                    fontSize: 14,
                    color: ArcUiTokens.primaryAccent,
                  ),
                ),
              ),
              _IntelBadge(label: '$confirmations confirm'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _IntelChip(icon: Icons.map_outlined, label: mapName),
              _IntelChip(icon: Icons.place_outlined, label: location),
              _IntelChip(icon: Icons.inventory_2_outlined, label: container),
              _IntelChip(icon: Icons.cloud_outlined, label: condition),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              notes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ArcUiTokens.primaryAccent,
                    side: BorderSide(
                      color: ArcUiTokens.primaryAccent.withValues(alpha: 0.38),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                    ),
                  ),
                  onPressed: () => _editReport(context, doc),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteReport(context, doc),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ArcUiTokens.secondaryAccent,
                    side: BorderSide(
                      color: ArcUiTokens.secondaryAccent.withValues(
                        alpha: 0.45,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editReport(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();

    final blueprint = TextEditingController(
      text: (data['blueprintId'] as String?) ?? '',
    );
    final map = TextEditingController(text: (data['mapName'] as String?) ?? '');
    final location = TextEditingController(
      text:
          (data['locationName'] as String?) ??
          (data['poiName'] as String?) ??
          (data['enemySourceName'] as String?) ??
          '',
    );
    final container = TextEditingController(
      text: (data['containerTypeLabel'] as String?) ?? '',
    );
    final condition = TextEditingController(
      text:
          (data['conditionLabel'] as String?) ??
          (data['mapEventLabel'] as String?) ??
          (data['weatherConditionLabel'] as String?) ??
          '',
    );
    final notes = TextEditingController(text: (data['notes'] as String?) ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ArcUiTokens.surfaceOverlay,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
            side: BorderSide(
              color: ArcUiTokens.primaryAccent.withValues(alpha: 0.28),
            ),
          ),
          title: Text(
            'Edit Intel Report',
            style: ArcUiTokens.sectionTitle(
              fontSize: 18,
              color: ArcUiTokens.primaryAccent,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _dialogField(blueprint, 'Blueprint / item'),
                _dialogField(map, 'Map'),
                _dialogField(location, 'Location / POI'),
                _dialogField(container, 'Container / source'),
                _dialogField(condition, 'Condition / event'),
                _dialogField(notes, 'Notes', maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: ArcUiTokens.textButtonStyle(
                accent: ArcUiTokens.primaryAccent,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton.icon(
              style: ArcUiTokens.textButtonStyle(
                accent: ArcUiTokens.primaryAccent,
                primary: true,
              ),
              onPressed: () async {
                await doc.reference.set({
                  'blueprintId': blueprint.text.trim(),
                  'mapName': map.text.trim(),
                  'locationName': location.text.trim(),
                  'poiName': location.text.trim(),
                  'containerTypeLabel': container.text.trim(),
                  'conditionLabel': condition.text.trim(),
                  'mapEventLabel': condition.text.trim(),
                  'notes': notes.text.trim(),
                  'editedAt': FieldValue.serverTimestamp(),
                  'userEdited': true,
                }, SetOptions(merge: true));

                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Intel report updated.')),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
          ],
        );
      },
    );

    blueprint.dispose();
    map.dispose();
    location.dispose();
    container.dispose();
    condition.dispose();
    notes.dispose();
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
        decoration: ArcUiTokens.inputDecoration(labelText: label),
      ),
    );
  }

  Future<void> _deleteReport(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ArcUiTokens.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
          side: BorderSide(
            color: ArcUiTokens.secondaryAccent.withValues(alpha: 0.30),
          ),
        ),
        title: Text(
          'Delete Intel Report?',
          style: ArcUiTokens.sectionTitle(
            fontSize: 18,
            color: ArcUiTokens.secondaryAccent,
          ),
        ),
        content: Text(
          'This removes your report from community intel. Use this if you submitted the wrong item, map, source or condition.',
          style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
        ),
        actions: [
          TextButton(
            style: ArcUiTokens.textButtonStyle(
              accent: ArcUiTokens.secondaryAccent,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            style: ArcUiTokens.textButtonStyle(
              accent: ArcUiTokens.secondaryAccent,
              primary: true,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await doc.reference.delete();

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Intel report deleted.')));
  }
}

class _IntelChip extends StatelessWidget {
  const _IntelChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ArcTacticalStatusPill(
      label: label,
      icon: icon,
      accent: ArcUiTokens.primaryAccent,
    );
  }
}

class _IntelBadge extends StatelessWidget {
  const _IntelBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ArcTacticalStatusPill(
      label: label,
      icon: Icons.verified_outlined,
      accent: ArcUiTokens.secondaryAccent,
    );
  }
}
