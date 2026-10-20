import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart' as uag_pass14_theme;

/// Read-only row identity; only + or - requests a persisted change.
class ArcCollectionDupeEntry {
  const ArcCollectionDupeEntry({
    required this.id,
    required this.name,
    required this.owned,
    required this.spares,
    this.detail,
    this.imageAssetPath,
    this.icon = Icons.inventory_2_outlined,
  });

  final String id;
  final String name;
  final bool owned;
  final int spares;
  final String? detail;
  final String? imageAssetPath;
  final IconData icon;
}

/// Searchable duplicate ledger shared by Blueprints, Stencils and Designs.
/// Never infers spares from an acquisition screenshot.
class ArcCollectionDupeManager extends StatefulWidget {
  const ArcCollectionDupeManager({
    super.key,
    required this.collection,
    required this.entries,
    required this.onAdjust,
    this.referenceNames = const <String>[],
    this.onReferenceSelected,
  });

  final String collection;
  final List<ArcCollectionDupeEntry> entries;
  final Future<void> Function(String id, int delta) onAdjust;
  /// Used for Designs when a real name has not been linked to its game slot.
  final List<String> referenceNames;
  final Future<void> Function(String name)? onReferenceSelected;

  @override
  State<ArcCollectionDupeManager> createState() => _ArcCollectionDupeManagerState();
}

