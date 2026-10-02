import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_section_grid_extractor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_dual_capture_merge_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_import_quality_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_import_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_bottom_overlap_normalizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_lattice_registrar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_owned_cell_structure_verifier.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_pixel_analyzer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_personal_calibration_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_template_verification_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_ownership_marker_verification_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_uploaded_image_processor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_capture_draft.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_photo_capture_session_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_delta_review_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class ArcBlueprintPhotoCaptureScreen extends StatefulWidget {
  const ArcBlueprintPhotoCaptureScreen({super.key});

  @override
  State<ArcBlueprintPhotoCaptureScreen> createState() =>
      _ArcBlueprintPhotoCaptureScreenState();
}

class _ArcBlueprintPhotoCaptureScreenState
    extends State<ArcBlueprintPhotoCaptureScreen> {
  final _picker = ImagePicker();
  final _repository = ArcBlueprintPhotoCaptureSessionRepository.instance;

  final _uploadedImageProcessor = const ArcBlueprintUploadedImageProcessor();

  ArcBlueprintPhotoCaptureDraft _draft = const ArcBlueprintPhotoCaptureDraft();
  ArcBlueprintCaptureSection _activeSection = ArcBlueprintCaptureSection.top;
  bool _busy = false;

  bool get _cameraSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    _restore();
    unawaited(_recoverLostPickerData());
  }

  Future<void> _restore() async {
    final restored = await _repository.restore();
    if (!mounted) return;
    setState(() {
      _draft = restored;
      if (restored.hasTop && !restored.hasBottom) {
        _activeSection = ArcBlueprintCaptureSection.bottom;
      }
    });
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade800 : null,
        ),
      );
  }

  String _pickerErrorMessage(Object error, ImageSource source) {
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      if (code.contains('camera_access_denied') ||
          code.contains('photo_access_denied') ||
          code.contains('permission')) {
        return source == ImageSource.camera
            ? 'Camera access was denied. Enable camera permission in your device or browser settings, then try again.'
            : 'Photo access was denied. Enable photo/file permission in your device or browser settings, then try again.';
      }
      if (code.contains('camera_unavailable') ||
          code.contains('no_available_camera')) {
        return 'No usable camera is available on this device. Choose a screenshot instead.';
      }
      return error.message?.trim().isNotEmpty == true
          ? error.message!.trim()
          : 'The image picker could not open (${error.code}).';
    }
    return 'The image picker could not open. Choose a screenshot or check this device/browser permission settings.';
  }

  Future<void> _storePickedImage(XFile image) async {
    final capturedSection = _activeSection;
    final originalBytes = await image.readAsBytes();
    final processed = _uploadedImageProcessor.process(
      originalBytes,
      section: capturedSection == ArcBlueprintCaptureSection.top
          ? ArcBlueprintGridSection.top
          : ArcBlueprintGridSection.bottom,
    );

    await _repository.saveSection(
      section: capturedSection,
      bytes: processed.imageBytes,
      fileName: image.name,
    );
    if (!mounted) return;

    setState(() {
      _draft = _repository.current;
      if (capturedSection == ArcBlueprintCaptureSection.top) {
        _activeSection = ArcBlueprintCaptureSection.bottom;
      }
    });

    _showMessage(
      capturedSection == ArcBlueprintCaptureSection.top
          ? '${processed.message} Top grid accepted. Now choose the bottom grid image.'
          : '${processed.message} Bottom grid accepted. Both images are ready to scan.',
    );
  }

  Future<void> _recoverLostPickerData() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty ||
          response.files == null ||
          response.files!.isEmpty) {
        return;
      }
      await _storePickedImage(response.files!.first);
    } catch (_) {
      _showMessage(
        'An interrupted camera selection could not be recovered. Please choose the image again.',
        error: true,
      );
    }
  }

  Future<void> _openLiveScanner() async {
    if (_busy) return;
    if (!_cameraSupported) {
      _showMessage(
        'Live camera scanning is not available on this device. Choose a screenshot instead.',
        error: true,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await Navigator.of(context)
          .push<ArcBlueprintScannerResult>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const ArcBlueprintLiveScannerScreen(),
            ),
          );

      if (result == null) {
        _showMessage('No Blueprint grid was captured.');
        return;
      }

      await _repository.saveDualCapture(
        topBytes: Uint8List.fromList(result.topImageBytes),
        bottomBytes: Uint8List.fromList(result.bottomImageBytes),
        topFileName: 'blueprint_grid_top.jpg',
        bottomFileName: 'blueprint_grid_bottom.jpg',
      );

      if (!mounted) return;
      setState(() {
        _draft = _repository.current;
        _activeSection = ArcBlueprintCaptureSection.bottom;
        _busy = false;
      });

      await _scanAndImport();
    } on PlatformException catch (error) {
      _showMessage(_pickerErrorMessage(error, ImageSource.camera), error: true);
    } catch (_) {
      _showMessage(
        'The Blueprint camera could not complete the capture. Try again or choose a screenshot.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (source == ImageSource.camera) {
      await _openLiveScanner();
      return;
    }
    if (_busy) return;
    if (source == ImageSource.camera && !_cameraSupported) {
      _showMessage(
        'Direct camera capture is not available on this device. Choose a screenshot instead.',
        error: true,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2400,
        requestFullMetadata: false,
      );
      if (image == null) {
        _showMessage(
          source == ImageSource.camera
              ? 'No photo was captured.'
              : 'No screenshot was selected.',
        );
        return;
      }
      await _storePickedImage(image);
    } on PlatformException catch (error) {
      _showMessage(_pickerErrorMessage(error, source), error: true);
    } on FormatException catch (error) {
      _showMessage(error.message, error: true);
    } catch (error) {
      _showMessage(_pickerErrorMessage(error, source), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retake(ArcBlueprintCaptureSection section) async {
    await _repository.clearSection(section);
    if (!mounted) return;
    setState(() {
      _draft = _repository.current;
      _activeSection = section;
    });
  }

  Uint8List? _bytesFor(ArcBlueprintCaptureSection section) {
    return section == ArcBlueprintCaptureSection.top
        ? _draft.topImageBytes
        : _draft.bottomImageBytes;
  }

  Future<void> _scanAndImport() async {
    if (!_draft.isComplete || _busy) return;
    final topBytes = _draft.topImageBytes;
    final bottomBytes = _draft.bottomImageBytes;
    if (topBytes == null || bottomBytes == null) return;

    setState(() => _busy = true);
    try {
      const latticeRegistrar = ArcBlueprintGridLatticeRegistrar();
      final registeredTop = latticeRegistrar.register(
        bytes: topBytes,
        columns: 10,
        rows: 5,
      );
      final registeredBottomFiveRows = latticeRegistrar.register(
        bytes: bottomBytes,
        columns: 10,
        rows: 5,
      );
      final registeredTopBytes = registeredTop.imageBytes;
      const bottomOverlapNormalizer = ArcBlueprintBottomOverlapNormalizer();
      final registeredBottomBytes = bottomOverlapNormalizer
          .removeRegisteredOverlap(registeredBottomFiveRows.imageBytes);
      if (kDebugMode) {
        debugPrint(
          'ARC GRID REGISTER: pipeline '
          'topRefined=${registeredTop.refined} '
          'bottomRefined=${registeredBottomFiveRows.refined} '
          'topX=${registeredTop.horizontalConfidence.toStringAsFixed(3)} '
          'topY=${registeredTop.verticalConfidence.toStringAsFixed(3)} '
          'bottomX=${registeredBottomFiveRows.horizontalConfidence.toStringAsFixed(3)} '
          'bottomY=${registeredBottomFiveRows.verticalConfidence.toStringAsFixed(3)}',
        );
      }

      const topAnalyzer = ArcBlueprintPhotoPixelAnalyzer(columns: 10, rows: 5);
      const bottomAnalyzer = ArcBlueprintPhotoPixelAnalyzer(
        columns: 10,
        rows: 4,
        validColumnCountsByRow: ArcBlueprintCanonicalGrid.bottomRowColumnCounts,
      );
      final top = topAnalyzer.analyze(
        bytes: registeredTopBytes,
        captureId: 'top',
      );
      final bottom = bottomAnalyzer.analyze(
        bytes: registeredBottomBytes,
        captureId: 'bottom',
      );

      if (!top.succeeded || !bottom.succeeded) {
        final message = [
          top.error,
          bottom.error,
        ].where((item) => item.isNotEmpty).join(' ');
        _showMessage(
          message.isEmpty
              ? 'The Blueprint grid could not be recognised. Retake both images closer to the screen.'
              : message,
          error: true,
        );
        return;
      }

      const mergeEngine = ArcBlueprintDualCaptureMergeEngine(
        columns: 10,
        topRows: 5,
        bottomRows: 4,
        finalRowCount: 3,
      );
      final merged = mergeEngine.merge(
        topSamples: top.samples,
        bottomSamples: bottom.samples,
      );

      if (!merged.succeeded) {
        _showMessage(merged.error, error: true);
        return;
      }

      final orderedBlueprintIds = ArcBlueprintSeedData.blueprints
          .map((blueprint) => blueprint.id)
          .toList(growable: false);

      // PASS 339: load the recovered/canonical tracker state before
      // classification so confirmed owned positions can calibrate this scan.
      // Missing positions are never treated as negative anchors.
      final existing = await ArcBlueprintRepository().loadMyBlueprintStates();
      const personalCalibration = ArcBlueprintPersonalCalibrationEngine();
      final calibrated = personalCalibration.calibrate(
        orderedBlueprintIds: orderedBlueprintIds,
        samples: merged.samples,
        existing: existing,
      );

      // PASS 340: verify only visually strong owned candidates against the
      // artwork expected at their exact canonical Blueprint position.
      // Template verification is suppression-only: it cannot promote a weak
      // or missing cell into ownership.
      const templateVerifier = ArcBlueprintTemplateVerificationEngine();
      final templateVerification = await templateVerifier.verify(
        topBytes: registeredTopBytes,
        bottomBytes: registeredBottomBytes,
        samples: calibrated.samples,
      );

      // PASS 343: direct owned-card UI verification for first-run scans.
      // Empty slots can still contain blue/purple grid texture, so strong
      // whole-cell candidates must also show the game's lower-left Blueprint
      // emblem / upper-right completion tick unless expected artwork is an
      // exceptionally strong match. This verifier is suppression-only.
      const ownershipMarkerVerifier =
          ArcBlueprintOwnershipMarkerVerificationEngine();
      final markerVerification = ownershipMarkerVerifier.verify(
        topBytes: registeredTopBytes,
        bottomBytes: registeredBottomBytes,
        samples: templateVerification.samples,
        templateDiagnostics: templateVerification.diagnostics,
      );

      if (kDebugMode) {
        for (final diagnostic in templateVerification.diagnostics) {
          debugPrint(
            'ARC TEMPLATE VERIFY: '
            'expected=${diagnostic.blueprintName} '
            'id=${diagnostic.blueprintId} '
            'index=${diagnostic.canonicalIndex} '
            'cell=${diagnostic.rowIndex + 1}:${diagnostic.columnIndex + 1} '
            'template=${diagnostic.templateSimilarity.toStringAsFixed(3)} '
            'multiSignal=${diagnostic.multiSignalEvidence.toStringAsFixed(3)} '
            'final=${diagnostic.finalScore.toStringAsFixed(3)} '
            'available=${diagnostic.templateAvailable} '
            'suppressed=${diagnostic.suppressed}',
          );
        }
        debugPrint(
          'ARC TEMPLATE VERIFY: summary '
          'anchors=${calibrated.knownOwnedAnchors} '
          'personalSuppressed=${calibrated.suppressedCandidateCount} '
          'templateSuppressed=${templateVerification.suppressedCandidateCount}',
        );
      }

      // V2 structural gate: ownership now has to resemble the actual ARC
      // completed-card UI, not merely score highly on generic colour/texture.
      //
      // Direct console/PC screenshots have materially different colour/luma
      // distribution from photographs of a display. Keep the live-camera
      // profile completely unchanged, but use a digital-input profile when
      // BOTH sections came through the explicit screenshot picker.
      final screenshotPair =
          _draft.topFileName.isNotEmpty &&
          _draft.bottomFileName.isNotEmpty &&
          _draft.topFileName != 'blueprint_grid_top.jpg' &&
          _draft.bottomFileName != 'blueprint_grid_bottom.jpg';

      final structureVerifier = screenshotPair
          ? const ArcBlueprintOwnedCellStructureVerifier(
              minimumBluePanelCoverage: 0.09,
              minimumFooterContrast: 0.04,
            )
          : const ArcBlueprintOwnedCellStructureVerifier();

      if (kDebugMode) {
        debugPrint(
          'ARC STRUCTURE PROFILE: '
          '${screenshotPair ? "digital-screenshot" : "live-camera"} '
          'blue=${structureVerifier.minimumBluePanelCoverage.toStringAsFixed(2)} '
          'contrast=${structureVerifier.minimumFooterContrast.toStringAsFixed(2)}',
        );
      }

      final structureVerification = structureVerifier.verify(
        topBytes: registeredTopBytes,
        bottomBytes: registeredBottomBytes,
        bottomFiveRowBytes: registeredBottomFiveRows.imageBytes,
        samples: markerVerification.samples,
        templateDiagnostics: templateVerification.diagnostics,
      );

      if (kDebugMode) {
        for (final diagnostic in structureVerification.diagnostics) {
          if (diagnostic.classification != 'uncertain') continue;
          final failed = <String>[
            if (diagnostic.bluePanelCoverage <
                structureVerifier.minimumBluePanelCoverage)
              'blue',
            if (diagnostic.footerDarkCoverage <
                structureVerifier.minimumFooterDarkCoverage)
              'footer',
            if (diagnostic.footerContrast <
                structureVerifier.minimumFooterContrast)
              'contrast',
            if (diagnostic.bookShapeEvidence <
                structureVerifier.minimumMarkerShapeEvidence)
              'book',
            if (diagnostic.tickShapeEvidence <
                structureVerifier.minimumMarkerShapeEvidence)
              'tick',
            if (diagnostic.templateSimilarity <
                structureVerifier.minimumArtworkSimilarity)
              'artwork',
          ];
          debugPrint(
            'ARC SIX SIGNAL: '
            '${diagnostic.captureId} '
            'R${diagnostic.rowIndex + 1}C${diagnostic.columnIndex + 1} '
            'blue=${diagnostic.bluePanelCoverage.toStringAsFixed(3)} '
            'footer=${diagnostic.footerDarkCoverage.toStringAsFixed(3)} '
            'contrast=${diagnostic.footerContrast.toStringAsFixed(3)} '
            'book=${diagnostic.bookShapeEvidence.toStringAsFixed(3)} '
            'tick=${diagnostic.tickShapeEvidence.toStringAsFixed(3)} '
            'artwork=${diagnostic.templateSimilarity.toStringAsFixed(3)} '
            'failed=${failed.join(",")} '
            'classification=${diagnostic.classification}',
          );
        }
      }

      const engine = ArcBlueprintPhotoOccupancyEngine(columns: 10);
      final result = engine.classify(
        orderedBlueprintIds: orderedBlueprintIds,
        samples: structureVerification.samples,
      );

      if (kDebugMode) {
        final ownedCount = result.decisions
            .where(
              (decision) => decision.state == ArcBlueprintPhotoCellState.owned,
            )
            .length;
        final missingCount = result.decisions
            .where(
              (decision) =>
                  decision.state == ArcBlueprintPhotoCellState.missing,
            )
            .length;
        final uncertainCount =
            result.decisions.length - ownedCount - missingCount;
        debugPrint(
          'ARC RECOGNITION: merged summary '
          'owned=$ownedCount missing=$missingCount uncertain=$uncertainCount',
        );
      }

      if (result.errors.isNotEmpty) {
        _showMessage(result.errors.join(' '), error: true);
        return;
      }

      // Structural/capture quality must still be good, but uncertainty no
      // longer blocks the entire import. Uncertain cells are ignored and only
      // confidently detected NEW ownership is offered for explicit review.
      const qualityGate = ArcBlueprintImportQualityGate(
        maximumUncertainCells: ArcBlueprintCanonicalGrid.totalPositions,
      );
      final quality = qualityGate.evaluate(
        decisions: result.decisions,
        topCaptureConfidence: top.confidence,
        bottomCaptureConfidence: bottom.confidence,
      );

      if (!quality.accepted) {
        _showMessage(quality.message, error: true);
        return;
      }

      final reconciliation = await ArcBlueprintPhotoImportService()
          .reconcileOwnershipEvidence(
            decisions: result.decisions,
            existing: existing,
            // Existing installs pre-date ownership provenance. A clean direct
            // screenshot pair is allowed to reconcile those legacy unknown states;
            // camera scans only auto-remove entries explicitly marked manual.
            allowLegacyUnknownCorrection: screenshotPair,
          );

      if (kDebugMode && reconciliation.changed) {
        debugPrint(
          'ARC OWNERSHIP RECONCILE: '
          'removed=${reconciliation.removedCount} '
          'scanConfirmed=${reconciliation.scanConfirmedCount} '
          'legacyUnknownCorrection=$screenshotPair',
        );
      }

      final uncertainCount = result.decisions
          .where((decision) => decision.needsReview)
          .length;

      final proposedAdditions = result.decisions
          .where(
            (decision) =>
                decision.state == ArcBlueprintPhotoCellState.owned &&
                existing[decision.blueprintId]?.owned != true,
          )
          .toList(growable: false);

      if (kDebugMode) {
        debugPrint(
          'ARC RECOGNITION: delta review '
          'existingOwned=${existing.values.where((state) => state.owned).length} '
          'proposedAdditions=${proposedAdditions.length} '
          'uncertainIgnored=$uncertainCount',
        );
      }

      if (proposedAdditions.isEmpty) {
        if (reconciliation.removedCount > 0) {
          final corrected = reconciliation.removedCount;
          _showMessage(
            '$corrected manual Blueprint entr'
            '${corrected == 1 ? 'y was' : 'ies were'} corrected from the scanned grid. '
            '$uncertainCount uncertain slot'
            '${uncertainCount == 1 ? '' : 's'} were left unchanged.',
          );
          await _repository.clear();
          if (!mounted) return;
          Navigator.of(context).pop(true);
          return;
        }

        _showMessage(
          uncertainCount == 0
              ? 'No new Blueprint ownership was detected.'
              : 'No new Blueprint ownership was detected confidently. '
                    '$uncertainCount uncertain slots were left unchanged.',
        );
        return;
      }

      if (!mounted) return;
      final applied = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => ArcBlueprintPhotoDeltaReviewScreen(
            proposedAdditions: proposedAdditions,
            uncertainIgnoredCount: uncertainCount,
          ),
        ),
      );

      if (applied != true) return;

      await _repository.clear();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FormatException catch (error) {
      _showMessage(error.message, error: true);
    } catch (_) {
      _showMessage(
        'Blueprint import failed. Check the image and try again.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _stepTitle => _activeSection == ArcBlueprintCaptureSection.top
      ? 'Capture the top of your grid'
      : 'Capture the overlap row, rows 6-8 and the final three slots';

  @override
  Widget build(BuildContext context) {
    final bytes = _bytesFor(_activeSection);
    final complete = _draft.isComplete;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'IMPORT BLUEPRINT GRID',
          style: ArcUiTokens.pageTitle(color: ArcUiTokens.primaryAccent),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ArcTacticalPageBody(
        width: ArcPageWidth.standard,
        maxWidth: 920,
        padding: ArcLayoutTokens.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_busy) ...[
              const LinearProgressIndicator(
                minHeight: 3,
                color: ArcUiTokens.primaryAccent,
                backgroundColor: Colors.white12,
              ),
              const SizedBox(height: 12),
            ],
            _ProgressHeader(
              completed: _draft.completedSections,
              activeSection: _activeSection,
            ),
            const SizedBox(height: 16),
            Text(
              _stepTitle,
              style: ArcUiTokens.sectionTitle(
                fontSize: 18,
                color: ArcUiTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _activeSection == ArcBlueprintCaptureSection.top
                  ? 'Fit the outer edges of the first five Blueprint rows inside the boundary. Keep the full left, right, top and bottom edges visible.'
                  : 'Keep row 5 visible once more as the overlap row. Include rows 6–8 fully and the final three Blueprint slots beneath them.',
              style: ArcUiTokens.body(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Avoid direct sunlight or strong screen reflections. If camera recognition struggles, use a clean console or PC screenshot.',
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
            ),
            const SizedBox(height: 14),
            AspectRatio(
              // Both captured images contain five physical rows. The bottom
              // image includes the one-row overlap until registration removes
              // it immediately before 4-row canonical analysis.
              aspectRatio: 10 / 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(color: Colors.black54),
                      child: bytes == null
                          ? const Center(
                              child: Icon(
                                Icons.grid_view_rounded,
                                color: Colors.white38,
                                size: 64,
                              ),
                            )
                          : Image.memory(bytes, fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: bytes == null
                                  ? ArcUiTokens.primaryAccent.withValues(
                                      alpha: 0.45,
                                    )
                                  : Colors.greenAccent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(
                              ArcUiTokens.radiusL,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: _SectionBadge(section: _activeSection),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (_cameraSupported)
                  FilledButton.icon(
                    key: const Key('blueprint-import-take-photo'),
                    onPressed: _busy ? null : _openLiveScanner,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(bytes == null ? 'Take Photo' : 'Retake Photo'),
                  ),
                OutlinedButton.icon(
                  key: const Key('blueprint-import-choose-image'),
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    bytes == null ? 'Choose Screenshot' : 'Use Screenshot',
                  ),
                ),
                if (bytes != null)
                  TextButton.icon(
                    onPressed: () => _retake(_activeSection),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _CaptureSummary(
              draft: _draft,
              busy: _busy,
              cameraSupported: _cameraSupported,
              onSelect: (section) => setState(() => _activeSection = section),
              onCapture: (section, source) {
                setState(() => _activeSection = section);
                unawaited(_pick(source));
              },
              onRetake: _retake,
            ),
            const SizedBox(height: 18),
            ArcTacticalPanel(
              icon: Icons.privacy_tip_outlined,
              title: 'Local Import Privacy',
              accent: ArcUiTokens.primaryAccent,
              child: Text(
                _cameraSupported
                    ? 'Privacy: photos are held only for this import session and are analysed locally. Confident matches import automatically. Uncertain slots are left unchanged. Duplicate counts are never read or changed.'
                    : 'This device uses screenshot upload rather than direct camera capture. Images are analysed locally. Confident matches import automatically and uncertain slots are left unchanged. Duplicate counts are never changed.',
                style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('blueprint-import-continue'),
              onPressed: complete && !_busy ? _scanAndImport : null,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Scan and Import Blueprints'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.completed, required this.activeSection});

  final int completed;
  final ArcBlueprintCaptureSection activeSection;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: completed / 2,
            minHeight: 8,
            color: ArcUiTokens.primaryAccent,
            backgroundColor: Colors.white12,
            borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${activeSection.index + 1}/2',
          style: ArcUiTokens.metadata(color: ArcUiTokens.textSecondary),
        ),
      ],
    );
  }
}

class _SectionBadge extends StatelessWidget {
  const _SectionBadge({required this.section});
  final ArcBlueprintCaptureSection section;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ArcUiTokens.surfaceOverlay,
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
        border: Border.all(
          color: ArcUiTokens.primaryAccent.withValues(alpha: 0.34),
        ),
      ),
      child: Padding(
        padding: ArcUiTokens.chipPadding,
        child: Text(
          section == ArcBlueprintCaptureSection.top
              ? 'TOP GRID'
              : 'BOTTOM GRID',
          style: ArcUiTokens.label(color: ArcUiTokens.primaryAccent),
        ),
      ),
    );
  }
}

class _CaptureSummary extends StatelessWidget {
  const _CaptureSummary({
    required this.draft,
    required this.busy,
    required this.cameraSupported,
    required this.onSelect,
    required this.onCapture,
    required this.onRetake,
  });

  final ArcBlueprintPhotoCaptureDraft draft;
  final bool busy;
  final bool cameraSupported;
  final ValueChanged<ArcBlueprintCaptureSection> onSelect;
  final void Function(ArcBlueprintCaptureSection, ImageSource) onCapture;
  final ValueChanged<ArcBlueprintCaptureSection> onRetake;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ArcBlueprintCaptureSection.values
          .map((section) {
            final captured = section == ArcBlueprintCaptureSection.top
                ? draft.hasTop
                : draft.hasBottom;
            return Card(
              color: ArcUiTokens.surfacePanel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
                side: BorderSide(
                  color: captured
                      ? ArcUiTokens.success.withValues(alpha: 0.38)
                      : ArcUiTokens.borderMedium,
                ),
              ),
              child: ListTile(
                onTap: busy
                    ? null
                    : () {
                        onSelect(section);
                        if (!captured) {
                          onCapture(section, ImageSource.gallery);
                        }
                      },
                leading: Icon(
                  captured ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: captured
                      ? ArcUiTokens.success
                      : ArcUiTokens.textTertiary,
                ),
                title: Text(
                  section == ArcBlueprintCaptureSection.top
                      ? 'Top grid image'
                      : 'Bottom grid image',
                  style: ArcUiTokens.cardTitle(fontSize: 14),
                ),
                subtitle: Text(
                  captured ? 'Captured' : 'Still required',
                  style: ArcUiTokens.bodySmall(),
                ),
                trailing: captured
                    ? IconButton(
                        tooltip: 'Retake',
                        onPressed: busy ? null : () => onRetake(section),
                        icon: const Icon(Icons.refresh),
                      )
                    : Wrap(
                        spacing: 2,
                        children: [
                          if (cameraSupported)
                            IconButton(
                              key: Key(
                                section == ArcBlueprintCaptureSection.top
                                    ? 'blueprint-import-top-camera'
                                    : 'blueprint-import-bottom-camera',
                              ),
                              tooltip: 'Take photo',
                              onPressed: busy
                                  ? null
                                  : () =>
                                        onCapture(section, ImageSource.camera),
                              icon: const Icon(Icons.photo_camera_outlined),
                            ),
                          IconButton(
                            key: Key(
                              section == ArcBlueprintCaptureSection.top
                                  ? 'blueprint-import-top-gallery'
                                  : 'blueprint-import-bottom-gallery',
                            ),
                            tooltip: 'Choose screenshot',
                            onPressed: busy
                                ? null
                                : () => onCapture(section, ImageSource.gallery),
                            icon: const Icon(Icons.image_outlined),
                          ),
                        ],
                      ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
