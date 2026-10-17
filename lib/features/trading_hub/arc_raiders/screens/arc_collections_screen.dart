import 'package:flutter/material.dart';

import '../data/arc_frozen_trail_collection_catalogue.dart';
import '../models/arc_collection_models.dart';
import '../widgets/arc_raiders_screen_shell.dart';
import '../widgets/foundation/arc_ui_tokens.dart';

class ArcCollectionsScreen extends StatefulWidget {
  const ArcCollectionsScreen({super.key});

  static const routeName = '/trading-hub/arc-raiders/collections-v2';

  @override
  State<ArcCollectionsScreen> createState() => _ArcCollectionsScreenState();
}

class _ArcCollectionsScreenState extends State<ArcCollectionsScreen> {
  ArcCollectionType _selected = ArcCollectionType.blueprints;
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.orientationOf(context) == Orientation.portrait) {
      return const Scaffold(
        backgroundColor: Color(0xFF07111B),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.screen_rotation_rounded,
                  size: 72,
                  color: ArcUiTokens.primaryAccent,
                ),
                SizedBox(height: 16),
                Text(
                  'ROTATE TO LANDSCAPE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ArcUiTokens.primaryAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Blueprint collections use a 17-column layout. '
                  'Rotate your device to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final spec = ArcFrozenTrailCollectionCatalogue.specs[_selected]!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArcRaidersScreenShell(
        child: ArcRaidersPageList(
          maxWidth: 1500,
          children: [
            ArcRaidersPageHeader(
              title: 'COLLECTIONS',
              subtitle:
                  'Frozen Trail 91-slot collection: confirmed and predicted positions.',
              icon: Icons.grid_view_rounded,
            ),
            const SizedBox(height: ArcUiTokens.gapM),
            _tabs(),
            const SizedBox(height: ArcUiTokens.gapM),
            _status(spec),
            const SizedBox(height: ArcUiTokens.gapM),
            _grid(spec),
            const SizedBox(height: ArcUiTokens.gapM),
            _knownItems(),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in ArcCollectionType.values)
          ChoiceChip(
            label: Text(type.label),
            selected: _selected == type,
            showCheckmark: false,
            selectedColor: ArcUiTokens.primaryAccent.withValues(alpha: 0.18),
            backgroundColor: ArcUiTokens.surfaceInteractive,
            side: BorderSide(
              color:
                  (_selected == type
                          ? ArcUiTokens.primaryAccent
                          : ArcUiTokens.borderSubtle)
                      .withValues(alpha: 0.72),
            ),
            labelStyle: ArcUiTokens.label(
              color: _selected == type
                  ? ArcUiTokens.primaryAccent
                  : ArcUiTokens.textSecondary,
            ),
            onSelected: (_) {
              setState(() => _selected = type);
              _controller.value = Matrix4.identity();
            },
          ),
      ],
    );
  }

  Widget _status(ArcCollectionGridSpec spec) {
    final verified = ArcFrozenTrailCollectionCatalogue.entriesFor(
      _selected,
    ).where((entry) => entry.slot != null).length;

    return ArcRaidersSectionCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ArcTacticalStatusPill(
            label: '${spec.totalSlots} SLOTS',
            icon: Icons.grid_4x4_rounded,
          ),
          ArcTacticalStatusPill(
            label: '${spec.rowCount} ROWS',
            icon: Icons.view_stream_rounded,
            accent: ArcUiTokens.secondaryAccent,
          ),
          ArcTacticalStatusPill(
            label: '$verified VERIFIED POSITIONS',
            icon: Icons.verified_rounded,
            accent: ArcUiTokens.success,
          ),
        ],
      ),
    );
  }

  Widget _grid(ArcCollectionGridSpec spec) {
    const cellWidth = 74.0;
    const cellHeight = 88.0;
    const gap = 6.0;

    final width = (spec.maxColumns * cellWidth) + ((spec.maxColumns - 1) * gap);
    final height = (spec.rowCount * cellHeight) + ((spec.rowCount - 1) * gap);

    return ArcRaidersSectionCard(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: (height + 30).clamp(220, 620).toDouble(),
        child: ClipRect(
          child: InteractiveViewer(
            transformationController: _controller,
            constrained: false,
            minScale: 0.45,
            maxScale: 3.4,
            boundaryMargin: const EdgeInsets.all(120),
            child: SizedBox(
              width: width,
              height: height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var row = 1; row <= spec.rowCount; row++) ...[
                    Row(
                      children: [
                        for (
                          var column = 1;
                          column <= spec.rowColumnCounts[row - 1];
                          column++
                        ) ...[
                          _slot(
                            spec,
                            row: row,
                            column: column,
                            width: cellWidth,
                            height: cellHeight,
                          ),
                          if (column < spec.rowColumnCounts[row - 1])
                            const SizedBox(width: gap),
                        ],
                      ],
                    ),
                    if (row < spec.rowCount) const SizedBox(height: gap),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _slot(
    ArcCollectionGridSpec spec, {
    required int row,
    required int column,
    required double width,
    required double height,
  }) {
    final slot = spec.absoluteSlotFor(row: row, column: column)!;
    final entry = ArcFrozenTrailCollectionCatalogue.entryAtSlot(
      _selected,
      slot,
    );
    final verified = entry != null;
    final accent = verified
        ? ArcUiTokens.primaryAccent
        : ArcUiTokens.borderSubtle;

    return Container(
      key: ValueKey('${_selected.name}-$slot'),
      width: width,
      height: height,
      padding: const EdgeInsets.all(7),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: accent,
        selected: verified,
        glow: verified,
        radius: ArcUiTokens.radiusS,
        borderOpacity: verified ? 0.48 : 0.20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$slot',
            style: ArcUiTokens.label(
              color: verified
                  ? ArcUiTokens.primaryAccent
                  : ArcUiTokens.textDisabled,
            ),
          ),
          if ((_selected == ArcCollectionType.blueprints ||
                  _selected == ArcCollectionType.stencils) &&
              entry != null &&
              ArcFrozenTrailCollectionCatalogue.frozenTrailArtworkPaths
                  .containsKey(entry.id))
            Expanded(
              child: Center(
                child: Image.asset(
                  ArcFrozenTrailCollectionCatalogue
                      .frozenTrailArtworkPaths[entry.id]!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image_outlined,
                    size: 20,
                    color: Colors.white38,
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          Text(
            entry?.name ?? 'UNVERIFIED',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: ArcUiTokens.body(
              fontSize: verified ? 10.5 : 9.5,
              color: verified
                  ? ArcUiTokens.textPrimary
                  : ArcUiTokens.textDisabled,
              weight: verified ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _knownItems() {
    final entries = ArcFrozenTrailCollectionCatalogue.entriesFor(_selected);

    if (entries.isEmpty) {
      return const ArcRaidersStatePanel(
        title: 'Layout captured',
        message:
            'The 100-slot Design geometry is confirmed. Item names and exact positions will be added only when verified in-game.',
        icon: Icons.rule_folder_outlined,
      );
    }

    return ArcRaidersSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VERIFIED / CONFIRMED ITEMS',
            style: ArcUiTokens.sectionTitle(
              fontSize: 15,
              color: ArcUiTokens.secondaryAccent,
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Icon(
                    entry.slot == null
                        ? Icons.help_outline_rounded
                        : Icons.verified_rounded,
                    size: 17,
                    color: entry.slot == null
                        ? ArcUiTokens.warning
                        : ArcUiTokens.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.slot == null
                          ? '${entry.name} — exact slot pending'
                          : '${entry.name} — slot ${entry.slot}',
                      style: ArcUiTokens.body(
                        color: ArcUiTokens.textPrimary,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (entry.sourceLabel != null)
                    Text(entry.sourceLabel!, style: ArcUiTokens.metadata()),
                ],
              ),
            ),
          if (_selected != ArcCollectionType.blueprints)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Duplicate and trading behaviour remains UNKNOWN until verified in-game.',
                style: ArcUiTokens.bodySmall(color: ArcUiTokens.warning),
              ),
            ),
        ],
      ),
    );
  }
}
