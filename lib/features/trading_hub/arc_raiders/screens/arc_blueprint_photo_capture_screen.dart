import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_section_grid_extractor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_dual_capture_merge_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_import_quality_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_pixel_analyzer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_personal_calibration_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_template_verification_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_uploaded_image_processor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_capture_draft.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_photo_capture_session_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_delta_review_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

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
    } catch (error) {
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
      final topSnapshot = Uint8List.fromList(result.topImageBytes);
      final bottomSnapshot = Uint8List.fromList(result.bottomImageBytes);

      await _repository.saveDualCapture(
        topBytes: topSnapshot,
        bottomBytes: bottomSnapshot,
        topFileName: 'blueprint_grid_top.jpg',
        bottomFileName: 'blueprint_grid_bottom.jpg',
      );
      if (!mounted) return;
      setState(() {
        _draft = _repository.current;
        _activeSection = ArcBlueprintCaptureSection.bottom;
      });
      await _scanAndImport();
    } on PlatformException catch (error) {
      _showMessage(_pickerErrorMessage(error, ImageSource.camera), error: true);
    } catch (error) {
      _showMessage(
        'The live Blueprint scanner could not complete the capture. Choose a screenshot or try again.',
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
      const topAnalyzer = ArcBlueprintPhotoPixelAnalyzer(columns: 10, rows: 5);
      const bottomAnalyzer = ArcBlueprintPhotoPixelAnalyzer(
        columns: 10,
        rows: 4,
        validColumnCountsByRow: ArcBlueprintCanonicalGrid.bottomRowColumnCounts,
      );
      final top = topAnalyzer.analyze(bytes: topBytes, captureId: 'top');
      final bottom = bottomAnalyzer.analyze(
        bytes: bottomBytes,
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
        topBytes: topBytes,
        bottomBytes: bottomBytes,
        samples: calibrated.samples,
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

      const engine = ArcBlueprintPhotoOccupancyEngine(columns: 10);
      final result = engine.classify(
        orderedBlueprintIds: orderedBlueprintIds,
        samples: templateVerification.samples,
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
    } catch (error) {
      _showMessage('Blueprint import failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _stepTitle => _activeSection == ArcBlueprintCaptureSection.top
      ? 'Capture the top of your grid'
      : 'Capture rows 6–8 and the final three slots';

  @override
  Widget build(BuildContext context) {
    final bytes = _bytesFor(_activeSection);
    final complete = _draft.isComplete;
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('IMPORT BLUEPRINT GRID'),
        backgroundColor: AppTheme.cardBackgroundDeep,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_busy) ...[
              const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: 12),
            ],
            _ProgressHeader(
              completed: _draft.completedSections,
              activeSection: _activeSection,
            ),
            const SizedBox(height: 16),
            Text(
              _stepTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontFamily: 'VT323',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _activeSection == ArcBlueprintCaptureSection.top
                  ? 'Fit the outer edges of the first five Blueprint rows inside the boundary. Keep the full left, right, top and bottom edges visible.'
                  : 'Start at row 6. Do not include row 5 again. Keep rows 6–8 fully visible and include the final three Blueprint slots beneath them.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            AspectRatio(
              aspectRatio: _activeSection == ArcBlueprintCaptureSection.top
                  ? 10 / 5
                  : 10 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                                  ? AppTheme.neonCyan.withValues(alpha: 0.45)
                                  : Colors.greenAccent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
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
                  label: Text(bytes == null ? 'Choose Screenshot' : 'Replace'),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardBackgroundDeep,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                _cameraSupported
                    ? 'Privacy: photos are held only for this import session and are analysed locally. Confident matches import automatically. Uncertain slots are left unchanged. Duplicate counts are never read or changed.'
                    : 'This device uses screenshot upload rather than direct camera capture. Images are analysed locally. Confident matches import automatically and uncertain slots are left unchanged. Duplicate counts are never changed.',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
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
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${activeSection.index + 1}/2',
          style: const TextStyle(color: Colors.white70),
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
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          section == ArcBlueprintCaptureSection.top
              ? 'TOP GRID'
              : 'BOTTOM GRID',
          style: const TextStyle(color: AppTheme.neonCyan),
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
              color: AppTheme.cardBackgroundDeep,
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
                  color: captured ? Colors.lightGreenAccent : Colors.white38,
                ),
                title: Text(
                  section == ArcBlueprintCaptureSection.top
                      ? 'Top grid image'
                      : 'Bottom grid image',
                ),
                subtitle: Text(captured ? 'Captured' : 'Still required'),
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
