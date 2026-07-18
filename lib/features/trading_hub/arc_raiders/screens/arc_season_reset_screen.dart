import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcSeasonResetScreen extends StatefulWidget {
  const ArcSeasonResetScreen({super.key});

  static const routeName = '/trading-hub/arc-raiders/season-reset';

  @override
  State<ArcSeasonResetScreen> createState() => _ArcSeasonResetScreenState();
}

class _ArcSeasonResetScreenState extends State<ArcSeasonResetScreen> {
  final ArcSeasonResetRepository _repository = ArcSeasonResetRepository();
  late final Future<_ResetScreenData> _future = _load();
  bool _confirmed = false;
  bool _applying = false;
  ArcSeasonResetApplyResult? _result;

  Future<_ResetScreenData> _load() async {
    await _repository.ensureSeasonStateExists();
    await _repository.reconcileInterruptedReset();
    final state = await _repository.getSeasonState();
    final preview = await _repository.createResetPreview();
    return _ResetScreenData(state: state, preview: preview);
  }

  Future<void> _apply(ArcSeasonResetPreview preview) async {
    if (_applying || !_confirmed) return;
    setState(() => _applying = true);
    try {
      final result = await _repository.applyReset(preview);
      if (!mounted) return;
      setState(() {
        _result = result;
        _confirmed = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expedition reset complete.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reset failed safely: $error')));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _returnToCommandCentre() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      ArcCommandCentreScreen.routeName,
      (route) => route.settings.name == ArcCommandCentreScreen.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const ArcCompanionBottomDock(activeLabel: 'Command'),
      body: ArcRaidersScreenShell(
        useSafeArea: true,
        showAdBanner: true,
        child: FutureBuilder<_ResetScreenData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.neonCyan),
              );
            }
            if (snapshot.hasError) {
              return ArcRaidersPageList(
                maxWidth: 840,
                bottomPadding: 120,
                children: [
                  ArcRaidersPageHeader(
                    title: 'EXPEDITION RESET',
                    subtitle: 'Preview unavailable',
                    icon: Icons.warning_amber_rounded,
                    accent: AppTheme.tradingDanger,
                  ),
                  ArcRaidersSectionCard(
                    accent: AppTheme.tradingDanger,
                    child: Text(
                      'Reset preview could not load: ${snapshot.error}',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              );
            }
            final data = snapshot.data;
            if (data == null) return const SizedBox.shrink();
            if (_result != null) {
              return _completionView(_result!);
            }
            return _previewView(data);
          },
        ),
      ),
    );
  }

