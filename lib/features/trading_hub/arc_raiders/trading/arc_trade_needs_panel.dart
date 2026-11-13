import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/services/uag_entitlement_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_design_slot_names_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_stencil_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/trade_items_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

@immutable
class ArcTradeNeed {
  const ArcTradeNeed(this.id, this.name, this.category, {this.quantity = 1});
  final String id;
  final String name;
  final String category;
  final int quantity;
}

@immutable
class ArcTradeNeedsSelection {
  const ArcTradeNeedsSelection({required this.blueprintIds, required this.assetIds,
    required this.otherNeeds, required this.allMissing});
  final Set<String> blueprintIds;
  final Set<String> assetIds;
  final List<String> otherNeeds;
  final bool allMissing;
}

/// Enforces the UI selection budget; the server must separately enforce any
/// eventual automatic matching/acceptance and commercial entitlements.
class ArcTradeNeedsPolicy {
  const ArcTradeNeedsPolicy._();
  static int selectable(UagSubscriptionTier tier, int eligibleCount) => switch (tier) {
    UagSubscriptionTier.free => 0,
    UagSubscriptionTier.essential => (eligibleCount + 1) ~/ 2,
    UagSubscriptionTier.premium => eligibleCount,
  };
  static bool permits(UagSubscriptionTier tier, int eligibleCount, int selectedCount) =>
    selectedCount >= 0 && selectedCount <= selectable(tier, eligibleCount);
}

/// Uses actual saved collection states. Unnamed Design positions are NOT
/// mislabeled as specific designs; unresolved slots remain clearly identified.
class ArcTradeNeedsPanel extends StatefulWidget {
  const ArcTradeNeedsPanel({super.key, required this.missingBlueprints,
    required this.catalog, required this.onApply});
  final List<ArcBlueprint> missingBlueprints;
  final List<ArcTradeItem> catalog;
  final ValueChanged<ArcTradeNeedsSelection> onApply;
  @override
  State<ArcTradeNeedsPanel> createState() => _ArcTradeNeedsPanelState();
}

