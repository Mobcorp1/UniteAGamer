import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_item_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_progression_workspace_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/screens/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum _CraftingPlannerMode { craft, recycle }

class ArcCraftingPlannerScreen extends StatefulWidget {
  const ArcCraftingPlannerScreen({super.key});

  static const routeName = '/trading-hub/arc-raiders/crafting';

  @override
  State<ArcCraftingPlannerScreen> createState() =>
      _ArcCraftingPlannerScreenState();
}

class _ArcCraftingPlannerScreenState extends State<ArcCraftingPlannerScreen> {
  final TextEditingController _search = TextEditingController();
  final ArcSavedLoadoutRepository _loadouts = ArcSavedLoadoutRepository();

  _CraftingPlannerMode _mode = _CraftingPlannerMode.craft;
  String _station = 'All';

  static const _stationOrder = <String>[
    'All',
    'Gunsmith',
    'Explosives',
    'Gear Bench',
    'Medical',
    'Utility',
    'Refiner',
    'Workbench',
    'In Raid',
    'Field Craft',
    'Other',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ArcItemIntelligenceItem> get _visibleItems {
    final source = _mode == _CraftingPlannerMode.craft
        ? ArcItemIntelligenceEngine.craftables
        : ArcItemIntelligenceEngine.recyclables;
    final query = ArcItemIntelligenceEngine.normalise(_search.text);

    final filtered =
        source
            .where((item) {
              final stationMatches =
                  _station == 'All' || item.primaryStation == _station;
              if (!stationMatches) return false;
              if (query.isEmpty) return true;

              final haystack = ArcItemIntelligenceEngine.normalise(
                '${item.name} ${item.id} ${item.aliases.join(' ')} '
                '${item.primaryStation} ${item.type}',
              );
              return haystack.contains(query);
            })
            .toList(growable: false)
          ..sort((a, b) => a.name.compareTo(b.name));

    return filtered;
  }

  Future<void> _copyText(String text, String confirmation) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(confirmation)));
  }

  String _materialText(Map<String, int> materials) {
    if (materials.isEmpty) return 'No material requirements.';
    return materials.entries
        .map(
          (entry) =>
              '${entry.value}x ${ArcItemIntelligenceEngine.itemName(entry.key)}',
        )
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Crafting Planner',
        subtitle: 'Craft, recycle and close exact loadout material gaps',
        showLogout: true,
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const ArcCompanionBottomDock(activeLabel: 'RUN'),
      body: ArcRaidersScreenShell(
        useSafeArea: true,
        showAdBanner: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          children: [
            const ArcProgressionWorkspaceBar(
              current: ArcProgressionWorkspace.crafting,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppTheme.spaceM),
            _hero(),
            const SizedBox(height: AppTheme.spaceM),
            StreamBuilder<ArcSavedLoadout?>(
              stream: _loadouts.watchFavouriteLoadout(),
              builder: (context, snapshot) => _favouriteLoadout(snapshot.data),
            ),
            const SizedBox(height: AppTheme.spaceM),
            _modeSwitch(),
            const SizedBox(height: AppTheme.spaceS),
            _searchAndFilters(),
            const SizedBox(height: AppTheme.spaceS),
            _catalog(),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return ArcRaidersSectionCard(
      accent: ArcUiTokens.primaryAccent,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/arc_raiders/operations/upgrade_gunsmith_card.webp',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: ArcUiTokens.surfacePanel),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: .96),
                      Colors.black.withValues(alpha: .84),
                      Colors.black.withValues(alpha: .48),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 122),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CRAFTING INTELLIGENCE',
                      style: ArcUiTokens.label(
                        color: ArcUiTokens.primaryAccent,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${ArcItemIntelligenceEngine.craftables.length} craftable items  •  '
                      '${ArcItemIntelligenceEngine.recyclables.length} recyclable items',
                      style: ArcUiTokens.sectionTitle(
                        fontSize: 20,
                        color: ArcUiTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Exact recipes, recursive from-scratch totals, Topside recycling '
                      'returns and Favourite Loadout material roll-up from the same '
                      'canonical item registry.',
                      style: ArcUiTokens.body(
                        color: Colors.white.withValues(alpha: .84),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favouriteLoadout(ArcSavedLoadout? loadout) {
    if (loadout == null) {
      return const ArcRaidersStatePanel(
        title: 'Favourite Loadout not set',
        message:
            'Save a Favourite Loadout and Crafting Planner will calculate the complete material chain automatically.',
        icon: Icons.inventory_2_outlined,
        accent: ArcUiTokens.secondaryAccent,
        compact: true,
      );
    }

    final plan = ArcItemIntelligenceEngine.planForFavouriteLoadout(loadout);
    final materialEntries = plan.rawMaterials.entries.toList(growable: false);
    final targetEntries = plan.resolvedTargets.entries.toList(growable: false);

    return ArcRaidersSectionCard(
      accent: ArcUiTokens.secondaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: ArcUiTokens.secondaryAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'FAVOURITE LOADOUT // FROM SCRATCH',
                  style: ArcUiTokens.label(color: ArcUiTokens.secondaryAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loadout.name,
            style: ArcUiTokens.sectionTitle(
              fontSize: 18,
              color: ArcUiTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${targetEntries.length} resolved craft targets • '
            '${materialEntries.length} raw material types',
            style: ArcUiTokens.metadata(color: ArcUiTokens.textSecondary),
          ),
          if (plan.unresolvedTargets.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              'Not yet craft-mapped: ${plan.unresolvedTargets.join(', ')}',
              style: ArcUiTokens.metadata(color: ArcUiTokens.warning),
            ),
          ],
          const SizedBox(height: 10),
          if (materialEntries.isEmpty)
            Text(
              'No craftable material chain was found for the saved items.',
              style: ArcUiTokens.body(color: ArcUiTokens.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in materialEntries)
                  _materialPill(entry.key, entry.value),
              ],
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: materialEntries.isEmpty
                    ? null
                    : () => _copyText(
                        'UAG FAVOURITE LOADOUT MATERIALS\n'
                            '${loadout.name}\n\n${_materialText(plan.rawMaterials)}',
                        'Favourite Loadout material list copied.',
                      ),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy Materials'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed(SmartTradeAssistScreen.routeName),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Trade'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed(ArcRaidIntelligenceScreen.routeName),
                icon: const Icon(Icons.route_rounded),
                label: const Text('Raid Intel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _materialPill(String itemId, int quantity) {
    final item = ArcItemIntelligenceEngine.byId(itemId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: ArcUiTokens.chipDecoration(color: ArcUiTokens.primaryAccent),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item != null) ...[
            SizedBox(
              width: 22,
              height: 22,
              child: Image.asset(
                item.imageAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.inventory_2_rounded,
                  size: 16,
                  color: ArcUiTokens.primaryAccent,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '${quantity}x ${item?.name ?? itemId}',
            style: ArcUiTokens.metadata(color: ArcUiTokens.primaryAccent),
          ),
        ],
      ),
    );
  }

  Widget _modeSwitch() {
    Widget option(_CraftingPlannerMode mode, String label, IconData icon) {
      final selected = _mode == mode;
      final accent = selected
          ? ArcUiTokens.primaryAccent
          : ArcUiTokens.textSecondary;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
          onTap: () => setState(() {
            _mode = mode;
            _station = 'All';
          }),
          child: AnimatedContainer(
            duration: AppTheme.fastAnimation,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: ArcUiTokens.chipDecoration(
              color: accent,
              selected: selected,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: accent),
                const SizedBox(width: 7),
                Text(label, style: ArcUiTokens.label(color: accent)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option(_CraftingPlannerMode.craft, 'CRAFT', Icons.handyman_rounded),
        const SizedBox(width: 8),
        option(
          _CraftingPlannerMode.recycle,
          'RECYCLE',
          Icons.recycling_rounded,
        ),
      ],
    );
  }

  Widget _searchAndFilters() {
    final availableStations = <String>{
      for (final item
          in (_mode == _CraftingPlannerMode.craft
              ? ArcItemIntelligenceEngine.craftables
              : ArcItemIntelligenceEngine.recyclables))
        item.primaryStation,
    };

    final stations = _stationOrder
        .where((value) => value == 'All' || availableStations.contains(value))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: ArcUiTokens.textPrimary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: _mode == _CraftingPlannerMode.craft
                ? 'Search recipes, weapons, attachments, augments...'
                : 'Search an item to see Topside recycling returns...',
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final station in stations) ...[
                ChoiceChip(
                  selected: _station == station,
                  showCheckmark: false,
                  label: Text(station.toUpperCase()),
                  selectedColor: ArcUiTokens.primaryAccent.withValues(
                    alpha: .14,
                  ),
                  backgroundColor: ArcUiTokens.surfaceInteractive,
                  side: BorderSide(
                    color: _station == station
                        ? ArcUiTokens.primaryAccent
                        : Colors.white.withValues(alpha: .10),
                  ),
                  labelStyle: ArcUiTokens.label(
                    color: _station == station
                        ? ArcUiTokens.primaryAccent
                        : ArcUiTokens.textSecondary,
                  ),
                  onSelected: (_) => setState(() => _station = station),
                ),
                const SizedBox(width: 7),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _catalog() {
    final visible = _visibleItems;
    if (visible.isEmpty) {
      return const ArcRaidersStatePanel(
        title: 'No matching ARC items',
        message: 'Change the search or station filter.',
        icon: Icons.search_off_rounded,
        compact: true,
      );
    }

    return Column(
      children: [
        for (final item in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _itemCard(item),
          ),
      ],
    );
  }

  Widget _itemCard(ArcItemIntelligenceItem item) {
    final plan = _mode == _CraftingPlannerMode.craft
        ? ArcItemIntelligenceEngine.planForItem(item.name)
        : null;

    return ArcRaidersSectionCard(
      accent: _mode == _CraftingPlannerMode.craft
          ? ArcUiTokens.primaryAccent
          : ArcUiTokens.success,
      padding: const EdgeInsets.all(12),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        leading: SizedBox(
          width: 48,
          height: 48,
          child: Image.asset(
            item.imageAsset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => const Icon(
              Icons.inventory_2_rounded,
              color: ArcUiTokens.textTertiary,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: ArcUiTokens.cardTitle(
            fontSize: 15,
            color: ArcUiTokens.textPrimary,
          ),
        ),
        subtitle: Text(
          _mode == _CraftingPlannerMode.craft
              ? '${item.primaryStation}'
                    '${item.stationLevel == null ? '' : ' Lv.${item.stationLevel}'}'
              : '${item.recyclesInto.length} Topside output'
                    '${item.recyclesInto.length == 1 ? '' : 's'}',
          style: ArcUiTokens.metadata(color: ArcUiTokens.textSecondary),
        ),
        children: [
          if (_mode == _CraftingPlannerMode.craft && plan != null) ...[
            _sectionLabel('IMMEDIATE RECIPE'),
            _keyValueList(item.recipe),
            const SizedBox(height: 8),
            _sectionLabel('TOTAL FROM SCRATCH'),
            _keyValueList(plan.rawMaterials),
            if (item.salvageable) ...[
              const SizedBox(height: 8),
              Text(
                'In-raid salvage is tracked separately because it can return fewer or different materials than Topside recycling.',
                style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _copyText(
                '${item.name}\n\nTOTAL FROM SCRATCH\n'
                    '${_materialText(plan.rawMaterials)}',
                '${item.name} recipe copied.',
              ),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy Total'),
            ),
          ] else ...[
            _sectionLabel('TOPSIDE RECYCLE'),
            _keyValueList(item.recyclesInto),
            if (item.salvageable) ...[
              const SizedBox(height: 8),
              _sectionLabel('IN-RAID SALVAGE'),
              _keyValueList(item.salvagesInto),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      label,
      style: ArcUiTokens.label(color: ArcUiTokens.primaryAccent),
    ),
  );

  Widget _keyValueList(Map<String, int> values) {
    if (values.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'No tracked materials.',
          style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
        ),
      );
    }

    return Column(
      children: [
        for (final entry in values.entries)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ArcItemIntelligenceEngine.itemName(entry.key),
                    style: ArcUiTokens.body(
                      color: ArcUiTokens.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'x${entry.value}',
                  style: ArcUiTokens.cardTitle(
                    fontSize: 13,
                    color: ArcUiTokens.primaryAccent,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
