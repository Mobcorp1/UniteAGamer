import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Intel',
          style: AppTheme.tradingHeading(
            fontSize: 24,
            color: AppTheme.neonCyan,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _IntelBackdrop(),
          SafeArea(
            child: user == null
                ? const Center(
                    child: Text(
                      'Log in to view your intel reports.',
                      style: TextStyle(color: Colors.white70),
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
                        return _IntelMessage(
                          icon: Icons.warning_amber_rounded,
                          title: 'Could not load intel',
                          message: snapshot.error.toString(),
                          color: AppTheme.neonPink,
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs.toList()
                        ..sort((a, b) {
                          final aTime = _readTime(a.data());
                          final bTime = _readTime(b.data());
                          return bTime.compareTo(aTime);
                        });

                      final latest = docs.take(5).toList();

                      if (latest.isEmpty) {
                        return const _IntelMessage(
                          icon: Icons.radar_rounded,
                          title: 'No intel reports yet',
                          message:
                              'Your latest 5 reports will appear here once you start submitting intel.',
                          color: AppTheme.neonCyan,
                        );
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 30),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 980),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _IntelHero(),
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
        ],
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
  const _IntelHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.10),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.radar_rounded, color: AppTheme.neonCyan, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Latest Intel',
                  style: AppTheme.tradingHeading(
                    fontSize: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Review, correct or delete your last 5 submitted reports.',
                  style: TextStyle(color: Colors.white70, height: 1.3),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.article_outlined, color: AppTheme.neonCyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  blueprintId,
                  style: AppTheme.tradingHeading(
                    fontSize: 22,
                    color: AppTheme.neonCyan,
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
              style: const TextStyle(color: Colors.white70, height: 1.3),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
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
                    foregroundColor: AppTheme.neonPink,
                    side: BorderSide(
                      color: AppTheme.neonPink.withValues(alpha: 0.45),
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
          backgroundColor: AppTheme.cardBackgroundDeep,
          title: Text(
            'Edit Intel Report',
            style: AppTheme.tradingHeading(
              fontSize: 24,
              color: AppTheme.neonCyan,
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.28),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppTheme.neonCyan.withValues(alpha: 0.28),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.neonPink),
          ),
        ),
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
        backgroundColor: AppTheme.cardBackgroundDeep,
        title: Text(
          'Delete Intel Report?',
          style: AppTheme.tradingHeading(
            fontSize: 24,
            color: AppTheme.neonPink,
          ),
        ),
        content: const Text(
          'This removes your report from community intel. Use this if you submitted the wrong item, map, source or condition.',
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.neonCyan, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _IntelBadge extends StatelessWidget {
  const _IntelBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.neonPink.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTheme.neonPink.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.neonPink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _IntelMessage extends StatelessWidget {
  const _IntelMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTheme.tradingHeading(fontSize: 24, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntelBackdrop extends StatelessWidget {
  const _IntelBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/arc_raiders/hub/auth_bg_landscape.webp',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ArcRaidersScreenBackdrop(),
        ),
        Container(color: Colors.black.withValues(alpha: 0.66)),
        const ArcRaidersScreenBackdrop(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.86),
                AppTheme.darkBackground.withValues(alpha: 0.28),
                Colors.black.withValues(alpha: 0.96),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
