import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart' as uag_pass14_theme;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/uag_android_responsiveness_guard.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_collection_models.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';

/// Read-only Blueprint inventory. Does not alter the protected Blueprint
/// Tracker widget, grid order, acquisition or dupesOwned logic.
class ArcBlueprintCollectionOverviewScreen extends StatefulWidget {
  const ArcBlueprintCollectionOverviewScreen({super.key});

  @override
  State<ArcBlueprintCollectionOverviewScreen> createState() =>
      _ArcBlueprintCollectionOverviewScreenState();
}

class _ArcBlueprintCollectionOverviewScreenState
    extends State<ArcBlueprintCollectionOverviewScreen> {
  String _filter = 'all';
  late Future<Map<String, ArcBlueprintState>> _states;

  @override
  void initState() {
    super.initState();
    UagAndroidResponsivenessGuard.instance.enterSurface('BlueprintCollectionOverview');
    _states = ArcBlueprintRepository().loadMyBlueprintStates();
  }

  @override
  void dispose() {
    UagAndroidResponsivenessGuard.instance.exitSurface('BlueprintCollectionOverview');
    super.dispose();
  }

  void _openExtra(ArcNativeCollectionKind kind) {
    Navigator.push(context, MaterialPageRoute<void>(
      builder: (_) => ArcAdditionalCollectionsScreen(initialKind: kind),
    ));
  }

  Future<void> _share(Map<String, ArcBlueprintState> states) async {
    final entries = ArcFrozenTrailCollectionCatalogue.blueprintEntries
        .where((entry) => entry.slot != null).toList()
      ..sort((a, b) => a.slot!.compareTo(b.slot!));
    ArcCollectionShareItem item(ArcCollectionEntry entry, {int spares = 0}) {
      final name = entry.name;
      final id = entry.id;
      final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      return ArcCollectionShareItem(
        id: id,
        label: name,
        assetPath: ArcFrozenTrailCollectionCatalogue.frozenTrailArtworkPaths[id] ??
            'assets/arc_raiders/blueprints/$slug.webp',
        spares: spares,
      );
    }
    if (!mounted) return;
    await ArcCollectionVisualShare.show(
      context: context,
      title: 'Blueprints',
      owned: entries.where((e) => states[e.id]?.owned == true).map(item).toList(),
      needed: entries.where((e) => states[e.id]?.owned != true).map(item).toList(),
      duplicates: entries.where((e) => (states[e.id]?.dupesOwned ?? 0) > 0)
          .map((e) => item(e, spares: states[e.id]!.dupesOwned)).toList(),
      wantedPriorityRanks: {
        for (final entry in entries)
          if ((states[entry.id]?.priorityRank ?? 0) > 0)
            entry.id: states[entry.id]!.priorityRank,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = ArcFrozenTrailCollectionCatalogue.blueprintEntries
        .where((e) => e.slot != null).toList()
      ..sort((a, b) => a.slot!.compareTo(b.slot!));
    return Scaffold(
      backgroundColor: uag_pass14_theme.AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('COLLECTIONS GRID'),
        backgroundColor: uag_pass14_theme.AppTheme.cardBackgroundDeep,
        foregroundColor: uag_pass14_theme.AppTheme.neonCyan,
        actions: [IconButton(
          tooltip: 'Refresh collection', icon: const Icon(Icons.refresh),
          onPressed: () => setState(() => _states = ArcBlueprintRepository().loadMyBlueprintStates()),
        )],
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: [
          const Chip(label: Text('BLUEPRINTS')),
          const SizedBox(width: 5),
          TextButton(onPressed: () => _openExtra(ArcNativeCollectionKind.stencils), child: const Text('STENCILS')),
          TextButton(onPressed: () => _openExtra(ArcNativeCollectionKind.designs), child: const Text('DESIGNS')),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: [
          const Expanded(child: Text('BLUEPRINT INVENTORY · 91 POSITIONS', style:
              TextStyle(color: uag_pass14_theme.AppTheme.neonCyan, fontSize: 12))),
          DropdownButton<String>(
            key: const Key('blueprints-inventory-filter'),
            value: _filter, dropdownColor: uag_pass14_theme.AppTheme.cardBackgroundAlt,
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All items')),
              DropdownMenuItem(value: 'needed', child: Text('Needed')),
              DropdownMenuItem(value: 'duplicates', child: Text('Duplicates')),
            ],
            onChanged: (v) { if (v != null) setState(() => _filter = v); },
          ),
        ])),
        Expanded(child: FutureBuilder<Map<String, ArcBlueprintState>>(
          future: _states,
          builder: (context, snap) {
            if (snap.hasError) return const Center(child: Text('Could not load Blueprints. Check sign-in.', style: TextStyle(color: uag_pass14_theme.AppTheme.warningAmber)));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final states = snap.data!;
            return Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton.icon(
                  onPressed: () => _share(states), icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share collection'),
                ),
              ]),
              Expanded(child: LayoutBuilder(builder: (context, size) {
                final tileWidth = ((size.maxWidth-20)/17).clamp(57.0, 88.0);
                const gap = 4.0;
                return SingleChildScrollView(scrollDirection: Axis.horizontal,
                  child: SizedBox(width: (tileWidth+gap)*17,
                    child: SingleChildScrollView(child: Column(children: [
                      for (var row=0; row<6; row++)
                        Row(children: [
                          for (final entry in entries.where((e) => (e.slot! - 1) ~/ 17 == row))
                            Builder(builder: (context) {
                              final state = states[entry.id];
                              final owned = state?.owned == true;
                              final dupes = state?.dupesOwned ?? 0;
                              final relevant = _filter=='all' || (_filter=='needed' && !owned) || (_filter=='duplicates' && dupes>0);
                              // Blueprint images follow the user's existing lowercase WebP naming convention.
                              final slug = entry.name.toLowerCase()
                                  .replaceAll(RegExp(r"[^a-z0-9]+"), '-')
                                  .replaceAll(RegExp(r'^-|-$'), '');
                              return Padding(padding: const EdgeInsets.only(right: gap, bottom: gap),
                                child: Opacity(opacity: relevant ? 1 : .20,
                                  child: InkWell(
                                    onTap: () => showDialog<void>(context: context, builder: (dialog) => AlertDialog(
                                      backgroundColor: uag_pass14_theme.AppTheme.cardBackgroundDeep,
                                      surfaceTintColor: Colors.transparent,
                                      title: Text(entry.name),
                                      content: Text('${owned ? 'Owned' : 'Needed'} · $dupes spare copies'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Close')),
                                        TextButton.icon(
                                          icon: const Icon(Icons.share),
                                          label: const Text('Share trade interest'),
                                          onPressed: () async {
                                            // ignore: deprecated_member_use
                                            await Share.share('UAG ARC Raiders Hub · Blueprint: ${entry.name}. ${owned ? 'Owned' : 'Needed'}. $dupes spare copies. Want to discuss a trade?');
                                          },
                                        ),
                                      ],
                                    )),
                                    child: Container(width: tileWidth, height: tileWidth*1.20,
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: owned ? uag_pass14_theme.AppTheme.cardBackgroundAlt : uag_pass14_theme.AppTheme.cardBackgroundDeep,
                                      border: Border.all(color: dupes>0 ? uag_pass14_theme.AppTheme.neonPink : uag_pass14_theme.AppTheme.neonCyan.withValues(alpha: 0.26)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(children: [
                                      Expanded(child: Stack(children: [
                                        Positioned.fill(child: Image.asset('assets/arc_raiders/blueprints/$slug.webp', fit: BoxFit.contain,
                                          errorBuilder: (_, _, _) => Icon(owned ? Icons.inventory_2_outlined : Icons.lock_outline, color: Colors.white30))),
                                        Positioned(right: 0, top: 0, child: Icon(owned ? Icons.check_circle : Icons.remove_circle_outline,
                                          size: 12, color: owned ? const Color(0xFFFFD949) : Colors.white30)),
                                        if (dupes>0) Positioned(right: 0, bottom: 0, child: Text('+$dupes', style: const TextStyle(fontSize: 10, color: uag_pass14_theme.AppTheme.neonPink))),
                                      ])),
                                      Text(entry.name, maxLines:1, overflow:TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontSize: 8)),
                                    ]),
                                  ),
                                  ),
                                ),
                              );
                            }),
                        ]),
                    ]))),
                );
              })),
              const Padding(padding: EdgeInsets.all(5), child: Text(
                'Read-only collection overview. Manage Blueprint ownership and spare counts in the existing Collections Tracker.',
                style: TextStyle(color: Colors.white60, fontSize: 10))),
            ]);
          },
        )),
      ]),
    );
  }
}
