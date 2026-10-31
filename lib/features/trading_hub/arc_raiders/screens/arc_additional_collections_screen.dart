import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collections_category_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collection_dupe_manager.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart' as uag_pass14_theme;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_ad_banner_card.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_tactical_banner_ad.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_modal_surface.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_design_reference_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_design_slot_names_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_stencil_catalogue.dart';

enum ArcCollectionView { all, needed, duplicates }

enum ArcCollectionTileAction { add, clear, intel }

/// Independent permanent visual collection page for Stencils and Designs.
/// All ownership imports are explicitly reviewed. Dupes are manually entered.
/// No mutation of Blueprint ownership, acquisition or trade data is possible.
class ArcAdditionalCollectionsScreen extends StatefulWidget {
  const ArcAdditionalCollectionsScreen({
    super.key,
    required this.initialKind,
    this.loader,
    this.saver,
    this.adBanner,
    this.designNameLoader,
    this.designNameSaver,
    this.clearer,
  });

  final ArcNativeCollectionKind initialKind;
  // Injected in tests; normal operation uses authenticated Firestore repository.
  final Future<ArcAdditionalCollectionState> Function(ArcNativeCollectionKind)?
  loader;
  final Future<ArcAdditionalCollectionState> Function(
    ArcNativeCollectionKind,
    Iterable<int>,
    Map<int, int>,
  )?
  saver;

  /// The host may provide its EXISTING tier-aware advertisement widget here.
  /// No network ad placeholder is presented as a served advertisement.
  final Widget? adBanner;
  final Future<Map<int, String>> Function()? designNameLoader;
  final Future<void> Function(int, String)? designNameSaver;

  /// Optional clearing seam for widget tests; production uses a transaction.
  final Future<ArcAdditionalCollectionState> Function(
    ArcNativeCollectionKind,
    int,
  )?
  clearer;

  @override
  State<ArcAdditionalCollectionsScreen> createState() =>
      _ArcAdditionalCollectionsScreenState();
}

