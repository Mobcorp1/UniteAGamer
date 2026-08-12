import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_icon_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_taxonomy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_map_filter_icon.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcMapFilterIconReviewScreen extends StatelessWidget {
  const ArcMapFilterIconReviewScreen({super.key});

  static const routeName = '/admin-map-filter-icons';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Map Icon Review',
        subtitle: 'Admin diagnostic icon atlas.',
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          ListView(
            children: [
              const ArcPageViewport(
                width: ArcPageWidth.wide,
                child: ArcMapFilterIconReviewAtlas(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ArcMapFilterIconReviewAtlas extends StatelessWidget {
  const ArcMapFilterIconReviewAtlas({super.key});

  static const _canonicalSections = [
    _IconReviewSectionData(
      title: 'ARC',
      subtitle: 'Canonical ARC enemy and world-object markers.',
      entries: ArcMapFilterTaxonomy.arc,
    ),
    _IconReviewSectionData(
      title: 'Extraction',
      entries: ArcMapFilterTaxonomy.extraction,
    ),
    _IconReviewSectionData(title: 'Loot', entries: ArcMapFilterTaxonomy.loot),
    _IconReviewSectionData(
      title: 'Infrastructure',
      entries: ArcMapFilterTaxonomy.infrastructure,
    ),
    _IconReviewSectionData(
      title: 'Access',
      entries: ArcMapFilterTaxonomy.access,
    ),
    _IconReviewSectionData(
      title: 'Nature',
      entries: ArcMapFilterTaxonomy.nature,
    ),
    _IconReviewSectionData(
      title: 'Quest',
      entries: ArcMapFilterTaxonomy.objectives,
    ),
  ];

  static const _uagCommunityItems = [
    _IconReviewItem(
      label: 'Report A Rat',
      iconKey: ArcMapFilterIconRegistry.communityReportRatIconKey,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArcPageHeader(
          title: 'Map Filter Icon Atlas',
          subtitle:
              '${ArcMapFilterTaxonomy.all.length} canonical icons '
              'plus ${_uagCommunityItems.length} UAG community icon rendered '
              'at marker, menu, cluster, review and audit sizes.',
          leading: const Icon(
            Icons.travel_explore_rounded,
            color: AppTheme.neonCyan,
            size: 34,
          ),
        ),
        const SizedBox(height: AppTheme.spaceL),
        _IconAtlasSummary(
          iconCount: ArcMapFilterTaxonomy.all.length,
          sectionCount: _canonicalSections.length + 1,
          communityIconCount: _uagCommunityItems.length,
        ),
        const SizedBox(height: AppTheme.spaceL),
        for (final section in _canonicalSections) ...[
          _IconReviewSection(
            title: section.title,
            subtitle: section.subtitle,
            items: section.items,
          ),
          const SizedBox(height: AppTheme.spaceL),
        ],
        const _IconReviewSection(
          title: 'UAG Community',
          subtitle:
              'UAG-owned feature icons, separate from canonical map entities.',
          items: _uagCommunityItems,
        ),
        const SizedBox(height: AppTheme.spaceL),
      ],
    );
  }
}

class ArcMapFilterIconReviewLaunchCard extends StatelessWidget {
  const ArcMapFilterIconReviewLaunchCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonPink.withValues(alpha: 0.34),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final label = Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonPink.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppTheme.neonPink.withValues(alpha: 0.32),
                  ),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: AppTheme.neonPink,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Map Icon Review',
                      style: AppTheme.tradingHeading(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Audit every Raid Intelligence taxonomy icon at 18, 24, '
                      '32, 48 and 128 pixels before shipping marker updates.',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 14,
                        color: AppTheme.tradingMutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final button = ElevatedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Review Icons'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label,
                const SizedBox(height: AppTheme.spaceM),
                Align(alignment: Alignment.centerLeft, child: button),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: label),
              const SizedBox(width: AppTheme.spaceM),
              Flexible(flex: 0, child: button),
            ],
          );
        },
      ),
    );
  }
}

class _IconAtlasSummary extends StatelessWidget {
  const _IconAtlasSummary({
    required this.iconCount,
    required this.sectionCount,
    required this.communityIconCount,
  });

  final int iconCount;
  final int sectionCount;
  final int communityIconCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.24),
      ),
      child: Wrap(
        spacing: AppTheme.spaceM,
        runSpacing: AppTheme.spaceM,
        children: [
          _SummaryPill(label: 'Canonical icons', value: '$iconCount'),
          _SummaryPill(label: 'Review sections', value: '$sectionCount'),
          _SummaryPill(
            label: 'UAG community icons',
            value: '$communityIconCount',
          ),
          const _SummaryPill(label: 'Preview sizes', value: '18/24/32/48/128'),
          const _SummaryPill(label: 'Fallback', value: 'map_filter_unknown'),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        '$label: $value',
        style: AppTheme.bodyTextStyle(
          fontSize: 12,
          color: AppTheme.tradingMutedText,
          isBold: true,
        ),
      ),
    );
  }
}

class _IconReviewItem {
  const _IconReviewItem({required this.label, required this.iconKey});

  final String label;
  final String iconKey;
}

class _IconReviewSectionData {
  const _IconReviewSectionData({
    required this.title,
    required this.entries,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<ArcMapFilterTaxonomyEntry> entries;

  List<_IconReviewItem> get items => [
    for (final entry in entries)
      _IconReviewItem(label: entry.label, iconKey: entry.iconKey),
  ];
}

class _IconReviewSection extends StatelessWidget {
  const _IconReviewSection({
    required this.title,
    required this.items,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<_IconReviewItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.tradingHeading(fontSize: 22)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTheme.bodyTextStyle(
                fontSize: 13,
                color: AppTheme.tradingMutedText,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spaceM),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1080
                  ? 3
                  : constraints.maxWidth >= 700
                  ? 2
                  : 1;
              final gap = AppTheme.spaceM;
              final tileWidth =
                  (constraints.maxWidth - ((columns - 1) * gap)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: tileWidth,
                      child: _IconReviewTile(item: item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IconReviewTile extends StatelessWidget {
  const _IconReviewTile({required this.item});

  static const _sizes = [18.0, 24.0, 32.0, 48.0, 128.0];

  final _IconReviewItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>('map-icon-review-${item.iconKey}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(
              fontSize: 14,
              color: AppTheme.neonCyan,
              isBold: true,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.iconKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyTextStyle(
              fontSize: 11,
              color: AppTheme.tradingMutedText,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceM,
            runSpacing: AppTheme.spaceS,
            children: [
              for (final size in _sizes)
                _IconSizePreview(item: item, size: size),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconSizePreview extends StatelessWidget {
  const _IconSizePreview({required this.item, required this.size});

  final _IconReviewItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final boxSize = size >= 128 ? 148.0 : 52.0;
    final columnWidth = size >= 128 ? 156.0 : 56.0;

    return SizedBox(
      width: columnWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: boxSize,
            height: boxSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.14),
              ),
            ),
            child: ArcMapFilterIcon(
              iconKey: item.iconKey,
              size: size,
              color: AppTheme.neonCyan,
              semanticLabel: '${item.label} $size pixel map icon',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${size.round()}px',
            style: AppTheme.bodyTextStyle(
              fontSize: 10,
              color: AppTheme.tradingMutedText,
            ),
          ),
        ],
      ),
    );
  }
}