class _ArcCollectionDupeManagerState extends State<ArcCollectionDupeManager> {
  final TextEditingController _search = TextEditingController();
  String? _saving;
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _adjust(String id, int delta) async {
    if (_saving != null) return;
    setState(() { _saving = id; _error = null; });
    try {
      await widget.onAdjust(id, delta);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save that change. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  Future<void> _assignName(String name) async {
    final callback = widget.onReferenceSelected;
    if (callback == null || _saving != null) return;
    setState(() { _saving = 'name:$name'; _error = null; });
    try {
      await callback(name);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not assign that Design name.');
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final recorded = widget.entries.where((e) => e.spares > 0).length;
    final sorted = [...widget.entries]..sort((a, b) {
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) return byName;
      final byOriginalName = a.name.compareTo(b.name);
      return byOriginalName != 0 ? byOriginalName : a.id.compareTo(b.id);
    });
    final rows = sorted.where((entry) => query.isNotEmpty
        ? ('${entry.name} ${entry.detail ?? ''}').toLowerCase().contains(query)
        : entry.spares > 0).toList(growable: false);
    final assignedNames = widget.entries.map((e) => e.name).toSet();
    final suggestions = query.isEmpty ? <String>[] : widget.referenceNames
        .where((name) => name.toLowerCase().contains(query) && !assignedNames.contains(name))
        .take(20).toList(growable: false);

    return Column(
      key: const Key('collections-searchable-dupes'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
          child: Row(children: [
            Expanded(child: TextField(
              key: const Key('collections-dupes-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search ${widget.collection} to add dupes',
                prefixIcon: const Icon(Icons.search_rounded, color: uag_pass14_theme.AppTheme.neonCyan),
                suffixIcon: query.isNotEmpty ? IconButton(
                  tooltip: 'Clear duplicate search',
                  onPressed: () => setState(_search.clear),
                  icon: const Icon(Icons.close_rounded)) : null,
                filled: true,
                fillColor: uag_pass14_theme.AppTheme.cardBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
              ),
            )),
            const SizedBox(width: 9),
            Text('$recorded saved', style: const TextStyle(color: uag_pass14_theme.AppTheme.neonCyan, fontSize: 11)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(9, 0, 9, 6),
          child: Text(query.isEmpty
              ? 'Recorded spares below. Search any item name to add or remove copies.'
              : 'Use + / − to save spare copies. Adding a spare to a missing item requires confirmation.',
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ),
        if (_error != null) Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Text(_error!, style: const TextStyle(color: uag_pass14_theme.AppTheme.warningAmber, fontSize: 11))),
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          // Small, self-contained thumbnail tiles; on narrow devices they
          // wrap naturally instead of becoming wide, text-heavy rows.
          // Fit at least six compact cards across a typical landscape phone.
          final width = constraints.maxWidth;
          final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
          final columns = portrait
              ? (width >= 330 ? 4 : width >= 245 ? 3 : width >= 165 ? 2 : 1)
              : (width / 116).floor().clamp(1, 10).toInt();
          return GridView.builder(
            key: const Key('collections-dupes-results'),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              childAspectRatio: portrait ? 0.79 : 1.16,
            ),
            itemCount: rows.length + suggestions.length + (rows.isEmpty && suggestions.isEmpty ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= rows.length && i < rows.length + suggestions.length) {
                final name = suggestions[i - rows.length];
                return OutlinedButton(
                  key: Key('collections-assign-${i - rows.length}'),
                  onPressed: _saving == null ? () => _assignName(name) : null,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.add_link_rounded, color: uag_pass14_theme.AppTheme.neonCyan),
                    const SizedBox(height: 4),
                    Text(name, maxLines: 3, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    const Text('Choose game slot', style: TextStyle(color: Colors.white54, fontSize: 9)),
                  ]),
                );
              }
              if (i >= rows.length) {
                return Center(child: Text(query.isEmpty
                  ? 'No spare copies saved yet. Search a name to get started.'
                  : 'No matching items.', textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 11)));
              }
              final item = rows[i];
              final busy = _saving != null;
              return Container(
                key: Key('collections-dupe-card-${item.id}'),
                decoration: BoxDecoration(
                  color: uag_pass14_theme.AppTheme.cardBackgroundAlt,
                  border: Border.all(color: item.spares > 0
                      ? uag_pass14_theme.AppTheme.neonPink : uag_pass14_theme.AppTheme.neonCyan.withValues(alpha: 0.26)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(children: [
                    Expanded(child: Stack(fit: StackFit.expand, children: [
                      if (item.imageAssetPath != null)
                        Image.asset(item.imageAssetPath!, fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(item.icon,
                            color: uag_pass14_theme.AppTheme.neonCyan, size: 27))
                      else Icon(item.icon, color: item.owned
                        ? uag_pass14_theme.AppTheme.neonCyan : Colors.white38, size: 27),
                      if (!item.owned) const Positioned(top: 0, right: 0,
                        child: Icon(Icons.lock_outline_rounded, color: Colors.white54, size: 12)),
                    ])),
                    Tooltip(message: item.name, child: Text(item.name,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Colors.white))),
                    // The controls must fit a six-across landscape grid.
                    // Material IconButton reserves ~48px per button by default,
                    // which overflowed the ~101px wide cells. Keep hit regions
                    // bounded and retain tooltips/keys for keyboard and tests.
                    SizedBox(height: 28, child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Remove one spare ${item.name}',
                          child: InkWell(
                            key: Key('collections-dupe-minus-${item.id}'),
                            borderRadius: BorderRadius.circular(16),
                            onTap: busy || item.spares <= 0
                                ? null : () => _adjust(item.id, -1),
                            child: const SizedBox(width: 29, height: 28,
                              child: Center(child: Icon(Icons.remove_circle_outline,
                                size: 21, color: Colors.white70))),
                          ),
                        ),
                        SizedBox(width: 25, child: Text('${item.spares}',
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: uag_pass14_theme.AppTheme.neonPink,
                            fontWeight: FontWeight.bold))),
                        Tooltip(
                          message: 'Add one spare ${item.name}',
                          child: InkWell(
                            key: Key('collections-dupe-plus-${item.id}'),
                            borderRadius: BorderRadius.circular(16),
                            onTap: busy || item.spares >= 999
                                ? null : () => _adjust(item.id, 1),
                            child: const SizedBox(width: 29, height: 28,
                              child: Center(child: Icon(Icons.add_circle_outline,
                                size: 21, color: uag_pass14_theme.AppTheme.neonCyan))),
                          ),
                        ),
                      ],
                    )),
                  ]),
                ),
              );
            },
          );
        })),
      ],
    );
  }
}