class _ArcAdditionalCollectionsScreenState
    extends State<ArcAdditionalCollectionsScreen> {
  final _picker = ImagePicker();
  final _repository = ArcCollectionSlotRepository();
  final _designNames = ArcDesignSlotNamesRepository();
  Map<int, String> _assignedDesignNames = <int, String>{};
  Map<String, String> _designArtworkByFilename = <String, String>{};
  final _recognizer = const ArcNativeCollectionScreenshotRecognizer();
  late ArcNativeCollectionKind _kind;
  ArcCollectionView _view = ArcCollectionView.all;
  ArcAdditionalCollectionState _saved = const ArcAdditionalCollectionState();
  List<ArcNativeSlotState> _reviewStates = const [];
  Uint8List? _screenshot;
  Map<int, int> _pendingDupes = <int, int>{};
  bool _busy = false;
  bool _loaded = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadDesignArtwork();
    _kind = widget.initialKind;
    _loadSaved();
    if (_kind == ArcNativeCollectionKind.designs) {
      _loadDesignNames();
    }
  }

  Future<void> _loadSaved() async {
    final expected = _kind;
    try {
      final state = widget.loader == null
          ? await _repository.read(expected)
          : await widget.loader!(expected);
      if (!mounted || expected != _kind) {
        return;
      }
      setState(() {
        _saved = state;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted || expected != _kind) {
        return;
      }
      setState(() {
        _loaded = true;
        _message =
            'Collection could not load. Check sign-in and account access before saving.';
      });
    }
  }

  Future<void> _loadDesignArtwork() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final found = <String, String>{};
      for (final path in manifest.listAssets()) {
        if (!path.startsWith('assets/arc_raiders/') ||
            !path.toLowerCase().endsWith('.webp')) {
          continue;
        }
        final filename = path.split('/').last.toLowerCase();
        // Only references explicitly bundled in pubspec are eligible.
        found.putIfAbsent(filename, () => path);
      }
      if (mounted) setState(() => _designArtworkByFilename = found);
    } catch (_) {
      // Missing optional artwork must never block Design grid ownership.
    }
  }

  // Do not display a single generic image in both Study Armchair slots;
  // slot 37 vs 87 rarity is unverified. Per-user rarity confirmation wins.
  String? _designArtworkForName(String name) => name == 'Study Armchair'
      ? null
      : _designArtworkByFilename[ArcDesignReferenceCatalogue.artworkFilenameForName(
          name,
        )];

  Future<void> _loadDesignNames() async {
    try {
      final names = widget.designNameLoader == null
          ? await _designNames.read()
          : await widget.designNameLoader!();
      if (!mounted || _kind != ArcNativeCollectionKind.designs) {
        return;
      }
      setState(() => _assignedDesignNames = names);
    } catch (_) {
      if (mounted && _kind == ArcNativeCollectionKind.designs) {
        setState(
          () => _message =
              'Design names could not sync. Slot ownership remains unchanged.',
        );
      }
    }
  }

  Future<void> _pickDesignName(int slot) async {
    if (_kind != ArcNativeCollectionKind.designs || _busy) {
      return;
    }
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: uag_pass14_theme.AppTheme.cardBackgroundDeep,
      builder: (sheetContext) {
        var query = '';
        return StatefulBuilder(
          builder: (sheetContext, rebuild) {
            final matches = ArcDesignReferenceCatalogue.names
                .where((n) => n.toLowerCase().contains(query.toLowerCase()))
                .toList(growable: false);
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(sheetContext).height * 0.82,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Find Design name for in-game slot $slot',
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (s) => rebuild(() => query = s),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Choose only after checking the name at this slot in-game. Names are alphabetic here, not in-game order.',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (_, i) => ListTile(
                          title: Text(
                            matches[i],
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () => Navigator.pop(sheetContext, matches[i]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (chosen == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (widget.designNameSaver == null) {
        await _designNames.assign(slot, chosen);
      } else {
        await widget.designNameSaver!(slot, chosen);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _assignedDesignNames[slot] = chosen;
        _message = 'Design slot $slot named $chosen. Ownership unchanged.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not save Design name. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _switch(ArcNativeCollectionKind kind) {
    if (_busy || kind == _kind) {
      return;
    }
    if (_reviewStates.isNotEmpty || _pendingDupes.isNotEmpty) {
      _confirmDiscard(() => _switchWithoutReview(kind));
      return;
    }
    _switchWithoutReview(kind);
  }

  void _switchWithoutReview(ArcNativeCollectionKind kind) {
    setState(() {
      _kind = kind;
      _view = ArcCollectionView.all;
      _reviewStates = const [];
      _screenshot = null;
      _pendingDupes = <int, int>{};
      _saved = const ArcAdditionalCollectionState();
      _assignedDesignNames = <int, String>{};
      _message = null;
      _loaded = false;
    });
    _loadSaved();
    if (_kind == ArcNativeCollectionKind.designs) {
      _loadDesignNames();
    }
  }

  Future<void> _confirmDiscard(VoidCallback move) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: uag_pass14_theme.AppTheme.cardBackgroundDeep,
        surfaceTintColor: Colors.transparent,
        title: const Text('Discard unsaved changes?'),
        content: const Text(
          'Screenshot reviews and unsaved duplicate edits will be lost. Saved items are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (mounted && confirm == true) {
      move();
    }
  }

  Future<void> _upload() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final chosen = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (chosen == null) {
        return;
      }
      final bytes = await chosen.readAsBytes();
      final result = _recognizer.analyse(bytes, _kind);
      if (!mounted) {
        return;
      }
      setState(() {
        _screenshot = bytes;
        _reviewStates = result.slots
            .map((s) => s.state)
            .toList(growable: false);
        _view = ArcCollectionView.all;
        _message = result.status;
      });
    } on FormatException catch (e) {
      if (mounted) {
        setState(() => _message = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Could not analyse screenshot. Use an original, uncropped in-game capture.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  int get _reviewOwnedCount =>
      _reviewStates.where((s) => s == ArcNativeSlotState.owned).length;
  int get _reviewUnknownCount =>
      _reviewStates.where((s) => s == ArcNativeSlotState.review).length;
  Set<int> get _pendingOwned => <int>{
    for (var index = 0; index < _reviewStates.length; index++)
      if (_reviewStates[index] == ArcNativeSlotState.owned) index + 1,
  };
  Set<int> get _displayOwned => <int>{
    ..._saved.ownedSlots,
    ..._pendingOwned,
    ..._pendingDupes.keys.where((k) => (_pendingDupes[k] ?? 0) > 0),
  };
  int _dupCount(int slot) =>
      _pendingDupes[slot] ?? _saved.duplicateCounts[slot] ?? 0;
  String _name(int slot) => _kind == ArcNativeCollectionKind.stencils
      ? ArcStencilCatalogue.nameAt(slot)
      : (_assignedDesignNames[slot] ??
            ArcDesignReferenceCatalogue.nameAt(slot) ??
            'Design slot $slot');

  void _cycleReview(int slot) {
    if (_reviewStates.length != _kind.slots || _busy) {
      return;
    }
    final states = List<ArcNativeSlotState>.of(_reviewStates);
    states[slot - 1] = switch (states[slot - 1]) {
      ArcNativeSlotState.owned => ArcNativeSlotState.missing,
      ArcNativeSlotState.missing => ArcNativeSlotState.review,
      ArcNativeSlotState.review => ArcNativeSlotState.owned,
    };
    setState(() => _reviewStates = states);
  }

  Future<void> _saveOneDupe(int slot, int change) async {
    if (_busy || !_loaded) {
      return;
    }
    if (change > 0 && !_displayOwned.contains(slot)) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: uag_pass14_theme.AppTheme.cardBackgroundDeep,
          surfaceTintColor: Colors.transparent,
          title: Text('Own ${_name(slot)}?'),
          content: const Text(
            'This item is marked missing. Confirm you own one AND have a spare copy before adding +1.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Own it + add spare'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) {
        return;
      }
    }
    final nextCount = (_dupCount(slot) + change).clamp(0, 999);
    if (nextCount == _dupCount(slot)) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final existing = _saved.ownedSlots;
      final owned = <int>{...existing, slot};
      final edited = <int, int>{slot: nextCount};
      final result = widget.saver == null
          ? await _repository.save(
              kind: _kind,
              addOwned: owned,
              editedDuplicates: edited,
            )
          : await widget.saver!(_kind, owned, edited);
      if (!mounted) {
        return;
      }
      setState(() {
        _saved = result;
        _pendingDupes.remove(slot);
        _message = '${_name(slot)}: $nextCount spare copies saved.';
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Duplicate could not be saved. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _setOwned(int slot, {required bool owned}) async {
    if (_busy || !_loaded) {
      return;
    }
    final kind = _kind;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = owned
          ? (widget.saver == null
                ? await _repository.save(kind: kind, addOwned: <int>{slot})
                : await widget.saver!(kind, <int>{slot}, const <int, int>{}))
          : (widget.clearer == null
                ? await _repository.save(
                    kind: kind,
                    addOwned: const <int>{},
                    clearOwned: <int>{slot},
                  )
                : await widget.clearer!(kind, slot));
      if (!mounted || kind != _kind) {
        return;
      }
      setState(() {
        _saved = result;
        _pendingDupes.remove(slot);
        // An in-progress screenshot must not silently restore a cleared card.
        if (_reviewStates.length == kind.slots) {
          final next = List<ArcNativeSlotState>.from(_reviewStates);
          next[slot - 1] = ArcNativeSlotState.missing;
          _reviewStates = next;
        }
        _message = owned ? '${_name(slot)} added.' : '${_name(slot)} cleared.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not update collection. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // Community-maintained item source guidance. Not a guaranteed drop location.
  static String _stencilSource(int slot) {
    if (slot == 9) {
      return 'Collector Set DLC';
    }
    if (<int>{4, 8, 10, 11, 12}.contains(slot)) {
      return 'Frozen Trail Premium Reward Pass';
    }
    return 'Topside containers (random drop)';
  }

  Future<void> _showCollectionIntel(int slot) async {
    final name = _name(slot);
    final isDesign = _kind == ArcNativeCollectionKind.designs;
    final verifiedName = !isDesign || _assignedDesignNames.containsKey(slot);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: uag_pass14_theme.AppTheme.cardBackgroundDeep,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INTEL · $name',
                key: const Key('collections-intel-title'),
                style: const TextStyle(
                  color: uag_pass14_theme.AppTheme.neonCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_kind.title} · Slot $slot',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Text(
                isDesign
                    ? (verifiedName
                          ? 'No item-specific source confirmed.'
                          : 'Assign the in-game Design name to identify it correctly.')
                    : _stencilSource(slot),
                key: const Key('collections-intel-status'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                isDesign
                    ? 'Outpost, Topside and Reward Pass Designs have different sources.'
                    : 'Community-reported acquisition type. No guaranteed map location.',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              if (isDesign && !verifiedName) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('collections-intel-assign-name'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _pickDesignName(slot);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Assign Design name'),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _details(int slot) async {
    final picked = await showModalBottomSheet<ArcCollectionTileAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) {
          final owned = _displayOwned.contains(slot);
          return ArcModalSurface(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                18,
                12,
                18,
                MediaQuery.viewInsetsOf(ctx).bottom + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name(slot).toUpperCase(),
                    style: ArcUiTokens.sectionTitle(
                      fontSize: 22,
                      color: ArcUiTokens.primaryAccent,
                    ),
                  ),
                  Text(
                    '${_kind.title} · Position $slot · ${owned ? 'Owned' : 'Needed'}',
                    style: const TextStyle(
                      color: uag_pass14_theme.AppTheme.neonCyan,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('collections-action-add'),
                        onPressed: _busy || owned
                            ? null
                            : () => Navigator.pop(
                                ctx,
                                ArcCollectionTileAction.add,
                              ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('ADD'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('collections-action-clear'),
                        onPressed: _busy || !owned
                            ? null
                            : () => Navigator.pop(
                                ctx,
                                ArcCollectionTileAction.clear,
                              ),
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('CLEAR'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('collections-action-intel'),
                        onPressed: () =>
                            Navigator.pop(ctx, ArcCollectionTileAction.intel),
                        icon: const Icon(Icons.radar_outlined),
                        label: const Text('INTEL'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_reviewStates.length == _kind.slots) ...[
                    TextButton.icon(
                      key: const Key('collections-review-cycle'),
                      onPressed: () {
                        _cycleReview(slot);
                        refresh(() {});
                      },
                      icon: const Icon(Icons.fact_check_outlined),
                      label: Text(
                        'Screenshot says: ${_reviewStates[slot - 1].name} · Tap to change',
                      ),
                    ),
                  ],
                  if (_kind == ArcNativeCollectionKind.designs)
                    TextButton.icon(
                      key: const Key('collections-assign-design-name'),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: uag_pass14_theme.AppTheme.neonCyan,
                      ),
                      label: Text(
                        _assignedDesignNames.containsKey(slot)
                            ? 'Correct Design name'
                            : 'Assign verified Design name',
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _pickDesignName(slot);
                      },
                    ),
                  if (owned)
                    Row(
                      children: [
                        const Text(
                          'Spare copies (manual): ',
                          style: TextStyle(color: Colors.white),
                        ),
                        IconButton(
                          key: const Key('collections-decrease-dupes'),
                          onPressed: _busy
                              ? null
                              : () async {
                                  await _saveOneDupe(slot, -1);
                                  if (ctx.mounted) refresh(() {});
                                },
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_dupCount(slot)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Tooltip(
                          key: const Key('collections-quick-add-dupe'),
                          message: 'Add Dupe +1',
                          child: IconButton(
                            key: const Key('collections-increase-dupes'),
                            tooltip: 'Add one spare',
                            onPressed: _busy
                                ? null
                                : () async {
                                    await _saveOneDupe(slot, 1);
                                    if (ctx.mounted) {
                                      refresh(() {});
                                    }
                                  },
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: uag_pass14_theme.AppTheme.neonCyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (!mounted || picked == null) {
      return;
    }
    if (picked == ArcCollectionTileAction.add) {
      await _setOwned(slot, owned: true);
    } else if (picked == ArcCollectionTileAction.clear) {
      await _setOwned(slot, owned: false);
    } else if (picked == ArcCollectionTileAction.intel) {
      await _showCollectionIntel(slot);
    }
  }

  Future<void> _saveAndContinue() async {
    if (_busy || !_loaded) {
      return;
    }
    final additions = _pendingOwned.difference(_saved.ownedSlots);
    if (_reviewStates.isEmpty && _pendingDupes.isEmpty) {
      setState(() {
        _reviewStates = const [];
        _screenshot = null;
        _message =
            'Already up to date. Continue browsing your saved collection.';
      });
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: uag_pass14_theme.AppTheme.cardBackgroundDeep,
        surfaceTintColor: Colors.transparent,
        title: Text('Save ${_kind.title} collection?'),
        content: Text(
          'Add ${additions.length} owned positions and save ${_pendingDupes.length} manually edited duplicate counts? '
          '$_reviewUnknownCount screenshot positions require review and will not be imported. '
          'Missing slots will NEVER remove previously saved ownership.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save & Continue'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final state = widget.saver == null
          ? await _repository.save(
              kind: _kind,
              addOwned: <int>{..._pendingOwned, ..._saved.ownedSlots},
              editedDuplicates: _pendingDupes,
            )
          : await widget.saver!(_kind, <int>{
              ..._pendingOwned,
              ..._saved.ownedSlots,
            }, Map<int, int>.of(_pendingDupes));
      if (!mounted) {
        return;
      }
      setState(() {
        _saved = state;
        _reviewStates = const [];
        _screenshot = null;
        _pendingDupes = <int, int>{};
        _message =
            'Saved and ready. Your ${_kind.title} collection is shown below.';
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Save failed. Changes are still available for retry. Check account permissions or connection.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _share() async {
    if (!_loaded) {
      return;
    }
    ArcCollectionShareItem itemAt(int slot) => ArcCollectionShareItem(
      label: _name(slot),
      assetPath: _kind == ArcNativeCollectionKind.stencils
          ? ArcStencilCatalogue.assetAt(slot)
          : null,
      spares: _saved.duplicateCounts[slot] ?? 0,
    );
    final owned = <ArcCollectionShareItem>[
      for (var slot = 1; slot <= _kind.slots; slot++)
        if (_saved.ownedSlots.contains(slot)) itemAt(slot),
    ];
    final needed = <ArcCollectionShareItem>[
      for (var slot = 1; slot <= _kind.slots; slot++)
        if (!_saved.ownedSlots.contains(slot)) itemAt(slot),
    ];
    final duplicates = <ArcCollectionShareItem>[
      for (var slot = 1; slot <= _kind.slots; slot++)
        if ((_saved.duplicateCounts[slot] ?? 0) > 0) itemAt(slot),
    ];
    if (!mounted) {
      return;
    }
    await ArcCollectionVisualShare.show(
      context: context,
      title: _kind.title,
      owned: owned,
      needed: needed,
      duplicates: duplicates,
    );
  }

  Widget _slotCard(int slot, double cardWidth) {
    final owned = _displayOwned.contains(slot);
    final dupes = _dupCount(slot);
    final relevant =
        _view == ArcCollectionView.all ||
        (_view == ArcCollectionView.needed && !owned) ||
        (_view == ArcCollectionView.duplicates && dupes > 0);
    final review =
        _reviewStates.length == _kind.slots &&
        _reviewStates[slot - 1] == ArcNativeSlotState.review;
    final name = _name(slot);
    final cardName = name;
    return Opacity(
      opacity: relevant ? 1 : .21,
      child: InkWell(
        key: Key('collections-saved-slot-$slot'),
        onTap: () => _details(slot),
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: owned
                ? uag_pass14_theme.AppTheme.cardBackgroundAlt
                : uag_pass14_theme.AppTheme.cardBackgroundDeep,
            border: Border.all(
              color: review
                  ? uag_pass14_theme.AppTheme.warningAmber
                  : dupes > 0
                  ? uag_pass14_theme.AppTheme.neonPink
                  : uag_pass14_theme.AppTheme.neonCyan.withValues(alpha: 0.25),
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_kind == ArcNativeCollectionKind.stencils)
                      Image.asset(
                        ArcStencilCatalogue.assetAt(slot),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          owned ? Icons.palette_outlined : Icons.lock_outline,
                          color: owned ? Colors.cyanAccent : Colors.white30,
                          size: 18,
                        ),
                      )
                    else
                      Icon(
                        owned ? Icons.weekend_outlined : Icons.lock_outline,
                        size: 18,
                        color: owned ? Colors.cyanAccent : Colors.white30,
                      ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        owned
                            ? Icons.check_circle
                            : Icons.remove_circle_outline,
                        size: 12,
                        color: owned
                            ? uag_pass14_theme.AppTheme.warningAmber
                            : Colors.white30,
                      ),
                    ),
                    if (dupes > 0)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Text(
                          '+$dupes',
                          style: const TextStyle(
                            fontSize: 10,
                            color: uag_pass14_theme.AppTheme.neonPink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Tooltip(
                message: name,
                child: Text(
                  cardName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: cardWidth >= 95
                        ? 10
                        : cardWidth >= 55
                        ? 9
                        : 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// Designs only: compact controls either side of an actual 320x50 ad.
  /// The entitlement-aware banner still governs whether an ad may appear.
  Widget _designsBottomDock(bool hasPending) {
    Widget action({
      required Key key,
      required String label,
      required IconData icon,
      required VoidCallback? onTap,
      required bool iconOnly,
      bool selected = false,
      bool camera = false,
    }) => Expanded(
      child: Tooltip(
        message: label,
        child: SizedBox(
          height: hasPending ? 34 : 42,
          child: OutlinedButton(
            key: key,
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              backgroundColor: camera
                  ? uag_pass14_theme.AppTheme.neonPink
                  : selected
                  ? uag_pass14_theme.AppTheme.cardBackgroundAlt
                  : uag_pass14_theme.AppTheme.cardBackground,
              foregroundColor: camera
                  ? uag_pass14_theme.AppTheme.darkBackground
                  : selected
                  ? uag_pass14_theme.AppTheme.neonCyan
                  : Colors.white70,
              side: BorderSide(
                color: camera || selected
                    ? uag_pass14_theme.AppTheme.neonCyan
                    : uag_pass14_theme.AppTheme.neonCyan.withValues(alpha: 0.34),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 17),
                  if (!iconOnly) ...[
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return SafeArea(
      top: false,
      child: Container(
        key: const Key('collections-designs-bottom-dock'),
        padding: const EdgeInsets.fromLTRB(7, 2, 7, 2),
        decoration: BoxDecoration(
          color: uag_pass14_theme.AppTheme.darkBackground,
          border: Border(
            top: BorderSide(
              color: uag_pass14_theme.AppTheme.neonCyan.withValues(alpha: 0.25),
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconOnly = constraints.maxWidth < 730;
            // Keep full 320-pixel AdMob creative in an independent 326-344px lane.
            final adWidth = math.min(
              344.0,
              math.max(326.0, constraints.maxWidth * 0.43),
            );
            return SizedBox(
              height: 74,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            action(
                              key: const Key('collections-filter-all'),
                              label: 'ALL',
                              icon: Icons.apps_rounded,
                              iconOnly: iconOnly,
                              selected: _view == ArcCollectionView.all,
                              onTap: () => setState(() => _view = ArcCollectionView.all),
                            ),
                            const SizedBox(width: 4),
                            action(
                              key: const Key('collections-filter-needed'),
                              label: 'NEEDED',
                              icon: Icons.help_outline_rounded,
                              iconOnly: iconOnly,
                              selected: _view == ArcCollectionView.needed,
                              onTap: () => setState(() => _view = ArcCollectionView.needed),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_saved.ownedSlots.length}/${_kind.slots} OWNED',
                          key: const Key('collections-design-owned-count'),
                          style: const TextStyle(
                            color: uag_pass14_theme.AppTheme.neonCyan,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    key: const Key('collections-design-fitted-ad'),
                    width: adWidth,
                    height: 74,
                    child: Center(
                      child: widget.adBanner ??
                          const ArcBlueprintBannerSlot(
                            banner: UagTacticalBannerAd(
                              margin: EdgeInsets.fromLTRB(2, 6, 2, 8),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            action(
                              key: const Key('collections-upload-native-screenshot'),
                              label: 'CAMERA',
                              icon: Icons.camera_alt_outlined,
                              onTap: _busy ? null : _upload,
                              iconOnly: iconOnly,
                              camera: true,
                            ),
                            const SizedBox(width: 4),
                            action(
                              key: const Key('collections-share'),
                              label: 'SHARE',
                              icon: Icons.share_outlined,
                              onTap: _loaded && !_busy ? _share : null,
                              iconOnly: iconOnly,
                            ),
                          ],
                        ),
                        if (hasPending) ...[
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 30,
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              key: const Key('collections-save-continue'),
                              onPressed: _loaded && !_busy ? _saveAndContinue : null,
                              icon: const Icon(Icons.save_outlined, size: 14),
                              label: const Text('SAVE', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _toolsRail(bool hasPending) {
    Widget action({
      required Key key,
      required String title,
      required IconData icon,
      required VoidCallback? onTap,
      bool selected = false,
      bool camera = false,
    }) => SizedBox(
      width: double.infinity,
      height: 43,
      child: OutlinedButton.icon(
        key: key,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          foregroundColor: camera
              ? uag_pass14_theme.AppTheme.darkBackground
              : selected
              ? uag_pass14_theme.AppTheme.neonCyan
              : Colors.white70,
          backgroundColor: camera
              ? uag_pass14_theme.AppTheme.neonPink
              : selected
              ? uag_pass14_theme.AppTheme.cardBackgroundAlt
              : uag_pass14_theme.AppTheme.cardBackground,
          side: BorderSide(
            color: camera
                ? uag_pass14_theme.AppTheme.neonCyan
                : selected
                ? uag_pass14_theme.AppTheme.neonCyan
                : uag_pass14_theme.AppTheme.neonCyan.withValues(alpha: 0.25),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 20,
          color: camera ? uag_pass14_theme.AppTheme.darkBackground : null,
        ),
        label: title.isEmpty
            ? const SizedBox.shrink()
            : Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.fade,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: uag_pass14_theme.AppTheme.cardBackgroundDeep.withValues(
          alpha: 0.87,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: uag_pass14_theme.AppTheme.neonCyan.withValues(alpha: 0.28),
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          action(
            key: const Key('collections-upload-native-screenshot'),
            title: '',
            icon: Icons.camera_alt_outlined,
            onTap: _busy ? null : _upload,
            camera: true,
          ),
          const SizedBox(height: 8),
          action(
            key: const Key('collections-filter-all'),
            title: 'ALL',
            icon: Icons.apps_rounded,
            onTap: () => setState(() => _view = ArcCollectionView.all),
            selected: _view == ArcCollectionView.all,
          ),
          const SizedBox(height: 7),
          action(
            key: const Key('collections-filter-needed'),
            title: 'NEEDED',
            icon: Icons.help_outline_rounded,
            onTap: () => setState(() => _view = ArcCollectionView.needed),
            selected: _view == ArcCollectionView.needed,
          ),
          const SizedBox(height: 7),
          // Dupe navigation is in the top bar. The rail remains compact.
          action(
            key: const Key('collections-share'),
            title: 'SHARE',
            icon: Icons.share_outlined,
            onTap: _loaded && !_busy ? _share : null,
          ),
          if (hasPending) ...[
            const SizedBox(height: 7),
            action(
              key: const Key('collections-save-continue'),
              title: 'SAVE',
              icon: Icons.save_outlined,
              onTap: _loaded && !_busy ? _saveAndContinue : null,
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${_saved.ownedSlots.length}/${_kind.slots}',
              style: const TextStyle(
                color: uag_pass14_theme.AppTheme.neonCyan,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A Design must be tied to the right in-game slot before spare copies
  /// are advertised. The reference list is alphabetic, not the 17-column order.
  Future<void> _assignDesignFromDupeSearch(String name) async {
    if (_kind != ArcNativeCollectionKind.designs || _busy) {
      return;
    }
    if (_assignedDesignNames.containsValue(name)) {
      return;
    }
    var typedSlot = '';
    final slot = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: uag_pass14_theme.AppTheme.cardBackgroundDeep,
        surfaceTintColor: Colors.transparent,
        title: Text('Choose in-game slot for $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Check the Design position in your game first. The 100 reference names are not sorted in game order.',
            ),
            TextField(
              key: const Key('collections-design-slot-input'),
              onChanged: (value) => typedSlot = value,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Game slot number (1–100)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(typedSlot);
              if (n != null && n >= 1 && n <= 100) {
                Navigator.pop(ctx, n);
              }
            },
            child: const Text('Use this slot'),
          ),
        ],
      ),
    );
    if (slot == null || !mounted) {
      return;
    }
    final previousName = _assignedDesignNames[slot];
    if (previousName != null && previousName != name) {
      final change = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: uag_pass14_theme.AppTheme.cardBackgroundDeep,
          surfaceTintColor: Colors.transparent,
          title: const Text('Correct saved Design name?'),
          content: Text(
            'Slot $slot is currently labelled $previousName. Replace it with $name? Ownership and spare quantities are not changed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace name'),
            ),
          ],
        ),
      );
      if (change != true || !mounted) {
        return;
      }
    }
    if (widget.designNameSaver == null) {
      await _designNames.assign(slot, name);
    } else {
      await widget.designNameSaver!(slot, name);
    }
    if (mounted) {
      setState(() {
        _assignedDesignNames[slot] = name;
        _message = '$name linked to Design slot $slot. Use + to add a spare.';
      });
    }
  }

  Widget _buildCollectionDupeSearch() {
    return ArcCollectionDupeManager(
      collection: _kind.title,
      entries: [
        for (var slot = 1; slot <= _kind.slots; slot++)
          ArcCollectionDupeEntry(
            id: '$slot',
            name: _name(slot),
            owned: _displayOwned.contains(slot),
            spares: _dupCount(slot),
            imageAssetPath: _kind == ArcNativeCollectionKind.stencils
                ? ArcStencilCatalogue.assetAt(slot)
                : _designArtworkForName(_name(slot)),
            icon: Icons.weekend_outlined,
            detail: _kind == ArcNativeCollectionKind.designs
                ? 'Game slot $slot'
                : null,
          ),
      ],
      onAdjust: (id, delta) => _saveOneDupe(int.parse(id), delta),
      referenceNames: _kind == ArcNativeCollectionKind.designs
          ? ArcDesignReferenceCatalogue.names
          : const <String>[],
      onReferenceSelected: _kind == ArcNativeCollectionKind.designs
          ? _assignDesignFromDupeSearch
          : null,
    );
  }

  Widget _grid() {
    if (_kind == ArcNativeCollectionKind.designs) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Authoritative game order: 17 columns, six rows (final row partial).
          // Show exactly two full rows at a time; the remaining slots scroll vertically.
          // Do not reorder, filter out or remap any saved slot identity.
          const columns = 17;
          const gap = 3.0;
          const inset = 5.0;
          final cardWidth =
              (constraints.maxWidth - (inset * 2) - gap * (columns - 1)) /
              columns;
          final rowHeight = math.max(
            1.0,
            (constraints.maxHeight - inset * 2 - gap) / 2,
          );
          return GridView.builder(
            key: const Key('collections-design-readable-gallery'),
            padding: const EdgeInsets.all(inset),
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              mainAxisExtent: rowHeight,
            ),
            itemCount: _kind.slots,
            itemBuilder: (context, index) {
              final slot = index + 1;
              final name = _name(slot);
              final owned = _displayOwned.contains(slot);
              final copies = _dupCount(slot);
              final matchesFilter =
                  _view == ArcCollectionView.all ||
                  (_view == ArcCollectionView.needed && !owned) ||
                  (_view == ArcCollectionView.duplicates && copies > 0);
              // Full names remain accessible by tap and tooltip. Small physical
              // screens cannot fit long titles in 17 columns without wrapping.
              return Opacity(
                opacity: matchesFilter ? 1 : 0.25,
                child: Tooltip(
                  message: name,
                  child: InkWell(
                    key: Key('collections-saved-slot-$slot'),
                    onTap: () => _details(slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: owned
                            ? uag_pass14_theme.AppTheme.cardBackgroundAlt
                            : uag_pass14_theme.AppTheme.cardBackgroundDeep,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: copies > 0
                              ? uag_pass14_theme.AppTheme.neonPink
                              : uag_pass14_theme.AppTheme.neonCyan.withValues(
                                  alpha: 0.25,
                                ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  owned
                                      ? Icons.weekend_outlined
                                      : Icons.lock_outline,
                                  size: cardWidth < 42 ? 17 : 28,
                                  color: owned
                                      ? Colors.cyanAccent
                                      : Colors.white38,
                                ),
                                if (_designArtworkForName(name)
                                    case final String artwork)
                                  Positioned.fill(
                                    child: Image.asset(
                                      artwork,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const SizedBox.shrink(),
                                    ),
                                  ),
                                if (copies > 0)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Text(
                                      '+$copies',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color:
                                            uag_pass14_theme.AppTheme.neonPink,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: math.min(54.0, rowHeight * 0.28),
                            child: Center(
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: cardWidth >= 78
                                      ? 10
                                      : cardWidth >= 52
                                      ? 9
                                      : 8,
                                  height: 1.05,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }
    final columns = _kind.columns;
    final rows = (_kind.slots / columns).ceil();
    const gap = 3.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final byWidth = (width - gap * (columns - 1)) / columns;
        final byHeight = (height - gap * (rows - 1)) / (rows * 1.12);
        // Keep exact in-game column counts. On narrow devices pinch/pan is available.
        final cardWidth = math.max(
          18.0,
          math.min(108.0, math.min(byWidth, byHeight)),
        );
        final cardHeight = cardWidth * 1.12;
        return ClipRect(
          child: InteractiveViewer(
            key: const Key('collections-pinch-zoom-grid'),
            constrained: false,
            panEnabled: true,
            scaleEnabled: true,
            minScale: 0.75,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(64),
            child: SizedBox(
              width: columns * cardWidth + gap * (columns - 1),
              height: rows * cardHeight + gap * (rows - 1),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _kind.slots,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap,
                  childAspectRatio: cardWidth / cardHeight,
                ),
                itemBuilder: (context, index) =>
                    _slotCard(index + 1, cardWidth),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _reviewStates.isNotEmpty || _pendingDupes.isNotEmpty;
    return Scaffold(
      backgroundColor: uag_pass14_theme.AppTheme.darkBackground,
      appBar: AppBar(
        titleSpacing: 0,
        toolbarHeight: 48,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final width = MediaQuery.sizeOf(context).width;
            return Row(
              children: [
                Text(
                  'Collections Tracker',
                  style: ArcUiTokens.pageTitle(
                    fontSize: width < 430 ? 17 : 19,
                    color: ArcUiTokens.primaryAccent,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: ArcCollectionsCategoryBar(
                        selected: _kind == ArcNativeCollectionKind.stencils
                            ? ArcCollectionsCategory.stencils
                            : ArcCollectionsCategory.designs,
                        showDupes: true,
                        dupesSelected: _view == ArcCollectionView.duplicates,
                        onDupesSelected: () => setState(
                          () => _view = ArcCollectionView.duplicates,
                        ),
                        onSelected: (category) {
                          if (_busy) {
                            return;
                          }
                          if (category == ArcCollectionsCategory.blueprints) {
                            if (hasPending) {
                              _confirmDiscard(() => Navigator.pop(context));
                            } else {
                              Navigator.pop(context);
                            }
                            return;
                          }
                          final next =
                              category == ArcCollectionsCategory.stencils
                              ? ArcNativeCollectionKind.stencils
                              : ArcNativeCollectionKind.designs;
                          if (next == _kind &&
                              _view == ArcCollectionView.duplicates) {
                            setState(() => _view = ArcCollectionView.all);
                          } else {
                            _switch(next);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: uag_pass14_theme.AppTheme.neonCyan,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Collections menu',
            icon: const Icon(
              Icons.menu_rounded,
              color: uag_pass14_theme.AppTheme.neonPink,
            ),
            onSelected: (action) {
              if (action == 'all') {
                setState(() => _view = ArcCollectionView.all);
              }
              if (action == 'needed') {
                setState(() => _view = ArcCollectionView.needed);
              }
              if (action == 'dupes') {
                setState(() => _view = ArcCollectionView.duplicates);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all', child: Text('All')),
              PopupMenuItem(value: 'needed', child: Text('Needed')),
              PopupMenuItem(value: 'dupes', child: Text('Dupes')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _kind == ArcNativeCollectionKind.designs
          ? _designsBottomDock(hasPending)
          : widget.adBanner ?? const ArcBlueprintBannerSlot(),
      body: SafeArea(
        top: false,
        bottom: false,
        right: true,
        left: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            6,
            2,
            _kind == ArcNativeCollectionKind.designs ? 6 : 18,
            4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_busy || !_loaded) const LinearProgressIndicator(),
              if (_message != null)
                Text(
                  _message!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: uag_pass14_theme.AppTheme.warningAmber,
                    fontSize: 11,
                  ),
                ),
              if (_reviewStates.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'SCREENSHOT REVIEW: $_reviewOwnedCount owned · $_reviewUnknownCount uncertain. Tap any card to verify.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (_screenshot != null)
                      TextButton(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor:
                                uag_pass14_theme.AppTheme.cardBackgroundDeep,
                            surfaceTintColor: Colors.transparent,
                            child: InteractiveViewer(
                              child: Image.memory(
                                _screenshot!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        child: const Text('View original'),
                      ),
                  ],
                ),
              const SizedBox(height: 4),
              // Designs use the balanced bottom dock; Stencils keep the original rail.
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _view == ArcCollectionView.duplicates
                          ? _buildCollectionDupeSearch()
                          : _grid(),
                    ),
                    if (_kind != ArcNativeCollectionKind.designs) ...[
                      const SizedBox(width: 6),
                      SizedBox(width: 113, child: _toolsRail(hasPending)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
