import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collections_category_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collection_dupe_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_ad_banner_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_design_reference_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_design_slot_names_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_stencil_catalogue.dart';

enum ArcCollectionView { all, needed, duplicates }

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
  });

  final ArcNativeCollectionKind initialKind;
  // Injected in tests; normal operation uses authenticated Firestore repository.
  final Future<ArcAdditionalCollectionState> Function(ArcNativeCollectionKind)? loader;
  final Future<ArcAdditionalCollectionState> Function(
      ArcNativeCollectionKind, Iterable<int>, Map<int, int>)? saver;
  /// The host may provide its EXISTING tier-aware advertisement widget here.
  /// No network ad placeholder is presented as a served advertisement.
  final Widget? adBanner;
  final Future<Map<int, String>> Function()? designNameLoader;
  final Future<void> Function(int, String)? designNameSaver;

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
    _kind = widget.initialKind;
    _loadSaved();
    if (_kind == ArcNativeCollectionKind.designs) _loadDesignNames();
  }

  Future<void> _loadSaved() async {
    final expected = _kind;
    try {
      final state = widget.loader == null
          ? await _repository.read(expected)
          : await widget.loader!(expected);
      if (!mounted || expected != _kind) return;
      setState(() {
        _saved = state;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted || expected != _kind) return;
      setState(() {
        _loaded = true;
        _message = 'Collection could not load. Check sign-in and account access before saving.';
      });
    }
  }

  Future<void> _loadDesignNames() async {
    try {
      final names = widget.designNameLoader == null
          ? await _designNames.read() : await widget.designNameLoader!();
      if (!mounted || _kind != ArcNativeCollectionKind.designs) return;
      setState(() => _assignedDesignNames = names);
    } catch (_) {
      if (mounted && _kind == ArcNativeCollectionKind.designs) {
        setState(() => _message = 'Design names could not sync. Slot ownership remains unchanged.');
      }
    }
  }

  Future<void> _pickDesignName(int slot) async {
    if (_kind != ArcNativeCollectionKind.designs || _busy) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0C1B26),
      builder: (sheetContext) {
        var query = '';
        return StatefulBuilder(builder: (sheetContext, rebuild) {
          final matches = ArcDesignReferenceCatalogue.names
            .where((n) => n.toLowerCase().contains(query.toLowerCase()))
            .toList(growable: false);
          return SafeArea(child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.82,
            child: Column(children: [
              Padding(padding: const EdgeInsets.all(12),
                child: TextField(
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Find Design name for in-game slot $slot',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (s) => rebuild(() => query = s),
                )),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Choose only after checking the name at this slot in-game. Names are alphabetic here, not in-game order.',
                  style: TextStyle(color: Colors.white60, fontSize: 11))),
              Expanded(child: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (_, i) {
                  final name = matches[i];
                  final artwork = ArcDesignReferenceCatalogue.artworkForName(name);
                  return ListTile(
                    leading: artwork == null
                        ? const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.weekend_outlined, color: Colors.white38),
                          )
                        : Image.asset(
                            artwork,
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(Icons.weekend_outlined, color: Colors.white38),
                            ),
                          ),
                    title: Text(name, style: const TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(sheetContext, name),
                  );
                },
              )),
            ]),
          ));
        });
      },
    );
    if (chosen == null || !mounted) return;
    setState(() => _busy = true);
    try {
      if (widget.designNameSaver == null) {
        await _designNames.assign(slot, chosen);
      } else {
        await widget.designNameSaver!(slot, chosen);
      }
      if (!mounted) return;
      setState(() {
        _assignedDesignNames[slot] = chosen;
        _message = 'Design slot $slot named $chosen. Ownership unchanged.';
      });
    } catch (_) {
      if (mounted) setState(() => _message = 'Could not save Design name. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _switch(ArcNativeCollectionKind kind) {
    if (_busy || kind == _kind) return;
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
    if (_kind == ArcNativeCollectionKind.designs) _loadDesignNames();
  }

  Future<void> _confirmDiscard(VoidCallback move) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text('Screenshot reviews and unsaved duplicate edits will be lost. Saved items are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    if (mounted && confirm == true) move();
  }

  Future<void> _upload() async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; });
    try {
      final chosen = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (chosen == null) return;
      final bytes = await chosen.readAsBytes();
      final result = _recognizer.analyse(bytes, _kind);
      if (!mounted) return;
      setState(() {
        _screenshot = bytes;
        _reviewStates = result.slots.map((s) => s.state).toList(growable: false);
        _view = ArcCollectionView.all;
        _message = result.status;
      });
    } on FormatException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'Could not analyse screenshot. Use an original, uncropped in-game capture.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int get _reviewOwnedCount => _reviewStates.where((s) => s == ArcNativeSlotState.owned).length;
  int get _reviewUnknownCount => _reviewStates.where((s) => s == ArcNativeSlotState.review).length;
  Set<int> get _pendingOwned => <int>{
    for (var index = 0; index < _reviewStates.length; index++)
      if (_reviewStates[index] == ArcNativeSlotState.owned) index + 1,
  };
  Set<int> get _displayOwned => <int>{..._saved.ownedSlots, ..._pendingOwned, ..._pendingDupes.keys.where((k) => (_pendingDupes[k] ?? 0) > 0)};
  int _dupCount(int slot) => _pendingDupes[slot] ?? _saved.duplicateCounts[slot] ?? 0;
  String _name(int slot) => _kind == ArcNativeCollectionKind.stencils
      ? ArcStencilCatalogue.nameAt(slot)
      : ArcDesignReferenceCatalogue.displayNameForSlot(
            slot, _assignedDesignNames) ?? 'Design slot $slot';

  String? _artworkAtSlot(int slot) =>
      _kind == ArcNativeCollectionKind.stencils
          ? ArcStencilCatalogue.assetAt(slot)
          : ArcDesignReferenceCatalogue.artworkForDisplaySlot(
              slot,
              _assignedDesignNames,
            );

  void _cycleReview(int slot) {
    if (_reviewStates.length != _kind.slots || _busy) return;
    final states = List<ArcNativeSlotState>.of(_reviewStates);
    states[slot - 1] = switch (states[slot - 1]) {
      ArcNativeSlotState.owned => ArcNativeSlotState.missing,
      ArcNativeSlotState.missing => ArcNativeSlotState.review,
      ArcNativeSlotState.review => ArcNativeSlotState.owned,
    };
    setState(() => _reviewStates = states);
  }

  Future<void> _saveOneDupe(int slot, int change) async {
    if (_busy || !_loaded) return;
    if (change > 0 && !_displayOwned.contains(slot)) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Own ${_name(slot)}?'),
          content: const Text('This item is marked missing. Confirm you own one AND have a spare copy before adding +1.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Own it + add spare')),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }
    final nextCount = (_dupCount(slot) + change).clamp(0, 999);
    if (nextCount == _dupCount(slot)) return;
    setState(() { _busy = true; _message = null; });
    try {
      final existing = _saved.ownedSlots;
      final owned = <int>{...existing, slot};
      final edited = <int, int>{slot: nextCount};
      final result = widget.saver == null
          ? await _repository.save(kind: _kind, addOwned: owned, editedDuplicates: edited)
          : await widget.saver!(_kind, owned, edited);
      if (!mounted) return;
      setState(() {
        _saved = result;
        _pendingDupes.remove(slot);
        _message = '${_name(slot)}: $nextCount spare copies saved.';
      });
    } catch (_) {
      if (mounted) setState(() => _message = 'Duplicate could not be saved. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _details(int slot) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111B26),
      builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) {
        final owned = _displayOwned.contains(slot);
        final artwork = _artworkAtSlot(slot);
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              18, 12, 18, MediaQuery.viewInsetsOf(ctx).bottom + 12),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_name(slot), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
              Text('${_kind.title} · Position $slot · ${owned ? 'Owned' : 'Needed'}',
                  style: const TextStyle(color: Color(0xFF75DBE5))),
              const SizedBox(height: 8),
              if (artwork != null) ...[
                Center(
                  child: SizedBox(
                    height: 120,
                    width: 120,
                    child: Image.asset(
                      artwork,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: Colors.white30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (_reviewStates.length == _kind.slots) ...[
                TextButton.icon(
                  key: const Key('collections-review-cycle'),
                  onPressed: () { _cycleReview(slot); refresh(() {}); },
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text('Screenshot says: ${_reviewStates[slot-1].name} · Tap to change'),
                ),
              ],
              if (_kind == ArcNativeCollectionKind.designs) TextButton.icon(
                key: const Key('collections-assign-design-name'),
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF64E8EF)),
                label: Text(_assignedDesignNames.containsKey(slot)
                    ? 'Correct Design name' : 'Assign verified Design name'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _pickDesignName(slot);
                },
              ),
              if (owned) Row(children: [
                const Text('Spare copies (manual): ', style: TextStyle(color: Colors.white)),
                IconButton(key: const Key('collections-decrease-dupes'), onPressed: _busy ? null : () async { await _saveOneDupe(slot, -1); if (ctx.mounted) refresh(() {}); }, icon: const Icon(Icons.remove_circle_outline, color: Colors.white)),
                Text('${_dupCount(slot)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Tooltip(
                  key: const Key('collections-quick-add-dupe'),
                  message: 'Add Dupe +1',
                  child: IconButton(
                    key: const Key('collections-increase-dupes'),
                    tooltip: 'Add one spare',
                    onPressed: _busy ? null : () async {
                      await _saveOneDupe(slot, 1);
                      if (ctx.mounted) refresh(() {});
                    },
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2CE1EB)),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))),
            ]),
          ),
        );
      }),
    );
  }

  Future<void> _saveAndContinue() async {
    if (_busy || !_loaded) return;
    final additions = _pendingOwned.difference(_saved.ownedSlots);
    if (_reviewStates.isEmpty && _pendingDupes.isEmpty) {
      setState(() {
        _reviewStates = const [];
        _screenshot = null;
        _message = 'Already up to date. Continue browsing your saved collection.';
      });
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Save ${_kind.title} collection?'),
        content: Text('Add ${additions.length} owned positions and save ${_pendingDupes.length} manually edited duplicate counts? '
          '$_reviewUnknownCount screenshot positions require review and will not be imported. '
          'Missing slots will NEVER remove previously saved ownership.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save & Continue')),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final state = widget.saver == null
          ? await _repository.save(kind: _kind, addOwned: <int>{..._pendingOwned, ..._saved.ownedSlots}, editedDuplicates: _pendingDupes)
          : await widget.saver!(_kind, <int>{..._pendingOwned, ..._saved.ownedSlots}, Map<int, int>.of(_pendingDupes));
      if (!mounted) return;
      setState(() {
        _saved = state;
        _reviewStates = const [];
        _screenshot = null;
        _pendingDupes = <int, int>{};
        _message = 'Saved and ready. Your ${_kind.title} collection is shown below.';
      });
    } catch (_) {
      if (mounted) setState(() => _message = 'Save failed. Changes are still available for retry. Check account permissions or connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (!_loaded) return;
    ArcCollectionShareItem itemAt(int slot) => ArcCollectionShareItem(
      label: _name(slot),
      assetPath: _artworkAtSlot(slot),
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
    if (!mounted) return;
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
    final relevant = _view == ArcCollectionView.all ||
        (_view == ArcCollectionView.needed && !owned) ||
        (_view == ArcCollectionView.duplicates && dupes > 0);
    final review = _reviewStates.length == _kind.slots && _reviewStates[slot-1] == ArcNativeSlotState.review;
    final name = _name(slot);
    final artwork = _artworkAtSlot(slot);
    final cardName = _kind == ArcNativeCollectionKind.designs &&
        !_assignedDesignNames.containsKey(slot)
        ? '#${slot.toString().padLeft(2, '0')}' : name;
    return Opacity(
      opacity: relevant ? 1 : .21,
      child: InkWell(
        key: Key('collections-saved-slot-$slot'),
        onTap: () => _details(slot),
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: owned ? const Color(0xFF163344) : const Color(0xFF12161E),
            border: Border.all(color: review ? Colors.amberAccent :
                dupes > 0 ? const Color(0xFFFF3C97) : const Color(0xFF325366)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(children: [
            Expanded(child: Stack(fit: StackFit.expand, children: [
              if (artwork != null)
                Image.asset(artwork, fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    owned ? Icons.palette_outlined : Icons.lock_outline,
                    color: owned ? Colors.cyanAccent : Colors.white30, size: 18))
              else Icon(owned ? Icons.weekend_outlined : Icons.lock_outline,
                  size: 18, color: owned ? Colors.cyanAccent : Colors.white30),
              Positioned(right: 0, top: 0, child: Icon(
                owned ? Icons.check_circle : Icons.remove_circle_outline,
                size: 12, color: owned ? const Color(0xFFFFD949) : Colors.white30)),
              if (dupes > 0) Positioned(bottom: 0, right: 0,
                child: Text('+$dupes', style: const TextStyle(fontSize: 10,
                    color: Color(0xFFFF61B6), fontWeight: FontWeight.bold))),
            ])),
            Tooltip(message: name,
              child: Text(cardName, overflow: TextOverflow.ellipsis, maxLines: 1,
              style: TextStyle(fontSize: cardWidth >= 95 ? 10 : cardWidth >= 55 ? 9 : 8,
                fontWeight: FontWeight.w600, color: Colors.white))),
          ]),
        ),
      ),
    );
  }

  Widget _toolsRail(bool hasPending) {
    Widget action({required Key key, required String title,
        required IconData icon, required VoidCallback? onTap,
        bool selected = false, bool camera = false}) =>
      SizedBox(width: double.infinity, height: 43, child: OutlinedButton.icon(
        key: key,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          foregroundColor: selected ? const Color(0xFF68F0F6) : Colors.white70,
          backgroundColor: camera ? const Color(0xFFE93895)
              : selected ? const Color(0xFF163E4D) : const Color(0xFF0D1D27),
          side: BorderSide(color: camera ? const Color(0xFF65E6F2) :
            selected ? const Color(0xFF45D7E7) : const Color(0xFF325362)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: camera ? Colors.white : null),
        label: title.isEmpty ? const SizedBox.shrink() :
          Text(title, maxLines: 1, overflow: TextOverflow.fade,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
      ));
    return Container(
      decoration: BoxDecoration(color: const Color(0xDD071824),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF28626E))),
      padding: const EdgeInsets.all(6),
      child: ListView(padding: EdgeInsets.zero, children: [
        action(key: const Key('collections-upload-native-screenshot'),
          title: '', icon: Icons.camera_alt_outlined,
          onTap: _busy ? null : _upload, camera: true),
        const SizedBox(height: 8),
        action(key: const Key('collections-filter-all'), title: 'ALL',
          icon: Icons.apps_rounded,
          onTap: () => setState(() => _view = ArcCollectionView.all),
          selected: _view == ArcCollectionView.all),
        const SizedBox(height: 7),
        action(key: const Key('collections-filter-needed'), title: 'NEEDED',
          icon: Icons.help_outline_rounded,
          onTap: () => setState(() => _view = ArcCollectionView.needed),
          selected: _view == ArcCollectionView.needed),
        const SizedBox(height: 7),
        // Dupe navigation is in the top bar. The rail remains compact.
        action(key: const Key('collections-share'), title: 'SHARE',
          icon: Icons.share_outlined,
          onTap: _loaded && !_busy ? _share : null),
        if (hasPending) ...[
          const SizedBox(height: 7),
          action(key: const Key('collections-save-continue'), title: 'SAVE',
            icon: Icons.save_outlined,
            onTap: _loaded && !_busy ? _saveAndContinue : null),
        ],
        const SizedBox(height: 8),
        Center(child: Text('${_saved.ownedSlots.length}/${_kind.slots}',
          style: const TextStyle(color: Color(0xFF62E5EB), fontSize: 10))),
      ]),
    );
  }

  /// A Design must be tied to the right in-game slot before spare copies
  /// are advertised. The reference list is alphabetic, not the 17-column order.
  Future<void> _assignDesignFromDupeSearch(String name) async {
    if (_kind != ArcNativeCollectionKind.designs || _busy) return;
    if (_assignedDesignNames.containsValue(name)) return;
    var typedSlot = '';
    final slot = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Choose in-game slot for $name'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Check the Design position in your game first. The 100 reference names are not sorted in game order.'),
          TextField(
            key: const Key('collections-design-slot-input'),
            onChanged: (value) => typedSlot = value,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Game slot number (1–100)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final n = int.tryParse(typedSlot);
            if (n != null && n >= 1 && n <= 100) Navigator.pop(ctx, n);
          }, child: const Text('Use this slot')),
        ],
      ),
    );
    if (slot == null || !mounted) return;
    final previousName = _assignedDesignNames[slot];
    if (previousName != null && previousName != name) {
      final change = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Correct saved Design name?'),
          content: Text('Slot $slot is currently labelled $previousName. Replace it with $name? Ownership and spare quantities are not changed.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Replace name')),
          ],
        ));
      if (change != true || !mounted) return;
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
      entries: [for (var slot = 1; slot <= _kind.slots; slot++)
        ArcCollectionDupeEntry(
          id: '$slot',
          name: _name(slot),
          owned: _displayOwned.contains(slot),
          spares: _dupCount(slot),
          imageAssetPath: _artworkAtSlot(slot),
          icon: Icons.weekend_outlined,
          detail: _kind == ArcNativeCollectionKind.designs ? 'Game slot $slot' : null,
        )],
      onAdjust: (id, delta) => _saveOneDupe(int.parse(id), delta),
      referenceNames: _kind == ArcNativeCollectionKind.designs
          ? ArcDesignReferenceCatalogue.names : const <String>[],
      onReferenceSelected: _kind == ArcNativeCollectionKind.designs
          ? _assignDesignFromDupeSearch : null,
    );
  }

  Widget _grid() {
    if (_kind == ArcNativeCollectionKind.designs) {
      return LayoutBuilder(builder: (context, constraints) {
        // Authoritative game order: 17 columns, six rows (final row partial).
        // Show about three rows at a time; the remaining slots scroll vertically.
        // Do not reorder, filter out or remap any saved slot identity.
        const columns = 17;
        const gap = 3.0;
        const inset = 5.0;
        final cardWidth = (constraints.maxWidth - (inset * 2) -
            gap * (columns - 1)) / columns;
        final rowHeight = (constraints.maxHeight / 3.08).clamp(92.0, 156.0).toDouble();
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
            final artwork = _artworkAtSlot(slot);
            final owned = _displayOwned.contains(slot);
            final copies = _dupCount(slot);
            final matchesFilter = _view == ArcCollectionView.all ||
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
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                    decoration: BoxDecoration(
                      color: owned ? const Color(0xFF163344) : const Color(0xFF12161E),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: copies > 0
                          ? const Color(0xFFFF3C97) : const Color(0xFF325366)),
                    ),
                    child: Column(children: [
                      Text(slot.toString().padLeft(2, '0'),
                        style: const TextStyle(fontSize: 9, color: Color(0xFF65E6F2))),
                      Expanded(child: Stack(alignment: Alignment.center, children: [
                        if (artwork == null)
                          Icon(owned ? Icons.weekend_outlined : Icons.lock_outline,
                            size: cardWidth < 42 ? 17 : 24,
                            color: owned ? Colors.cyanAccent : Colors.white38)
                        else Image.asset(
                          artwork,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(
                            owned ? Icons.weekend_outlined : Icons.lock_outline,
                            size: cardWidth < 42 ? 17 : 24,
                            color: owned ? Colors.cyanAccent : Colors.white38,
                          ),
                        ),
                        if (copies > 0) Positioned(right: 0, bottom: 0,
                          child: Text('+$copies', style: const TextStyle(
                            fontSize: 8, color: Color(0xFFFF8FC1)))),
                      ])),
                      SizedBox(height: rowHeight * 0.42,
                        child: Center(child: Text(name,
                          textAlign: TextAlign.center,
                          maxLines: 5,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white,
                            fontSize: cardWidth >= 58 ? 9 : cardWidth >= 40 ? 8 : 7,
                            height: 1.05)))),
                    ]),
                  ),
                ),
              ),
            );
          },
        );
      });
    }
    final columns = _kind.columns;
    final rows = (_kind.slots / columns).ceil();
    const gap = 3.0;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final byWidth = (width - gap * (columns - 1)) / columns;
      final byHeight = (height - gap * (rows - 1)) / (rows * 1.12);
      // Keep exact in-game column counts. On narrow devices pinch/pan is available.
      final cardWidth = math.max(18.0, math.min(108.0, math.min(byWidth, byHeight)));
      final cardHeight = cardWidth * 1.12;
      return ClipRect(child: InteractiveViewer(
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
            itemBuilder: (context, index) => _slotCard(index + 1, cardWidth),
          ),
        ),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _reviewStates.isNotEmpty || _pendingDupes.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFF071018),
      appBar: AppBar(
        titleSpacing: 0,
        toolbarHeight: 48,
        title: LayoutBuilder(builder: (context, constraints) {
          final width = MediaQuery.sizeOf(context).width;
          return Row(children: [
            Text('Collections Tracker', style: ArcUiTokens.pageTitle(
              fontSize: width < 430 ? 17 : 19,
              color: ArcUiTokens.primaryAccent)),
            const SizedBox(width: 18),
            Expanded(child: Align(alignment: Alignment.center,
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360),
                child: ArcCollectionsCategoryBar(
                  selected: _kind == ArcNativeCollectionKind.stencils
                      ? ArcCollectionsCategory.stencils : ArcCollectionsCategory.designs,
                  showDupes: true,
                  dupesSelected: _view == ArcCollectionView.duplicates,
                  onDupesSelected: () => setState(() => _view = ArcCollectionView.duplicates),
                  onSelected: (category) {
                    if (_busy) return;
                    if (category == ArcCollectionsCategory.blueprints) {
                      if (hasPending) {
                        _confirmDiscard(() => Navigator.pop(context));
                      } else { Navigator.pop(context); }
                      return;
                    }
                    final next = category == ArcCollectionsCategory.stencils
                      ? ArcNativeCollectionKind.stencils : ArcNativeCollectionKind.designs;
                    if (next == _kind && _view == ArcCollectionView.duplicates) {
                      setState(() => _view = ArcCollectionView.all);
                    } else { _switch(next); }
                  },
                ),
              ),
            )),
          ]);
        }),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF62E5EB),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [PopupMenuButton<String>(
          tooltip: 'Collections menu',
          icon: const Icon(Icons.menu_rounded, color: Color(0xFFFF4BA0)),
          onSelected: (action) {
            if (action == 'all') setState(() => _view = ArcCollectionView.all);
            if (action == 'needed') setState(() => _view = ArcCollectionView.needed);
            if (action == 'dupes') setState(() => _view = ArcCollectionView.duplicates);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'all', child: Text('All')),
            PopupMenuItem(value: 'needed', child: Text('Needed')),
            PopupMenuItem(value: 'dupes', child: Text('Dupes')),
          ],
        ), const SizedBox(width: 8)],
      ),
      bottomNavigationBar: widget.adBanner ?? const ArcBlueprintBannerSlot(),
      body: SafeArea(top: false, bottom: false, right: true, left: true,
        child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 2, 18, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_busy || !_loaded) const LinearProgressIndicator(),
          if (_message != null) Text(_message!,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFFFC77B), fontSize: 11)),
          if (_reviewStates.isNotEmpty)
            Row(children: [
              Expanded(child: Text('SCREENSHOT REVIEW: $_reviewOwnedCount owned · $_reviewUnknownCount uncertain. Tap any card to verify.',
                  style: const TextStyle(color: Colors.white70, fontSize: 11))),
              if (_screenshot != null) TextButton(
                onPressed: () => showDialog<void>(context: context,
                  builder: (ctx) => Dialog(child: InteractiveViewer(child:
                      Image.memory(_screenshot!, fit: BoxFit.contain)))),
                child: const Text('View original'),
              ),
            ]),
          const SizedBox(height: 4),
          // PASS05: full-height in-game order grid + slim trade-action rail.
          Expanded(child: Row(children: [
            Expanded(child: _view == ArcCollectionView.duplicates
                ? _buildCollectionDupeSearch() : _grid()),
            const SizedBox(width: 6),
            SizedBox(width: 113, child: _toolsRail(hasPending)),
          ])),
        ]),
      )),
    );
  }
}