class _ArcTradeNeedsPanelState extends State<ArcTradeNeedsPanel> {
  late Future<_NeedsData> _data;
  final Set<String> _selected = <String>{};
  bool _allMissing = true;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  @override
  void didUpdateWidget(covariant ArcTradeNeedsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.missingBlueprints.length != widget.missingBlueprints.length) {
      _data = _load();
      _selected.clear();
    }
  }

  Future<_NeedsData> _load() async {
    final tier = (await UagEntitlementService().getMyEntitlement()).effectiveTier;
    final arc = await ArcAmplificationRepository().watch().first;
    final slots = ArcCollectionSlotRepository();
    final stencils = await slots.read(ArcNativeCollectionKind.stencils);
    final designs = await slots.read(ArcNativeCollectionKind.designs);
    final designNames = await ArcDesignSlotNamesRepository().read();
    final needs = <ArcTradeNeed>[
      for (final bp in widget.missingBlueprints)
        ArcTradeNeed('bp:${bp.id}', bp.name, 'Blueprint'),
    ];
    final materials = <String, int>{};
    for (final project in ArcAmplificationCatalog.projects) {
      if (arc.completed.contains(project.id)) continue;
      final needed = arc.shortage(project.id);
      if (needed > (materials[project.material] ?? 0)) {
        materials[project.material] = needed;
      }
    }
    for (final entry in materials.entries) {
      final match = widget.catalog.where((item) =>
        item.name.toLowerCase() == entry.key.toLowerCase());
      if (match.isNotEmpty) {
        needs.add(ArcTradeNeed('asset:${match.first.id}', entry.key,
          'Amplification material', quantity: entry.value));
      } else {
        needs.add(ArcTradeNeed('other:material:${entry.key}', entry.key,
          'Amplification material — catalogue match unavailable', quantity: entry.value));
      }
    }
    for (var slot = 1; slot <= ArcNativeCollectionKind.stencils.slots; slot++) {
      if (!stencils.ownedSlots.contains(slot)) {
        needs.add(ArcTradeNeed('other:stencil:$slot', ArcStencilCatalogue.nameAt(slot), 'Stencil'));
      }
    }
    for (var slot = 1; slot <= ArcNativeCollectionKind.designs.slots; slot++) {
      if (!designs.ownedSlots.contains(slot)) {
        needs.add(ArcTradeNeed('other:design:$slot',
          designNames[slot] ?? 'Unidentified Design slot $slot', 'Design'));
      }
    }
    return _NeedsData(tier, needs);
  }

  void _apply(_NeedsData data) {
    final chosen = _allMissing || data.tier == UagSubscriptionTier.free
      ? data.needs
      : data.needs.where((need) => _selected.contains(need.id)).toList();
    final valid = ArcTradeNeedsPolicy.permits(data.tier, data.needs.length, _selected.length);
    if (!_allMissing && !valid) return;
    widget.onApply(ArcTradeNeedsSelection(
      blueprintIds: chosen.where((n) => n.id.startsWith('bp:'))
        .map((n) => n.id.substring(3)).toSet(),
      assetIds: chosen.where((n) => n.id.startsWith('asset:'))
        .map((n) => n.id.substring(6)).toSet(),
      otherNeeds: chosen.where((n) => n.id.startsWith('other:'))
        .map((n) => n.name == 'Unidentified Design slot ${n.id.split(':').last}'
          ? 'Design slot ${n.id.split(':').last} (name not confirmed)' : n.name).toList(),
      allMissing: _allMissing || data.tier == UagSubscriptionTier.free,
    ));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Wanted items applied to this trade listing. Review the offer before publishing.'),
    ));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_NeedsData>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Text('Could not load trade needs: ${snapshot.error}',
          style: const TextStyle(color: Colors.orangeAccent));
      }
      if (!snapshot.hasData) return const LinearProgressIndicator();
      final data = snapshot.data!;
      final max = ArcTradeNeedsPolicy.selectable(data.tier, data.needs.length);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Saved tracker requirements: ${data.needs.length} • ${data.tier.label}',
          style: const TextStyle(color: AppTheme.neonCyan)),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Accept offers for ALL missing items'),
          subtitle: const Text('Blueprints, research materials, stencils and Designs; this does not transfer in-game items.'),
          value: _allMissing,
          onChanged: data.tier == UagSubscriptionTier.free ? null :
            (value) => setState(() => _allMissing = value ?? true),
        ),
        if (!_allMissing && data.tier != UagSubscriptionTier.free) ...[
          Text('Choose up to $max of ${data.needs.length} needs',
            style: const TextStyle(color: Colors.white70)),
          SizedBox(height: 170, child: ListView.builder(
            itemCount: data.needs.length,
            itemBuilder: (context, index) {
              final need = data.needs[index];
              final checked = _selected.contains(need.id);
              return CheckboxListTile(
                dense: true,
                title: Text(need.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${need.category}${need.quantity > 1 ? ' • x${need.quantity}' : ''}'),
                value: checked,
                onChanged: !checked && _selected.length >= max ? null : (value) {
                  setState(() { if (value == true) { _selected.add(need.id); }
                    else { _selected.remove(need.id); } });
                },
              );
            },
          )),
        ],
        const SizedBox(height: 6),
        OutlinedButton.icon(
          key: const Key('arc-trade-apply-tracker-needs'),
          onPressed: () => _apply(data),
          icon: const Icon(Icons.playlist_add_check),
          label: const Text('APPLY TO THIS LISTING'),
        ),
      ]);
    },
  );
}

class _NeedsData {
  const _NeedsData(this.tier, this.needs);
  final UagSubscriptionTier tier;
  final List<ArcTradeNeed> needs;
}
