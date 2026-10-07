import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_referral_terms_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/repositories/uag_community_referral_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_trade_value_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_value.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_asset_thumbnail.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcDuplicateBlueprintsScreen extends StatefulWidget {
  const ArcDuplicateBlueprintsScreen({super.key});

  static const routeName =
      '/trading-hub/arc-raiders/trading/duplicate-blueprints';

  @override
  State<ArcDuplicateBlueprintsScreen> createState() =>
      _ArcDuplicateBlueprintsScreenState();
}

class _ArcDuplicateBlueprintsScreenState
    extends State<ArcDuplicateBlueprintsScreen> {
  final ArcBlueprintRepository _blueprints = ArcBlueprintRepository();
  final UagCommunityReferralRepository _referrals =
      UagCommunityReferralRepository();

  ArcUagValueTier? _filterTier;
  bool _sharing = false;

  Color _tierColor(ArcUagValueTier tier) => switch (tier) {
    ArcUagValueTier.sPlus => Colors.amberAccent,
    ArcUagValueTier.s => ArcUiTokens.secondaryAccent,
    ArcUagValueTier.a => ArcUiTokens.primaryAccent,
    ArcUagValueTier.b => Colors.lightGreenAccent,
    ArcUagValueTier.c => ArcUiTokens.textSecondary,
  };

  List<_ValuedBlueprint> _duplicates(Map<String, ArcBlueprintState> states) {
    final result = <_ValuedBlueprint>[];
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final state =
          states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
      if (state.dupesOwned <= 0) continue;
      final profile = ArcBlueprintTradeValueCatalog.forBlueprint(blueprint);
      result.add(
        _ValuedBlueprint(blueprint: blueprint, state: state, value: profile),
      );
    }
    result.sort((a, b) {
      final valueCompare = b.value.tradeTier.sortWeight.compareTo(
        a.value.tradeTier.sortWeight,
      );
      if (valueCompare != 0) return valueCompare;
      final quantityCompare = b.state.dupesOwned.compareTo(a.state.dupesOwned);
      if (quantityCompare != 0) return quantityCompare;
      return a.blueprint.name.compareTo(b.blueprint.name);
    });
    return result;
  }

  List<_ValuedBlueprint> _needs(Map<String, ArcBlueprintState> states) {
    final result = <_ValuedBlueprint>[];
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final state =
          states[blueprint.id] ?? ArcBlueprintState.empty(blueprint.id);
      if (state.owned) continue;
      result.add(
        _ValuedBlueprint(
          blueprint: blueprint,
          state: state,
          value: ArcBlueprintTradeValueCatalog.forBlueprint(blueprint),
        ),
      );
    }
    result.sort((a, b) {
      final aPriority = a.state.priorityRank > 0 ? a.state.priorityRank : 999;
      final bPriority = b.state.priorityRank > 0 ? b.state.priorityRank : 999;
      final priorityCompare = aPriority.compareTo(bPriority);
      if (priorityCompare != 0) return priorityCompare;
      return ArcBlueprintTradeValueCatalog.compareBlueprints(
        a.blueprint,
        b.blueprint,
      );
    });
    return result;
  }

  int _totalTradeValue(List<_ValuedBlueprint> items) => items.fold<int>(
    0,
    (total, item) => total + item.value.tradePoints * item.state.dupesOwned,
  );

  Map<ArcUagValueTier, int> _tierCounts(List<_ValuedBlueprint> items) {
    final counts = <ArcUagValueTier, int>{
      for (final tier in ArcUagValueTier.values) tier: 0,
    };
    for (final item in items) {
      counts[item.value.tradeTier] =
          (counts[item.value.tradeTier] ?? 0) + item.state.dupesOwned;
    }
    return counts;
  }

  Future<bool> _ensureReferralTermsAccepted() async {
    final accepted = await _referrals.watchReferralTermsAccepted().first;
    if (accepted) return true;
    if (!mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ArcUiTokens.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        title: const Text('Activate Refer a Raider link'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Blueprint share link can also attribute genuine new UAG users to your referral account.',
              ),
              const SizedBox(height: 12),
              Text(
                'By continuing you accept Refer a Raider terms ${UagReferralTermsPolicy.version}.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final principle
                  in UagReferralTermsPolicy.requiredPrinciples.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $principle'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Accept & continue'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    await _referrals.acceptCurrentReferralTerms();
    return true;
  }

  Future<String?> _shareLink() async {
    final accepted = await _ensureReferralTermsAccepted();
    if (!accepted) return null;
    final code = await _referrals.ensureMyReferralCode();
    final base = _referrals.referralUri(code);
    return base
        .replace(
          queryParameters: <String, String>{
            ...base.queryParameters,
            'source': 'blueprint-trade-share',
          },
        )
        .toString();
  }

  String _buildShareMessage({
    required List<_ValuedBlueprint> duplicates,
    required List<_ValuedBlueprint> needs,
    required String link,
  }) {
    String lineFor(_ValuedBlueprint item, {bool showQuantity = false}) {
      final quantity = showQuantity ? ' ×${item.state.dupesOwned}' : '';
      return '${item.value.tradeTier.label} • ${item.blueprint.name}$quantity';
    }

    final topDuplicates = duplicates.take(6).toList(growable: false);
    final topNeeds = needs.take(6).toList(growable: false);
    final buffer = StringBuffer()
      ..writeln('Got any ARC Raiders blueprints to trade?')
      ..writeln()
      ..writeln(
        "I've put my duplicate blueprints and the ones I still need into the UAG ARC Raiders Hub.",
      );

    if (topDuplicates.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('I HAVE:');
      for (final item in topDuplicates) {
        buffer.writeln('• ${lineFor(item, showQuantity: true)}');
      }
      if (duplicates.length > topDuplicates.length) {
        buffer.writeln('• +${duplicates.length - topDuplicates.length} more');
      }
    }

    if (topNeeds.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('I NEED:');
      for (final item in topNeeds) {
        buffer.writeln('• ${lineFor(item)}');
      }
      if (needs.length > topNeeds.length) {
        buffer.writeln('• +${needs.length - topNeeds.length} more');
      }
    }

    buffer
      ..writeln()
      ..writeln(
        "Have I got anything you need — and have you got anything I'm missing?",
      )
      ..writeln()
      ..writeln(link)
      ..writeln()
      ..write('Built with UAG ARC Raiders Hub.');
    return buffer.toString();
  }

  Future<void> _copyOrShare({
    required List<_ValuedBlueprint> duplicates,
    required List<_ValuedBlueprint> needs,
    required bool nativeShare,
  }) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final link = await _shareLink();
      if (link == null || !mounted) return;
      final message = _buildShareMessage(
        duplicates: duplicates,
        needs: needs,
        link: link,
      );
      if (nativeShare) {
        await SharePlus.instance.share(
          ShareParams(
            text: message,
            subject: 'My UAG ARC Raiders Blueprint trades',
          ),
        );
      } else {
        await Clipboard.setData(ClipboardData(text: message));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Blueprint trade message copied. Paste it into PS App, WhatsApp, Discord or anywhere else.',
            ),
          ),
        );
      }
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('HAVE • NEED • TRADE'),
        actions: [
          IconButton(
            tooltip: 'Smart Trade Assist',
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(SmartTradeAssistScreen.routeName),
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
        ],
      ),
      body: ArcRaidersScreenShell(
        child: StreamBuilder<ArcBlueprintStateSnapshot>(
          stream: _blueprints.watchMyBlueprintStateSnapshot(),
          builder: (context, snapshot) {
            final stateSnapshot = snapshot.data;
            final states =
                stateSnapshot?.states ?? const <String, ArcBlueprintState>{};
            if (stateSnapshot == null || stateSnapshot.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (stateSnapshot.status ==
                    ArcBlueprintStateHydrationStatus.error &&
                states.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Blueprint inventory could not be loaded. Try again when your connection is restored.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final allDuplicates = _duplicates(states);
            final visibleDuplicates = _filterTier == null
                ? allDuplicates
                : allDuplicates
                      .where((item) => item.value.tradeTier == _filterTier)
                      .toList(growable: false);
            final needs = _needs(states);
            final totalValue = _totalTradeValue(allDuplicates);
            final counts = _tierCounts(allDuplicates);

            return ArcRaidersPageList(
              children: [
                _summaryCard(
                  duplicateItems: allDuplicates,
                  needs: needs,
                  totalValue: totalValue,
                  counts: counts,
                ),
                const SizedBox(height: 12),
                _shareCard(allDuplicates, needs),
                const SizedBox(height: 12),
                _tierFilter(counts),
                const SizedBox(height: 12),
                if (allDuplicates.isEmpty)
                  _emptyDuplicates()
                else if (visibleDuplicates.isEmpty)
                  const _SimplePanel(
                    icon: Icons.filter_alt_off_rounded,
                    title: 'No duplicates in this tier',
                    body: 'Choose another UAG Market Tier or select All.',
                  )
                else ...[
                  Text(
                    'DUPLICATES • HIGHEST VALUE FIRST',
                    style: ArcUiTokens.sectionTitle(
                      fontSize: 18,
                      color: ArcUiTokens.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final item in visibleDuplicates) ...[
                    _blueprintCard(item, duplicate: true),
                    const SizedBox(height: 8),
                  ],
                ],
                const SizedBox(height: 14),
                Text(
                  'WHAT I NEED',
                  style: ArcUiTokens.sectionTitle(
                    fontSize: 18,
                    color: ArcUiTokens.secondaryAccent,
                  ),
                ),
                const SizedBox(height: 8),
                if (needs.isEmpty)
                  const _SimplePanel(
                    icon: Icons.check_circle_rounded,
                    title: 'Blueprint collection complete',
                    body:
                        'You currently have every Blueprint in the tracked grid.',
                  )
                else
                  for (final item in needs.take(12)) ...[
                    _blueprintCard(item, duplicate: false),
                    const SizedBox(height: 8),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard({
    required List<_ValuedBlueprint> duplicateItems,
    required List<_ValuedBlueprint> needs,
    required int totalValue,
    required Map<ArcUagValueTier, int> counts,
  }) {
    final duplicateCopies = duplicateItems.fold<int>(
      0,
      (total, item) => total + item.state.dupesOwned,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.34,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR BLUEPRINT TRADE BOARD',
            style: ArcUiTokens.sectionTitle(
              fontSize: 22,
              color: ArcUiTokens.primaryAccent,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'UAG Market Tier ranks barter value separately from Embark rarity. 1 S+ = 2 S = 4 A = 8 B = 16 C.',
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric('DUPLICATES', '$duplicateCopies'),
              _metric('NEED', '${needs.length}'),
              _metric('UAG VALUE', '$totalValue'),
              for (final tier in ArcUagValueTier.values)
                if ((counts[tier] ?? 0) > 0)
                  _metric(
                    tier.label,
                    '${counts[tier]}',
                    color: _tierColor(tier),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shareCard(
    List<_ValuedBlueprint> duplicates,
    List<_ValuedBlueprint> needs,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: ArcUiTokens.secondaryAccent,
        borderOpacity: 0.28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SHARE YOUR HAVE / NEED LIST',
            style: ArcUiTokens.sectionTitle(
              fontSize: 18,
              color: ArcUiTokens.secondaryAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Copy a ready-made message for PlayStation App, WhatsApp or Discord, or use your phone share sheet. Your Refer a Raider attribution is built into the link.',
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _sharing
                    ? null
                    : () => _copyOrShare(
                        duplicates: duplicates,
                        needs: needs,
                        nativeShare: false,
                      ),
                icon: const Icon(Icons.copy_rounded),
                label: Text(_sharing ? 'PREPARING...' : 'COPY MESSAGE'),
              ),
              OutlinedButton.icon(
                onPressed: _sharing
                    ? null
                    : () => _copyOrShare(
                        duplicates: duplicates,
                        needs: needs,
                        nativeShare: true,
                      ),
                icon: const Icon(Icons.share_rounded),
                label: const Text('SHARE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tierFilter(Map<ArcUagValueTier, int> counts) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: _filterTier == null,
          onSelected: (_) => setState(() => _filterTier = null),
        ),
        for (final tier in ArcUagValueTier.values)
          ChoiceChip(
            label: Text('${tier.label} (${counts[tier] ?? 0})'),
            selected: _filterTier == tier,
            onSelected: (_) => setState(() => _filterTier = tier),
          ),
      ],
    );
  }

  Widget _emptyDuplicates() => const _SimplePanel(
    icon: Icons.inventory_2_outlined,
    title: 'No duplicate Blueprints available',
    body:
        'Add duplicate quantities in Blueprint Tracker and they will appear here automatically.',
  );

  Widget _blueprintCard(_ValuedBlueprint item, {required bool duplicate}) {
    final color = _tierColor(item.value.tradeTier);
    final points = item.value.tradePoints;
    final quantity = duplicate ? item.state.dupesOwned : 1;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: color,
        borderOpacity: 0.24,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: ArcAssetThumbnail(
              assetPath: item.blueprint.imageAssetPath ?? '',
              fallbackIcon: item.blueprint.icon,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.blueprint.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.body(
                    color: ArcUiTokens.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _pill('${item.value.tradeTier.label} MARKET', color),
                    _pill('$points pts', ArcUiTokens.primaryAccent),
                    if (item.value.gameplayTier != null)
                      _pill(
                        '${item.value.gameplayTier!.label} GAMEPLAY',
                        Colors.lightGreenAccent,
                      ),
                    _pill(
                      item.blueprint.rarityLabel,
                      ArcUiTokens.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  duplicate
                      ? '${item.state.dupesOwned} duplicate ${item.state.dupesOwned == 1 ? 'copy' : 'copies'} • ${points * quantity} total UAG value'
                      : item.state.priorityRank > 0
                      ? 'Wanted priority ${item.state.priorityRank} • $points UAG value'
                      : 'Missing • $points UAG value',
                  style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.10),
              border: Border.all(color: color.withValues(alpha: 0.55)),
            ),
            child: Text(
              duplicate
                  ? '×${item.state.dupesOwned}'
                  : item.value.tradeTier.label,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, {Color? color}) {
    final accent = color ?? ArcUiTokens.primaryAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Text(
        '$label  $value',
        style: TextStyle(color: accent, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      border: Border.all(color: color.withValues(alpha: 0.26)),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _ValuedBlueprint {
  const _ValuedBlueprint({
    required this.blueprint,
    required this.state,
    required this.value,
  });

  final ArcBlueprint blueprint;
  final ArcBlueprintState state;
  final ArcBlueprintValueProfile value;
}

class _SimplePanel extends StatelessWidget {
  const _SimplePanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ArcUiTokens.primaryAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ArcUiTokens.body(weight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(body, style: ArcUiTokens.bodySmall()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
