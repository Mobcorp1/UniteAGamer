import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_blueprint_collection_overview_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';

/// The public entry point for all three collections.
///
/// The existing BlueprintGridScreen stays untouched. Named route requests for
/// use this screen through its separate route. The original named Blueprint
/// route and direct BlueprintGridScreen remain available for manual editing.
class ArcCollectionsTrackerScreen extends StatefulWidget {
  static const routeName = '/trading-hub/arc-raiders/collections-tracker';

  const ArcCollectionsTrackerScreen({super.key, this.previewMode = false});

  /// Only used by isolated widget tests; avoids contacting Firebase in tests.
  final bool previewMode;

  @override
  State<ArcCollectionsTrackerScreen> createState() =>
      _ArcCollectionsTrackerScreenState();
}

class _ArcCollectionsTrackerScreenState
    extends State<ArcCollectionsTrackerScreen> {
  Future<Map<String, ArcBlueprintState>>? _blueprints;
  Future<ArcAdditionalCollectionState>? _stencils;
  Future<ArcAdditionalCollectionState>? _designs;

  @override
  void initState() {
    super.initState();
    if (!widget.previewMode) _loadCounts();
  }

  void _loadCounts() {
    _blueprints = ArcBlueprintRepository().loadMyBlueprintStates();
    _stencils = ArcCollectionSlotRepository().read(ArcNativeCollectionKind.stencils);
    _designs = ArcCollectionSlotRepository().read(ArcNativeCollectionKind.designs);
  }

  void _refresh() => setState(_loadCounts);

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(builder: (_) => page),
    );
    if (mounted && !widget.previewMode) _refresh();
  }

  Widget _count(Future<int>? ownedCount, int total) {
    if (widget.previewMode) {
      return Text('— / $total', style: const TextStyle(color: Colors.white60));
    }
    return FutureBuilder<int>(
      future: ownedCount,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Sign in to view',
              style: TextStyle(color: Color(0xFFFFC77B), fontSize: 11));
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        return Text('${snapshot.data} / $total',
            style: const TextStyle(
              color: Color(0xFF6CE6E9),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ));
      },
    );
  }

  Widget _collectionTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required String keyName,
    required Future<int>? ownedCount,
    required int total,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF122A35),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: Key('collections-tracker-$keyName'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF36717B)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(icon, color: const Color(0xFF63DBE7), size: 23),
            const SizedBox(width: 12),
            Expanded(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                )),
                Text(subtitle, maxLines: 2,
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            )),
            _count(ownedCount, total),
            const SizedBox(width: 7),
            const Icon(Icons.chevron_right, color: Color(0xFF67DDE7)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blueprintCount = _blueprints?.then((states) =>
        states.values.where((state) => state.owned).length);
    final stencilCount = _stencils?.then((state) => state.ownedSlots.length);
    final designCount = _designs?.then((state) => state.ownedSlots.length);

    return Scaffold(
      backgroundColor: const Color(0xFF07131D),
      appBar: AppBar(
        title: const Text('COLLECTIONS TRACKER'),
        backgroundColor: const Color(0xFF0D2530),
        foregroundColor: const Color(0xFF68E3EB),
        actions: [IconButton(
          key: const Key('collections-tracker-refresh'),
          tooltip: 'Refresh collection counts',
          onPressed: widget.previewMode ? null : _refresh,
          icon: const Icon(Icons.refresh),
        )],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text('YOUR COLLECTIONS', style: TextStyle(
              color: Color(0xFF6CE6E9),
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            )),
            const SizedBox(height: 4),
            const Text(
              'All three collections live here. Open one to see every item, '
              'filter Needed or Duplicates, and share your list.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _collectionTile(
              keyName: 'blueprints',
              label: 'BLUEPRINTS',
              subtitle: '91-slot visual inventory · names, images and spare copies',
              icon: Icons.grid_view_rounded,
              total: 91,
              ownedCount: blueprintCount,
              onTap: () => _open(const ArcBlueprintCollectionOverviewScreen()),
            ),
            const SizedBox(height: 8),
            _collectionTile(
              keyName: 'stencils',
              label: 'STENCILS',
              subtitle: '14 named slots · screenshot import and manual duplicates',
              icon: Icons.palette_outlined,
              total: 14,
              ownedCount: stencilCount,
              onTap: () => _open(const ArcAdditionalCollectionsScreen(
                initialKind: ArcNativeCollectionKind.stencils)),
            ),
            const SizedBox(height: 8),
            _collectionTile(
              keyName: 'designs',
              label: 'DESIGNS',
              subtitle: '100 slots · screenshot import and manual duplicates',
              icon: Icons.chair_alt_outlined,
              total: 100,
              ownedCount: designCount,
              onTap: () => _open(const ArcAdditionalCollectionsScreen(
                initialKind: ArcNativeCollectionKind.designs)),
            ),
            const SizedBox(height: 16),
            const Text('UPDATE YOUR COLLECTION', style: TextStyle(
              color: Color(0xFF6CE6E9),
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('collections-tracker-scan'),
              onPressed: () => _open(const ArcFrozenTrailSingleGridCaptureScreen()),
              icon: const Icon(Icons.upload_file),
              label: const Text('SCAN / UPDATE BLUEPRINTS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6CE6E9),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('collections-tracker-manage-blueprints'),
              onPressed: () => _open(const BlueprintGridScreen()),
              icon: const Icon(Icons.edit_note),
              label: const Text('MANAGE BLUEPRINT OWNERSHIP & DUPLICATES'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1D6472),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'For newly acquired Blueprints, re-scan the current in-game grid. '
              'If a new card is missed, open Manage Blueprints and mark it owned '
              'manually. Position 62 (row 4, card 11) is the reported Banter card. '
              'This does not reset your existing collection or duplicate counts.',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ))),
    );
  }
}