  Widget _previewView(_ResetScreenData data) {
    final state = data.state;
    final preview = data.preview;
    final blocked = state.resetStatus == ArcSeasonResetStatus.inProgress;
    return ArcRaidersPageList(
      maxWidth: 920,
      bottomPadding: 120,
      children: [
        ArcRaidersPageHeader(
          title: 'START EXPEDITION RESET',
          subtitle:
              'Archive the current season and begin ${preview.nextSeasonId}. No changes happen until you confirm.',
          icon: Icons.restart_alt_rounded,
          accent: AppTheme.neonPink,
        ),
        _statusCard(state, preview),
        _impactSection(
          title: 'WHAT RESETS',
          impacts: preview.impactsFor(ArcSeasonResetClassification.reset),
          accent: AppTheme.neonPink,
        ),
        _staticPolicySection(
          title: 'WHAT PERSISTS',
          items: ArcSeasonResetPolicy.persistentSystems,
          accent: AppTheme.neonCyan,
        ),
        _impactSection(
          title: 'WHAT RECALCULATES',
          impacts: preview.impactsFor(
            ArcSeasonResetClassification.recalculated,
          ),
          accent: Colors.amberAccent,
        ),
        _staticPolicySection(
          title: 'MANUAL RECONFIRMATION',
          items: ArcSeasonResetPolicy.manualReconfirmSystems,
          accent: Colors.orangeAccent,
        ),
        ArcRaidersSectionCard(
          accent: AppTheme.neonPink,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                value: _confirmed,
                onChanged: blocked
                    ? null
                    : (value) => setState(() => _confirmed = value == true),
                activeColor: AppTheme.neonPink,
                checkColor: Colors.black,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I understand this archives current-season tracker and Operation progress. Profile, reputation, legal consent and permanent rewards remain.',
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    isBold: true,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _applying
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: blocked || !_confirmed || _applying
                          ? null
                          : () => _apply(preview),
                      icon: _applying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restart_alt_rounded),
                      label: Text(
                        blocked ? 'Reset In Progress' : 'Confirm Reset',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _completionView(ArcSeasonResetApplyResult result) {
    return ArcRaidersPageList(
      maxWidth: 860,
      bottomPadding: 120,
      children: [
        ArcRaidersPageHeader(
          title: 'EXPEDITION RESET COMPLETE',
          subtitle:
              '${result.archivedSeasonId} archived. ${result.currentSeasonId} is now active.',
          icon: Icons.task_alt_rounded,
          accent: AppTheme.neonCyan,
        ),
        ArcRaidersSectionCard(
          accent: AppTheme.neonCyan,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metricRow('New season', result.currentSeasonId),
              _metricRow('Archived season', result.archivedSeasonId),
              _metricRow('Reset ID', result.resetId),
              _metricRow('Reset version', result.resetVersion.toString()),
              _metricRow(
                'Tracker docs reset',
                result.resetStateIds.length.toString(),
              ),
              _metricRow(
                'Operations archived',
                result.archivedOperationIds.length.toString(),
              ),
              _metricRow(
                'Rewards preserved',
                result.archivedRewardCount.toString(),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Text(
                'Next: rebuild early-season quest, Scrappy, bench and Operation progress from Command Centre.',
                style: AppTheme.bodyTextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              ElevatedButton.icon(
                onPressed: _returnToCommandCentre,
                icon: const Icon(Icons.dashboard_customize_rounded),
                label: const Text('Return To Command Centre'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusCard(ArcSeasonState state, ArcSeasonResetPreview preview) {
    return ArcRaidersSectionCard(
      accent: AppTheme.neonCyan,
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: AppTheme.spaceM,
        runSpacing: AppTheme.spaceM,
        children: [
          _metricTile('Current season', preview.currentSeasonId),
          _metricTile('Next season', preview.nextSeasonId),
          _metricTile('Reset version', preview.resetVersion.toString()),
          _metricTile('Reset status', state.resetStatus.name),
          _metricTile('Scrappy docs', preview.scrappyStateCount.toString()),
          _metricTile('Quest docs', preview.questStateCount.toString()),
          _metricTile('Bench docs', preview.benchStateCount.toString()),
          _metricTile('Operations', preview.operationProgressCount.toString()),
          _metricTile('Vault rewards', preview.rewardCount.toString()),
        ],
      ),
    );
  }

  Widget _impactSection({
    required String title,
    required List<ArcSeasonResetSystemImpact> impacts,
    required Color accent,
  }) {
    return ArcRaidersSectionCard(
      accent: accent,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.tradingHeading(fontSize: 20, color: accent),
          ),
          const SizedBox(height: AppTheme.spaceM),
          for (final impact in impacts) _impactRow(impact, accent),
        ],
      ),
    );
  }

  Widget _staticPolicySection({
    required String title,
    required List<String> items,
    required Color accent,
  }) {
    return ArcRaidersSectionCard(
      accent: accent,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.tradingHeading(fontSize: 20, color: accent),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                Chip(
                  label: Text(item),
                  backgroundColor: Colors.black.withValues(alpha: 0.28),
                  side: BorderSide(color: accent.withValues(alpha: 0.28)),
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _impactRow(ArcSeasonResetSystemImpact impact, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hexagon_outlined, size: 16, color: accent),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  impact.itemCount > 0
                      ? '${impact.label} (${impact.itemCount})'
                      : impact.label,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    isBold: true,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  impact.reason,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 210),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: AppTheme.tradingCardDecoration(
          borderColor: AppTheme.neonCyan.withValues(alpha: 0.16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTheme.bodyTextStyle(
                fontSize: 10,
                color: Colors.white54,
                isBold: true,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.tradingHeading(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: Colors.white60,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: Colors.white,
                isBold: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetScreenData {
  const _ResetScreenData({required this.state, required this.preview});

  final ArcSeasonState state;
  final ArcSeasonResetPreview preview;
}
