import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_blueprint_collection_overview_screen.dart';
import 'package:camera/camera.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_camera_dark_cell_guard.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_camera_lattice_registrar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_three_state_grid_classifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart' as uag_pass14_theme;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_single_grid_locator.dart';
import 'package:image/image.dart' as image_codec;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_perspective_cropper.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_edge_calibration.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_edge_crop_overlay.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_import_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_collection_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';

/// Frozen Trail: one full grid, 17 columns and six rows (last row: six cells).
/// Preserves the established ownership evidence threshold and applies
/// confident new detections together; uncertain results never remove ownership.
class ArcFrozenTrailSingleGridCaptureScreen extends StatefulWidget {
  const ArcFrozenTrailSingleGridCaptureScreen({super.key});

  @override
  State<ArcFrozenTrailSingleGridCaptureScreen> createState() =>
      _ArcFrozenTrailSingleGridCaptureScreenState();
}

class _ArcFrozenTrailSingleGridCaptureScreenState
    extends State<ArcFrozenTrailSingleGridCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _image;
  List<ArcBlueprintPhotoCellDecision> _candidates = const [];
  List<ArcBlueprintPhotoCellDecision> _recognised = const [];
  bool _scanReady = false;
  String? _scanBlockReason;
  bool _initialImportReview = false;
  int _detectedMissingCount = 0;
  int _detectedUncertainCount = 0;
  List<ArcBlueprintPhotoCellDecision> _gridAudit = const [];
  List<int> _unmappedOwnedSlots = const [];
  List<int> _darkReviewSlots = const [];
  bool _lastScanWasCamera = false;
  bool _showSamplingOverlay = false;
  bool _busy = false;
  String? _feedback;

  Future<void> _openOriginalCameraFrame() async {
    if (_busy) {
      return;
    }
    final grid32FlowTimer = Stopwatch()..start();
    debugPrint('ARC GRID32 FLOW cameraOpened');
    Uint8List? aligned;
    while (mounted) {
      final image = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute<Uint8List>(
          builder: (_) => const _FrozenTrailAlignedCamera(),
        ),
      );
      debugPrint('ARC GRID32 FLOW stillReturnedMs=${grid32FlowTimer.elapsedMilliseconds} hasImage=${image != null}');
      if (!mounted || image == null) return;

      // Grid35: crop only the actual saved still, on a large alignment screen.
      final candidate = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute<Uint8List>(
          builder: (_) => _FrozenTrailPostCaptureAlignScreen(imageBytes: image),
        ),
      );
      debugPrint('ARC GRID32 FLOW postAlignReturnedMs=${grid32FlowTimer.elapsedMilliseconds} hasGrid=${candidate != null}');
      if (!mounted) return;
      if (candidate != null) {
        aligned = candidate;
        break;
      }
      // Back from alignment means Retake: reopen the clean camera once.
      debugPrint('ARC GRID35 FLOW retakeRequested');
    }
    if (!mounted || aligned == null) return;
    final selectedGrid = aligned;
    setState(() {
      _image = selectedGrid;
      _candidates = const [];
      _recognised = const [];
      _scanReady = false;
      _scanBlockReason = null;
      _feedback = null;
      _busy = true;
    });
    try {
      await _analyse(aligned, alreadyRegistered: true);
      debugPrint('ARC GRID32 FLOW endToEndMs=${grid32FlowTimer.elapsedMilliseconds}');
    } on FormatException catch (error) {
      if (mounted) {
        setState(() => _feedback = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _feedback =
              'Could not align the captured Blueprint grid. Retake and fit the cyan guides to the outer grid edges.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _capture(ImageSource source) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 3200,
        requestFullMetadata: false,
      );
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) {
        return;
      }
      // Always show the complete original image for post-capture alignment.
      // Analysis uses only the user's explicitly chosen rectangle.
      if (mounted) {
        setState(() => _busy = false);
      }
      // Gallery images are processed directly; do not ask for a second trim.
      final aligned = bytes;
      setState(() {
        _busy = true;
        _image = aligned;
        _candidates = const [];
        _recognised = const [];
        _scanReady = false;
        _scanBlockReason = null;
        _initialImportReview = false;
      });
      await _analyse(aligned);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _feedback = error.message ?? error.code);
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(() => _feedback = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _feedback =
              'Unable to process this image. Use a clear, front-on screenshot.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _analyse(Uint8List bytes, {bool alreadyRegistered = false}) async {
    final grid31AnalysisTimer = Stopwatch()..start();
    // Grid29 contract: the camera image is already registered by the camera
    // alignment stage. NEVER run a second crop inside recognition.
    // Gallery / PS5 images continue through their locked grid locator.
    late final Uint8List registeredImage;
    if (alreadyRegistered) {
      registeredImage = bytes;
    } else {
      final located = const ArcBlueprintSingleGridLocator().locate(bytes);
      registeredImage = const ArcBlueprintSingleGridLocator()
          .normalizeLocatedGrid(located);
    }
    final states = await ArcBlueprintRepository().loadMyBlueprintStates();
    final entries = <int, ArcCollectionEntry>{
      for (final entry in ArcFrozenTrailCollectionCatalogue.blueprintEntries)
        if (entry.slot != null) entry.slot!: entry,
    };
    // Reuse the original occupancy classifier, but provide Frozen Trail's
    // current 17-column canonical slot identities instead of the old 10x9
    // seed ordering. Unmapped slots are never written.
    final orderedIds = List<String>.generate(
      91,
      (index) =>
          entries[index + 1]?.id ?? 'uag-unresolved-grid-slot-${index + 1}',
      growable: false,
    );
    // Empty-first recognition: clear black cells are missing; blue card faces
    // with visual evidence are owned; ambiguous cells stay uncertain. Canonical
    // slot order supplies identity, not individual artwork matching.
    if (kDebugMode && alreadyRegistered) {
      // Diagnostics only: measures colour bands in the EXACT 1700x600 image
      // passed to the classifier. No change to the image or decisions.
      final probeTimer = Stopwatch()..start();
      try {
        final bands = await compute(_grid32GeometryProbe, registeredImage);
        for (final band in bands) {
          debugPrint(band);
        }
      } catch (error) {
        debugPrint('ARC GRID32 PROFILE unavailable=$error');
      }
      debugPrint('ARC GRID32 TIMING geometryProbeMs=${probeTimer.elapsedMilliseconds}');
    }
    final simpleSamples = const ArcBlueprintThreeStateGridClassifier().analyze(
      registeredImage,
    );
    // Camera-only conservative check: neighbouring blue cards can bleed into a
    // mostly dark face after perspective / alignment. Review rather than claim
    // ownership; the gallery/PS5 classifier and its thresholds are untouched.
    final reviewedSamples = alreadyRegistered
        ? const ArcBlueprintCameraDarkCellGuard().review(
            registeredImage,
            simpleSamples,
          )
        : simpleSamples;
    final darkReviewSlots = <int>[
      for (var i = 0; i < simpleSamples.length; i++)
        if (simpleSamples[i].occupancyScore == 0.96 &&
            reviewedSamples[i].occupancyScore == 0.50)
          simpleSamples[i].rowIndex * 17 + simpleSamples[i].columnIndex + 1,
    ];
    final classification = const ArcBlueprintPhotoOccupancyEngine(
      columns: 17,
    ).classify(orderedBlueprintIds: orderedIds, samples: reviewedSamples);
    if (classification.errors.isNotEmpty) {
      throw FormatException(classification.errors.join(' '));
    }
    final owned = classification.decisions
        .where(
          (decision) =>
              decision.state == ArcBlueprintPhotoCellState.owned &&
              entries.containsKey(decision.blueprintIndex + 1),
        )
        .toList(growable: false);
    final additions = owned
        .where((decision) => states[decision.blueprintId]?.owned != true)
        .toList(growable: false);
    final missing = classification.decisions
        .where(
          (decision) => decision.state == ArcBlueprintPhotoCellState.missing,
        )
        .length;
    final uncertain = classification.decisions
        .where(
          (decision) => decision.state == ArcBlueprintPhotoCellState.uncertain,
        )
        .length;
    final rawOwned = classification.decisions
        .where((decision) => decision.state == ArcBlueprintPhotoCellState.owned)
        .length;
    final unmappedOwned = rawOwned - owned.length;
    final unmappedSlots = classification.decisions
        .where(
          (decision) =>
              decision.state == ArcBlueprintPhotoCellState.owned &&
              !entries.containsKey(decision.blueprintIndex + 1),
        )
        .map((decision) => decision.blueprintIndex + 1)
        .toList(growable: false);
    if (rawOwned + missing + uncertain != 91) {
      throw FormatException(
        'Incomplete grid: ${rawOwned + missing + uncertain} of 91 cells were classified.',
      );
    }
    debugPrint(
      'ARC GRID24 TOTAL rawOwned=$rawOwned mappedOwned=${owned.length} '
      'unmappedOwned=$unmappedOwned missing=$missing uncertain=$uncertain total=91',
    );
    debugPrint(
      'ARC EMPTY FIRST owned=${owned.length} missing=$missing uncertain=$uncertain',
    );
    // Do not import if the fixed slot grid is poorly aligned or many cells
    // cannot be classified. Do not lower the original persistence safety gate.
    final importGate =
        ArcBlueprintPhotoImportService.automaticUpdateBlockReason(
          decisions: additions,
          existing: states,
        );
    final initialReview =
        unmappedOwned == 0 &&
        states.values.every((value) => !value.owned) &&
        missing >= 1 &&
        uncertain <= 10 &&
        owned.length >= 25;
    final guard = alreadyRegistered && darkReviewSlots.isNotEmpty
        ? 'Camera alignment produced ${darkReviewSlots.length} dark-dominant false-positive risks. Retake/realign before importing.'
        : owned.isEmpty
        ? 'No owned Blueprint cards were confidently identified.'
        : unmappedOwned > 0
        ? 'Unmapped occupied grid slots: ${unmappedSlots.join(', ')}. Review catalogue mapping before importing.'
        : uncertain > 10
        ? '$uncertain of 91 cells are uncertain; retake the full grid.'
        : initialReview && importGate != null
        ? null // Explicitly reviewed initial import, never automatic.
        : importGate;
    debugPrint('ARC GRID31 TIMING analysisMs=${grid31AnalysisTimer.elapsedMilliseconds} camera=$alreadyRegistered');
    if (!mounted) return;
    setState(() {
      _image = registeredImage; // Exactly the bytes consumed by recognition.
      _scanReady = true;
      _recognised = owned;
      _gridAudit = classification.decisions;
      _unmappedOwnedSlots = unmappedSlots;
      _darkReviewSlots = darkReviewSlots;
      _lastScanWasCamera = alreadyRegistered;
      // Developer diagnostic overlay stays opt-in; not part of user results.
      _showSamplingOverlay = false;
      _candidates = additions;
      _scanBlockReason = guard;
      _initialImportReview = initialReview;
      _detectedMissingCount = missing;
      _detectedUncertainCount = uncertain;
      _feedback = guard == null
          ? 'Scan complete: ${owned.length} recognised; ${additions.length} new. Review and update the Blueprint Collection.'
          : 'Import paused: $guard. No ownership has been changed. Retake and align the complete grid.';
    });
  }

  Future<void> _save() async {
    if (_busy ||
        !_scanReady ||
        _scanBlockReason != null ||
        _recognised.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      // Recheck the safety gate at the moment of writing. Never turn a
      // scanner score into a manual confirmation or force confidence to 1.
      final states = await ArcBlueprintRepository().loadMyBlueprintStates();
      if (!mounted) return;
      final stillNew = _candidates
          .where((decision) => states[decision.blueprintId]?.owned != true)
          .toList(growable: false);
      final initialImport =
          _initialImportReview &&
          states.values.every((value) => !value.owned) &&
          _detectedMissingCount >= 1 &&
          _detectedUncertainCount <= 10 &&
          _recognised.isNotEmpty;
      final guard = ArcBlueprintPhotoImportService.automaticUpdateBlockReason(
        decisions: stillNew,
        existing: states,
        confirmedInitialImport: initialImport,
      );
      if (guard != null) throw FormatException(guard);
      if (initialImport && stillNew.isNotEmpty) {
        final approved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: uag_pass14_theme.AppTheme.cardBackgroundDeep,
            surfaceTintColor: Colors.transparent,
            title: const Text('Confirm first Blueprint import'),
            content: Text(
              'Add ${stillNew.length} owned Blueprints? '
              'The scan found $_detectedMissingCount missing and '
              '$_detectedUncertainCount uncertain cells. '
              'Check the detected positions before confirming. '
              'Existing duplicates will not be changed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Confirm import'),
              ),
            ],
          ),
        );
        if (approved != true || !mounted) return;
      }
      if (stillNew.isNotEmpty) {
        await ArcBlueprintPhotoImportService().apply(
          stillNew,
          confirmedInitialImport: initialImport,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FormatException catch (error) {
      if (mounted) setState(() => _feedback = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _feedback =
              'Could not update Blueprints. Existing ownership was not reset.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final portrait = size.height > size.width;
    return Scaffold(
      backgroundColor: const Color(0xFF07141E),
      bottomNavigationBar: kDebugMode ? const SafeArea(top: false,
        child: SizedBox(height: 50,
          child: ColoredBox(color: Color(0xFF161C29),
            child: Center(child: Text('ADVERTISEMENT · PREVIEW PLACEMENT (NOT LIVE)',
              style: TextStyle(color: Colors.white54, fontSize: 11)))))) : null,
      appBar: AppBar(
        title: const Text('COLLECTIONS GRID'),
        backgroundColor: const Color(0xFF0B2633),
        foregroundColor: const Color(0xFF72EBEF),
      ),
      body: portrait
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.screen_rotation,
                    size: 66,
                    color: Color(0xFF72EBEF),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'ROTATE TO LANDSCAPE',
                    style: TextStyle(color: Color(0xFF72EBEF), fontSize: 22),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The full 17-column Blueprint grid needs a wide screen.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    const Chip(
                      key: Key('collections-grid-tab-blueprints'),
                      label: Text('BLUEPRINTS'),
                      backgroundColor: Color(0xFF174B57),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    for (final collection in ArcNativeCollectionKind.values)
                      OutlinedButton(
                        key: Key('collections-grid-tab-${collection.key}'),
                        onPressed: _busy ? null : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ArcAdditionalCollectionsScreen(initialKind: collection),
                          ),
                        ),
                        child: Text(collection.title.toUpperCase()),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('collections-view-blueprint-inventory'),
                  onPressed: _busy ? null : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) =>
                      const ArcBlueprintCollectionOverviewScreen()),
                  ),
                  icon: const Icon(Icons.grid_view),
                  label: const Text('View Blueprints · All / Needed / Duplicates'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'BLUEPRINTS · 91 SLOTS · 17 COLUMNS',
                  style: TextStyle(
                    color: Color(0xFF72EBEF),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fit all six rows in the frame, including the six final cells. '
                  'Use a clear screenshot where possible. Confident new ownership '
                  'can be reviewed and applied to your collection; existing ownership is preserved.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (const bool.fromEnvironment('UAG_ENABLE_LEGACY_COLLECTION_CAMERA') &&
                        (kIsWeb || defaultTargetPlatform == TargetPlatform.android ||
                         defaultTargetPlatform == TargetPlatform.iOS))
                      FilledButton.icon(
                        key: const Key('frozen-trail-single-capture-camera'),
                        onPressed: _busy ? null : _openOriginalCameraFrame,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Open Blueprint Grid Camera'),
                      ),
                    OutlinedButton.icon(
                      key: const Key('frozen-trail-single-capture-screenshot'),
                      onPressed: _busy
                          ? null
                          : () => _capture(ImageSource.gallery),
                      icon: const Icon(Icons.image),
                      label: const Text('Choose Full Grid Screenshot'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: AspectRatio(
                      aspectRatio: 17 / 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          border: Border.all(
                            color: const Color(0xFF72EBEF),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _image == null
                            ? const Center(
                                child: Text(
                                  'FULL BLUEPRINT GRID',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(_image!, fit: BoxFit.contain),
                                    if (_lastScanWasCamera &&
                                        _showSamplingOverlay &&
                                        _scanReady)
                                      IgnorePointer(
                                        child: CustomPaint(
                                          painter: _Grid31CameraSamplesPainter(
                                            cells: _gridAudit,
                                            reviewedSlots: _darkReviewSlots,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (_feedback != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _feedback!,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                if (_scanReady) ...[
                   const Divider(),
                   if (_lastScanWasCamera) ...[
                     TextButton.icon(
                       key: const Key('grid31-toggle-sampling-overlay'),
                       onPressed: () => setState(
                         () => _showSamplingOverlay = !_showSamplingOverlay,
                       ),
                       icon: Icon(_showSamplingOverlay
                           ? Icons.grid_off : Icons.grid_on),
                       label: Text(_showSamplingOverlay
                           ? 'Hide camera sampling areas'
                           : 'Show camera sampling areas'),
                     ),
                     if (_darkReviewSlots.isNotEmpty)
                       Text(
                         'CAMERA SAFETY: dark-dominant cells require review: '
                         '${_darkReviewSlots.join(', ')}. Do not import this scan.',
                         style: const TextStyle(color: Colors.orangeAccent),
                       ),
                   ],
                  Text(
                    'SCAN RESULTS · ${_recognised.length} MAPPED OWNED · ${_candidates.length} NEW',
                    style: const TextStyle(color: Color(0xFF72EBEF)),
                  ),
                  Text(
                    '91-CELL AUDIT · ${_gridAudit.where((cell) => cell.state == ArcBlueprintPhotoCellState.owned).length} OCCUPIED · '
                    '$_detectedMissingCount EMPTY · $_detectedUncertainCount REVIEW',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (_unmappedOwnedSlots.isNotEmpty)
                    Text(
                      'UNMAPPED OCCUPIED SLOTS: ${_unmappedOwnedSlots.join(', ')}',
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  const SizedBox(height: 6),
                  ExpansionTile(
                    title: const Text(
                      'Review all 91 grid positions',
                      style: TextStyle(color: Color(0xFF72EBEF)),
                    ),
                    children: [
                      for (final cell in _gridAudit)
                        ListTile(
                          dense: true,
                          title: Text(
                            'Row ${cell.rowIndex + 1}, card ${cell.columnIndex + 1} '
                            '(slot ${cell.blueprintIndex + 1})',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            cell.state == ArcBlueprintPhotoCellState.owned
                                ? 'Detected occupied · ${ArcFrozenTrailCollectionCatalogue.entryAtSlot(ArcCollectionType.blueprints, cell.blueprintIndex + 1)?.name ?? "UNMAPPED"}'
                                : cell.state ==
                                      ArcBlueprintPhotoCellState.missing
                                ? 'Detected empty'
                                : 'Needs review',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                  const Text(
                    'Existing owned Blueprints, duplicate counts, and unidentified slots are preserved. No missing Blueprint will be removed.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  for (final candidate in _recognised)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF72EBEF),
                      ),
                      title: Text(
                        ArcFrozenTrailCollectionCatalogue.entryAtSlot(
                              ArcCollectionType.blueprints,
                              candidate.blueprintIndex + 1,
                            )?.name ??
                            candidate.blueprintId,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Row ${candidate.rowIndex + 1} · '
                        'Card ${candidate.columnIndex + 1} · '
                        'Confidence ${(candidate.confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ),
                  if (_scanBlockReason != null)
                    const Text(
                      'Import blocked. Retake the photo with all six rows visible.',
                      style: TextStyle(color: Colors.orangeAccent),
                    ),
                  FilledButton.icon(
                    key: const Key('frozen-trail-apply-scan-results'),
                    onPressed:
                        !_busy &&
                            _scanBlockReason == null &&
                            _recognised.isNotEmpty
                        ? _save
                        : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      'Update Blueprint Collection (${_candidates.length} new)',
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Grid35 camera step: full live preview with one shutter, no crop guide.
/// The actual photo is aligned on the next (expanded) screen.
class _FrozenTrailAlignedCamera extends StatefulWidget {
  const _FrozenTrailAlignedCamera();

  @override
  State<_FrozenTrailAlignedCamera> createState() =>
      _FrozenTrailAlignedCameraState();
}

class _FrozenTrailAlignedCameraState extends State<_FrozenTrailAlignedCamera>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() => _error = null);
    }
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'No camera is available.');
      }
      final chosen = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        chosen,
        ResolutionPreset.max,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (error) {
      if (controller != null) {
        await controller.dispose();
      }
      if (mounted) {
        setState(() => _error = error.description ?? error.code);
      }
    } catch (_) {
      if (controller != null) {
        await controller.dispose();
      }
      if (mounted) {
        setState(
          () => _error =
              'Camera unavailable. Use Choose Full Grid Screenshot instead.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final previous = _controller;
      _controller = null;
      if (previous != null) {
        previous.dispose();
      }
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (_busy || controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() => _busy = true);
    final cameraTimer = Stopwatch()..start();
    debugPrint(
      'ARC GRID32 CAPTURE press preview=${controller.value.previewSize} '
      'guide=none; one alignment step follows capture',
    );
    try {
      final photo = await controller.takePicture();
      final stillMs = cameraTimer.elapsedMilliseconds;
      debugPrint('ARC GRID32 CAPTURE stillReadyMs=$stillMs');
      final original = await photo.readAsBytes();
      final readMs = cameraTimer.elapsedMilliseconds - stillMs;
      // Grid35: photograph once, then align the actual saved still on the
      // full-screen post-capture alignment page.  Never crop the live preview.
      final oriented = await compute(_orientCapturedGridPhoto, original);
      debugPrint(
        'ARC GRID31 TIMING shutterToStillMs=$stillMs '
        'readMs=$readMs prepareMs=${cameraTimer.elapsedMilliseconds - stillMs - readMs} '
        'totalMs=${cameraTimer.elapsedMilliseconds}',
      );
      if (mounted) {
        Navigator.of(context).pop(oriented);
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } on CameraException catch (error) {
      if (mounted) {
        setState(() => _error = error.description ?? error.code);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Capture failed. Please try taking the photo again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final portrait = size.height > size.width;
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: portrait
            ? const Center(
                child: Text(
                  'ROTATE TO LANDSCAPE',
                  style: TextStyle(color: Color(0xFF72EBEF), fontSize: 24),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final rawAspect =
                      controller != null && controller.value.isInitialized
                          ? controller.value.aspectRatio
                          : constraints.maxWidth / constraints.maxHeight;
                  final cameraAspect = rawAspect >= 1
                      ? rawAspect
                      : 1 / rawAspect;
                  final frameWidth = constraints.maxWidth <
                          constraints.maxHeight * cameraAspect
                      ? constraints.maxWidth
                      : constraints.maxHeight * cameraAspect;
                  final frameHeight = frameWidth / cameraAspect;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (controller != null && controller.value.isInitialized)
                        Center(
                          child: SizedBox(
                            key: const Key('grid35-clean-camera-preview'),
                            width: frameWidth,
                            height: frameHeight,
                            child: CameraPreview(controller),
                          ),
                        )
                      else
                        Center(
                          child: _error == null
                              ? const CircularProgressIndicator()
                              : Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                        ),
                      Positioned(
                        top: 8,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: _busy
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TAKE BLUEPRINT PHOTO',
                                    style: TextStyle(
                                      color: Color(0xFF72EBEF),
                                      fontSize: 19,
                                    ),
                                  ),
                                  Text(
                                    'Keep the full collection visible. Crop and align on the next screen.',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filled(
                              key: const Key('grid08-single-grid-shutter'),
                              tooltip: 'Take Blueprint Photo',
                              onPressed: _busy ||
                                      controller == null ||
                                      !controller.value.isInitialized
                                  ? null
                                  : _takePhoto,
                              icon: const Icon(Icons.camera_alt),
                            ),
                          ],
                        ),
                      ),
                      if (_busy)
                        const Positioned(
                          bottom: 12,
                          left: 16,
                          right: 16,
                          child: LinearProgressIndicator(),
                        ),
                      if (_error != null && controller != null)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// Grid35: the user aligns the uncropped saved still exactly once.
/// The photo and cyan guides stay in the same image-coordinate system during
/// display-only zoom/pan; the cropper receives the original base viewport.
class _FrozenTrailPostCaptureAlignScreen extends StatefulWidget {
  const _FrozenTrailPostCaptureAlignScreen({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<_FrozenTrailPostCaptureAlignScreen> createState() =>
      _FrozenTrailPostCaptureAlignScreenState();
}

class _FrozenTrailPostCaptureAlignScreenState
    extends State<_FrozenTrailPostCaptureAlignScreen> {
  static const _defaultCalibration = ArcBlueprintEdgeCalibration(
    left: 0.02,
    top: 0.02,
    right: 0.98,
    bottom: 0.98,
  );

  ArcBlueprintEdgeCalibration _calibration = _defaultCalibration;
  bool _working = false;
  String? _error;
  final TransformationController _photoTransform = TransformationController();
  double _photoZoom = 1;
  late final Uint8List _orientedBytes;
  late final double _aspectRatio;
  int _sourceWidth = 0;
  int _sourceHeight = 0;

  @override
  void initState() {
    super.initState();
    final decoded = image_codec.decodeImage(widget.imageBytes);
    if (decoded == null) {
      _orientedBytes = widget.imageBytes;
      _aspectRatio = 17 / 6;
      _error = 'This image cannot be decoded. Please choose another image.';
    } else {
      final oriented = image_codec.bakeOrientation(decoded);
      _orientedBytes = Uint8List.fromList(
        image_codec.encodeJpg(oriented, quality: 97),
      );
      _aspectRatio = oriented.width / oriented.height;
      _sourceWidth = oriented.width;
      _sourceHeight = oriented.height;
      debugPrint('ARC GRID32 STILL oriented=${oriented.width}x${oriented.height} aspect=$_aspectRatio');
    }
  }

  @override
  void dispose() {
    _photoTransform.dispose();
    super.dispose();
  }

  // Zoom/pan modifies only the display transform. The image and crop edges
  // share one image-coordinate space, so the final crop is never zoomed twice.
  void _setPhotoZoom(double zoom, Size imageViewport) {
    final next = zoom.clamp(1.0, 3.0).toDouble();
    setState(() {
      _photoZoom = next;
      _photoTransform.value = Matrix4.identity()
        ..setEntry(0, 0, next)
        ..setEntry(1, 1, next)
        ..setTranslationRaw(
          (imageViewport.width * (1 - next)) / 2,
          (imageViewport.height * (1 - next)) / 2,
          0,
        );
    });
  }

  Future<void> _applyCrop(Size sourceViewport) async {
    if (_working || _error != null) {
      return;
    }
    setState(() => _working = true);
    final alignTimer = Stopwatch()..start();
    final rect = _calibration.normalizedRect;
    debugPrint(
      'ARC GRID32 ALIGN viewport=$sourceViewport sourceAspect=$_aspectRatio '
      'normLTRB=${rect.left.toStringAsFixed(4)},${rect.top.toStringAsFixed(4)},'
      '${rect.right.toStringAsFixed(4)},${rect.bottom.toStringAsFixed(4)} '
      'sourceLTRB=${(rect.left * _sourceWidth).toStringAsFixed(1)},'
      '${(rect.top * _sourceHeight).toStringAsFixed(1)},'
      '${(rect.right * _sourceWidth).toStringAsFixed(1)},'
      '${(rect.bottom * _sourceHeight).toStringAsFixed(1)}',
    );
    try {
      final bytes = await compute(
        _rectifyFullGridImage,
        _FrozenTrailCropRequest(
          bytes: _orientedBytes,
          width: sourceViewport.width,
          height: sourceViewport.height,
          calibration: _calibration,
        ),
      );
      debugPrint('ARC GRID31 TIMING alignCropMs=${alignTimer.elapsedMilliseconds}');
      debugPrint('ARC GRID32 ALIGN finalBytes=${bytes.length} grid=1700x600');
      if (mounted) {
        Navigator.of(context).pop(bytes);
      }
    } on FormatException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Unable to crop this image. Check the cyan rectangle and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07141E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            if (!landscape) {
              return const Center(
                child: Text(
                  'ROTATE TO LANDSCAPE TO ALIGN THE GRID',
                  style: TextStyle(color: Color(0xFF72EBEF), fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              );
            }

            // Grid35: put the controls in the landscape side gutters instead
            // of shrinking the photo with an AppBar + instructions + footer.
            // On a Sony landscape display, this uses almost all available
            // image height, matching the size of the camera preview.
            final sideWidth = (constraints.maxWidth * 0.17).clamp(108.0, 154.0).toDouble();
            final imageMaxWidth = constraints.maxWidth - 2 * sideWidth - 12;
            final imageHeight = (constraints.maxHeight - 36)
                .clamp(1.0, imageMaxWidth / _aspectRatio).toDouble();
            final imageSize = Size(imageHeight * _aspectRatio, imageHeight);

            return Row(
              children: [
                SizedBox(
                  width: sideWidth,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 5, 4, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          key: const Key('grid35-back-to-camera'),
                          tooltip: 'Retake photo',
                          onPressed: _working
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, color: Colors.pinkAccent),
                        ),
                        const Text(
                          'ALIGN GRID',
                          style: TextStyle(
                            color: Color(0xFF10DDE8),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Drag the cyan edges to include all 17 columns and six rows.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pinch or use +/- to zoom. Drag inside the photo to pan.',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      key: const Key('grid35-expanded-alignment-photo'),
                      width: imageSize.width,
                      height: imageSize.height,
                      child: ClipRect(
                        child: InteractiveViewer(
                          key: const Key('grid35-photo-zoom-pan'),
                          transformationController: _photoTransform,
                          constrained: false,
                          minScale: 1,
                          maxScale: 3,
                          panEnabled: !_working,
                          scaleEnabled: !_working,
                          boundaryMargin: const EdgeInsets.all(16),
                          onInteractionEnd: (_) {
                            if (mounted) {
                              setState(() => _photoZoom =
                                  _photoTransform.value.getMaxScaleOnAxis());
                            }
                          },
                          child: SizedBox(
                            width: imageSize.width,
                            height: imageSize.height,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(
                                  _orientedBytes,
                                  key: const Key('grid09-full-image-preview'),
                                  fit: BoxFit.fill, // Exact source aspect ratio.
                                ),
                                ArcBlueprintEdgeCropOverlay(
                                  key: const Key('grid09-post-capture-alignment'),
                                  calibration: _calibration,
                                  enabled: !_working,
                                  onChanged: (next) => setState(() {
                                    _calibration = next;
                                    _error = null;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: sideWidth,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 5, 8, 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton.filledTonal(
                              key: const Key('grid35-zoom-out'),
                              tooltip: 'Zoom out',
                              onPressed: _working || _photoZoom <= 1
                                  ? null
                                  : () => _setPhotoZoom(
                                      _photoZoom - .5, imageSize),
                              icon: const Icon(Icons.remove),
                            ),
                            IconButton.filledTonal(
                              key: const Key('grid35-zoom-in'),
                              tooltip: 'Zoom in',
                              onPressed: _working || _photoZoom >= 3
                                  ? null
                                  : () => _setPhotoZoom(
                                      _photoZoom + .5, imageSize),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        Text(
                          '${(_photoZoom * 100).round()}%',
                          key: const Key('grid35-zoom-label'),
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        TextButton(
                          key: const Key('grid35-fit-photo'),
                          onPressed: _working
                              ? null
                              : () => _setPhotoZoom(1, imageSize),
                          child: const Text('Fit photo'),
                        ),
                        TextButton(
                          key: const Key('grid35-reset-crop'),
                          onPressed: _working
                              ? null
                              : () => setState(() {
                                  _calibration = _defaultCalibration;
                                  _error = null;
                                }),
                          child: const Text('Reset crop'),
                        ),
                        if (_error != null)
                          Flexible(
                            child: SingleChildScrollView(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 7),
                        FilledButton(
                          key: const Key('grid09-confirm-crop'),
                          onPressed: _working
                              ? null
                              : () => _applyCrop(imageSize),
                          child: Text(_working ? 'Aligning…' : 'Scan Grid'),
                        ),
                        if (_working) const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

@visibleForTesting
Widget arcGrid35CameraForTest() => const _FrozenTrailAlignedCamera();

// Exposes the real alignment screen for layout/interaction regression tests.
@visibleForTesting
Widget arcGrid35AlignmentForTest(Uint8List bytes) =>
    _FrozenTrailPostCaptureAlignScreen(imageBytes: bytes);

/// Visualises the exact sample rectangles used by the fixed grid classifier.
/// No hit tests and no effect on recognition or persistence.
class _Grid31CameraSamplesPainter extends CustomPainter {
  const _Grid31CameraSamplesPainter({
    required this.cells,
    required this.reviewedSlots,
  });

  final List<ArcBlueprintPhotoCellDecision> cells;
  final List<int> reviewedSlots;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / 17;
    final cellHeight = size.height / 6;
    for (final cell in cells) {
      final slot = cell.blueprintIndex + 1;
      final selected = reviewedSlots.contains(slot);
      final color = selected || cell.state == ArcBlueprintPhotoCellState.uncertain
          ? Colors.orangeAccent
          : cell.state == ArcBlueprintPhotoCellState.missing
              ? Colors.white70
              : Colors.lightGreenAccent;
      final left = cell.columnIndex * cellWidth;
      final top = cell.rowIndex * cellHeight;
      final area = Rect.fromLTRB(
        left + cellWidth * .12,
        top + cellHeight * .14,
        left + cellWidth * .88,
        top + cellHeight * .76,
      );
      canvas.drawRect(
        area,
        Paint()
          ..color = color.withValues(alpha: selected ? 1 : .68)
          ..strokeWidth = selected ? 2.2 : 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Grid31CameraSamplesPainter oldDelegate) =>
      oldDelegate.cells != cells || oldDelegate.reviewedSlots != reviewedSlots;
}

@visibleForTesting
Uint8List arcGrid33AutoFitForTest(Uint8List bytes) =>
    _grid33AutoFitBlueprintGrid(bytes);

class _FrozenTrailCropRequest {
  const _FrozenTrailCropRequest({
    required this.bytes,
    required this.width,
    required this.height,
    required this.calibration,
  });
  final Uint8List bytes;
  final double width;
  final double height;
  final ArcBlueprintEdgeCalibration calibration;
}

Uint8List _rectifyFullGridImage(_FrozenTrailCropRequest request) {
  // Camera-only alignment: apply the existing user's cyan crop first,
  // then fit dark outer margins before passing the ALREADY registered image
  // into recognition. This never runs on the PS5/gallery image path.
  final aligned = const ArcBlueprintPerspectiveCropper(
    outputWidth: 1700,
    cellHeight: 100,
  ).rectify(
    imageBytes: request.bytes,
    viewportSize: Size(request.width, request.height),
    calibration: request.calibration,
    outputRows: 6,
  );
  // Grid34: fit repeated card/gap geometry BEFORE returning image bytes.
  // Grid29's 'registeredImage = bytes;' recognition contract is unchanged.
  // Do not use this registration on gallery or console screenshots.
  return const ArcBlueprintCameraLatticeRegistrar().register(aligned).bytes;
}

// Grid35 capture preparation: orient the complete saved camera photo only.
// No preview overlay or premature crop is used. Gallery screenshots retain
// their independent and protected recognition path.
Uint8List _orientCapturedGridPhoto(Uint8List bytes) {
  final decoded = image_codec.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Cannot decode camera photo.');
  }
  return Uint8List.fromList(
    image_codec.encodeJpg(image_codec.bakeOrientation(decoded), quality: 97),
  );
}

Uint8List _grid33AutoFitBlueprintGrid(Uint8List bytes) {
  final decoded = image_codec.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Cannot decode aligned camera grid.');
  }
  final oriented = image_codec.bakeOrientation(decoded);
  final working = oriented.width == 1700 && oriented.height == 600
      ? oriented
      : image_codec.copyResize(oriented, width: 1700, height: 600);

  bool blueAt(int x, int y) {
    final pixel = working.getPixel(x, y);
    final r = pixel.r.toDouble();
    final g = pixel.g.toDouble();
    final b = pixel.b.toDouble();
    return b > 42 && b > r * 1.14 && b > g * 1.02 && (b - r) > 10;
  }

  List<double> columnBlueRatios() {
    final values = <double>[];
    for (var x = 0; x < working.width; x++) {
      var blue = 0;
      var total = 0;
      for (var y = 0; y < working.height; y += 4) {
        if (blueAt(x, y)) blue++;
        total++;
      }
      values.add(blue / total);
    }
    return values;
  }

  List<double> rowBlueRatios() {
    final values = <double>[];
    for (var y = 0; y < working.height; y++) {
      var blue = 0;
      var total = 0;
      for (var x = 0; x < working.width; x += 4) {
        if (blueAt(x, y)) blue++;
        total++;
      }
      values.add(blue / total);
    }
    return values;
  }

  double smoothedValue(List<double> values, int center, int radius) {
    var sum = 0.0;
    var count = 0;
    final start = center - radius < 0 ? 0 : center - radius;
    final end = center + radius >= values.length ? values.length - 1 : center + radius;
    for (var i = start; i <= end; i++) {
      sum += values[i];
      count++;
    }
    return count == 0 ? 0 : sum / count;
  }

  int firstAbove(List<double> values, double threshold, int radius) {
    for (var i = 0; i < values.length; i++) {
      if (smoothedValue(values, i, radius) >= threshold) return i;
    }
    return 0;
  }

  int lastAbove(List<double> values, double threshold, int radius) {
    for (var i = values.length - 1; i >= 0; i--) {
      if (smoothedValue(values, i, radius) >= threshold) return i;
    }
    return values.length - 1;
  }

  final columnRatios = columnBlueRatios();
  final rowRatios = rowBlueRatios();
  var left = firstAbove(columnRatios, 0.05, 6);
  var right = lastAbove(columnRatios, 0.05, 6);
  var top = firstAbove(rowRatios, 0.05, 4);
  var bottom = lastAbove(rowRatios, 0.05, 4);

  if (right - left < working.width * 0.55 || bottom - top < working.height * 0.55) {
    return Uint8List.fromList(image_codec.encodeJpg(working, quality: 97));
  }

  const targetAspect = 17 / 6;
  final padX = ((right - left + 1) * 0.01).round() + 6;
  final padY = ((bottom - top + 1) * 0.01).round() + 4;
  left -= padX;
  right += padX;
  top -= padY;
  bottom += padY;
  if (left < 0) left = 0;
  if (top < 0) top = 0;
  if (right >= working.width) right = working.width - 1;
  if (bottom >= working.height) bottom = working.height - 1;

  var cropWidth = right - left + 1;
  var cropHeight = bottom - top + 1;
  final currentAspect = cropWidth / cropHeight;
  if (currentAspect > targetAspect) {
    final wantedHeight = (cropWidth / targetAspect).round();
    final extra = wantedHeight - cropHeight;
    top -= extra ~/ 2;
    bottom += extra - extra ~/ 2;
  } else if (currentAspect < targetAspect) {
    final wantedWidth = (cropHeight * targetAspect).round();
    final extra = wantedWidth - cropWidth;
    left -= extra ~/ 2;
    right += extra - extra ~/ 2;
  }
  if (left < 0) {
    right += -left;
    left = 0;
  }
  if (top < 0) {
    bottom += -top;
    top = 0;
  }
  if (right >= working.width) {
    final overflow = right - working.width + 1;
    left -= overflow;
    right = working.width - 1;
  }
  if (bottom >= working.height) {
    final overflow = bottom - working.height + 1;
    top -= overflow;
    bottom = working.height - 1;
  }
  if (left < 0) left = 0;
  if (top < 0) top = 0;
  cropWidth = right - left + 1;
  cropHeight = bottom - top + 1;
  if (cropWidth <= 0 || cropHeight <= 0) {
    return Uint8List.fromList(image_codec.encodeJpg(working, quality: 97));
  }

  final cropped = image_codec.copyCrop(
    working,
    x: left,
    y: top,
    width: cropWidth,
    height: cropHeight,
  );
  final resized = image_codec.copyResize(cropped, width: 1700, height: 600);
  return Uint8List.fromList(image_codec.encodeJpg(resized, quality: 97));
}

// Grid32 read-only geometry probe: reports blue signal in 10-pixel bands of
// the EXACT image consumed by the fixed 17x6 classifier. It does not crop,
// shift, infer ownership or change any decisions. Camera route only.
List<String> _grid32GeometryProbe(Uint8List bytes) {
  final image = image_codec.decodeImage(bytes);
  if (image == null) return <String>['ARC GRID32 PROFILE decodeFailed'];
  final lines = <String>[
    'ARC GRID32 PROFILE finalSize=${image.width}x${image.height}',
  ];
  if (image.width != 1700 || image.height != 600) return lines;
  bool blueAt(int x, int y) {
    final p = image.getPixel(x, y);
    final r = p.r.toDouble();
    final g = p.g.toDouble();
    final b = p.b.toDouble();
    return b > 48 && b > r * 1.28 && b > g * 1.06 && b - r > 17;
  }
  for (var row = 0; row < 6; row++) {
    final bands = <String>[];
    for (var offset = 0; offset < 100; offset += 10) {
      var blue = 0;
      var total = 0;
      final columns = row == 5 ? 6 : 17;
      for (var col = 0; col < columns; col++) {
        for (var x = col * 100 + 20; x <= col * 100 + 80; x += 15) {
          final y = row * 100 + offset + 5;
          if (blueAt(x, y)) blue++;
          total++;
        }
      }
      bands.add((blue * 100 / total).toStringAsFixed(0));
    }
    lines.add('ARC GRID32 PROFILE row=${row + 1} blueBy10px=${bands.join(",")}');
  }
  for (final col in <int>[0, 8, 16]) {
    final bands = <String>[];
    for (var offset = 0; offset < 100; offset += 10) {
      var blue = 0;
      var total = 0;
      for (var row = 0; row < 5; row++) {
        for (var y = row * 100 + 20; y <= row * 100 + 70; y += 10) {
          if (blueAt(col * 100 + offset + 5, y)) blue++;
          total++;
        }
      }
      bands.add((blue * 100 / total).toStringAsFixed(0));
    }
    lines.add('ARC GRID32 PROFILE col=${col + 1} blueBy10px=${bands.join(",")}');
  }
  return lines;
}
