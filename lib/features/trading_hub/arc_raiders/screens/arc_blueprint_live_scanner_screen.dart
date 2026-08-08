import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_automatic_grid_selector.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_detector.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_section_grid_extractor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_dual_capture_session.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/manual_alignment_controller.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_perspective_cropper.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_edge_calibration.dart';

bool canStartCapture({
  required bool controllerInitialized,
  required bool capturing,
  required bool isPortrait,
}) {
  return controllerInitialized && !capturing && !isPortrait;
}

class ArcBlueprintScannerResult {
  ArcBlueprintScannerResult({
    required Uint8List topImageBytes,
    required Uint8List bottomImageBytes,
  }) : topImageBytes = Uint8List.fromList(topImageBytes),
       bottomImageBytes = Uint8List.fromList(bottomImageBytes);

  final Uint8List topImageBytes;
  final Uint8List bottomImageBytes;
}

class ArcBlueprintLiveScannerScreen extends StatefulWidget {
  const ArcBlueprintLiveScannerScreen({super.key});

  @override
  State<ArcBlueprintLiveScannerScreen> createState() =>
      _ArcBlueprintLiveScannerScreenState();
}

enum _BlueprintLockState { searching, detected, locked }

class _ArcBlueprintLiveScannerScreenState
    extends State<ArcBlueprintLiveScannerScreen>
    with WidgetsBindingObserver {
  final ArcBlueprintAutomaticGridSelector _selector =
      const ArcBlueprintAutomaticGridSelector();

  CameraController? _controller;
  CameraDescription? _description;
  bool _initializing = true;
  bool _capturing = false;
  bool _debugDetection = false;
  bool _analyzingPreview = false;
  String? _error;
  _BlueprintLockState _lockState = _BlueprintLockState.searching;
  DateTime? _potentialLockTime;
  ArcBlueprintGridDetection _latestDetection =
      const ArcBlueprintGridDetection.notFound();
  FlashMode _flashMode = FlashMode.off;
  double _zoom = 1;
  double _baseZoom = 1;
  double _minZoom = 1;
  double _maxZoom = 1;
  ArcBlueprintDualCaptureSession _captureSession =
      const ArcBlueprintDualCaptureSession();

  bool get _capturingBottom => _captureSession.hasTop;

  bool get _gridLocked => _lockState == _BlueprintLockState.locked;

  // Manual alignment controllers for top and bottom captures.
  final ManualAlignmentController _topAlignmentController =
      ManualAlignmentController()..resetToTopDefault();
  final ManualAlignmentController _bottomAlignmentController =
      ManualAlignmentController()..resetToBottomDefault();

  // Last known viewport size used for normalized->source coordinate mapping.
  Size? _viewportSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    unawaited(_initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopPreviewStream());
    unawaited(_controller?.dispose());
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(controller.dispose());
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _description != null) {
      unawaited(_initialize(description: _description));
    }
  }

  Future<void> _initialize({CameraDescription? description}) async {
    if (mounted) {
      setState(() {
        _initializing = true;
        _error = null;
      });
    }
    try {
      final cameras = description == null ? await availableCameras() : null;
      final selected =
          description ??
          cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );
      await _controller?.dispose();
      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _description = selected;
        _controller = controller;
        _initializing = false;
        _flashMode = FlashMode.off;
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _zoom = minZoom;
        _baseZoom = minZoom;
      });
      await _startPreviewStream();
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = error.description ?? error.code;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = error.message ?? 'The camera could not be started.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'No usable camera could be started.';
      });
    }
  }

  Future<void> _startPreviewStream() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    try {
      await controller.startImageStream(_processPreviewFrame);
    } on CameraException {
      // Ignore preview streaming errors and continue with capture-only mode.
    }
  }

  Future<void> _stopPreviewStream() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (!controller.value.isStreamingImages) return;

    try {
      await controller.stopImageStream();
    } on CameraException {
      // Ignore if the stream is already stopped.
    }
  }

  void _processPreviewFrame(CameraImage image) {
    if (_capturing || _analyzingPreview || !mounted) return;
    _analyzingPreview = true;

    try {
      final detectionRows = _capturingBottom ? 3 : 5;
      final frameImage = _convertCameraImage(image);
      if (frameImage == null) return;

      final detection = ArcBlueprintGridDetector(
        columns: 10,
        rows: detectionRows,
        analysisWidth: 640,
      ).detectImage(frameImage);

      _updateLockState(detection);
    } finally {
      _analyzingPreview = false;
    }
  }

  img.Image? _convertCameraImage(CameraImage image) {
    const maxPreviewWidth = 720;
    final srcWidth = image.width;
    final srcHeight = image.height;
    final targetWidth = srcWidth > maxPreviewWidth ? maxPreviewWidth : srcWidth;
    final scale = srcWidth / targetWidth;
    final targetHeight = (srcHeight / scale).round();

    if (image.format.group == ImageFormatGroup.yuv420) {
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      final result = img.Image(width: targetWidth, height: targetHeight);

      for (var y = 0; y < targetHeight; y++) {
        final sourceY = (y * scale).floor().clamp(0, srcHeight - 1);
        final yRow = sourceY * yPlane.bytesPerRow;
        final uvRow = (sourceY / 2).floor();

        for (var x = 0; x < targetWidth; x++) {
          final sourceX = (x * scale).floor().clamp(0, srcWidth - 1);
          final yIndex = yRow + sourceX;
          final uvCol = (sourceX / 2).floor();
          final uIndex =
              uvRow * uPlane.bytesPerRow + uvCol * (uPlane.bytesPerPixel ?? 1);
          final vIndex =
              uvRow * vPlane.bytesPerRow + uvCol * (vPlane.bytesPerPixel ?? 1);

          final yValue = yPlane.bytes[yIndex];
          final uValue = uPlane.bytes[uIndex];
          final vValue = vPlane.bytes[vIndex];
          final yPrime = yValue.toInt();
          final uPrime = uValue.toInt() - 128;
          final vPrime = vValue.toInt() - 128;

          final r = (yPrime + 1.402 * vPrime).round().clamp(0, 255);
          final g = (yPrime - 0.344136 * uPrime - 0.714136 * vPrime)
              .round()
              .clamp(0, 255);
          final b = (yPrime + 1.772 * uPrime).round().clamp(0, 255);
          result.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      return result;
    }

    if (image.format.group == ImageFormatGroup.bgra8888) {
      final plane = image.planes[0];
      final result = img.Image(width: targetWidth, height: targetHeight);

      for (var y = 0; y < targetHeight; y++) {
        final sourceY = (y * scale).floor().clamp(0, srcHeight - 1);
        final rowOffset = sourceY * plane.bytesPerRow;

        for (var x = 0; x < targetWidth; x++) {
          final sourceX = (x * scale).floor().clamp(0, srcWidth - 1);
          final index = rowOffset + sourceX * 4;
          final b = plane.bytes[index];
          final g = plane.bytes[index + 1];
          final r = plane.bytes[index + 2];
          final a = plane.bytes[index + 3];
          result.setPixelRgba(x, y, r, g, b, a);
        }
      }

      return result;
    }

    return null;
  }

  void _updateLockState(ArcBlueprintGridDetection detection) {
    final now = DateTime.now();
    final isLocked = detection.isLocked;
    final isDetected = detection.isValid;

    if (isLocked) {
      _potentialLockTime ??= now;
      if (now.difference(_potentialLockTime!).inMilliseconds >= 1000) {
        _lockState = _BlueprintLockState.locked;
      } else {
        _lockState = _BlueprintLockState.detected;
      }
    } else if (isDetected) {
      _potentialLockTime = null;
      _lockState = _BlueprintLockState.detected;
    } else {
      _potentialLockTime = null;
      _lockState = _BlueprintLockState.searching;
    }

    if (mounted) {
      setState(() {
        _latestDetection = detection;
      });
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await controller.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } on CameraException {
      _showMessage('Flash is not available for this camera.');
    }
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
    _zoom = next;
    await controller.setZoomLevel(next);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _baseZoom = _zoom;
  }


  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      _capturing = true;
    });

    try {
      await _stopPreviewStream();
      final photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      final section = _capturingBottom
          ? ArcBlueprintGridSection.bottom
          : ArcBlueprintGridSection.top;

      // Use manual alignment calibration where possible as the authoritative crop.
      Uint8List? corrected;
      try {
        final controller = _capturingBottom
            ? _bottomAlignmentController
            : _topAlignmentController;
        if (_viewportSize != null && controller.calibration.isValid) {
          corrected = ArcBlueprintPerspectiveCropper().rectify(
            imageBytes: bytes,
            viewportSize: _viewportSize!,
            calibration: controller.calibration,
          );
        } else {
          // Fallback to automatic selector when viewport not available
          final selection = _selector.select(bytes, section: section);
          corrected = selection.imageBytes;
        }
      } catch (e) {
        // If cropper fails, fallback to automatic selection
        final selection = _selector.select(bytes, section: section);
        corrected = selection.imageBytes;
      }

      if (!mounted) return;

      if (!_capturingBottom) {
        final nextSession = _captureSession.captureTop(corrected);
        setState(() {
          _captureSession = nextSession;
          _lockState = _BlueprintLockState.searching;
          _potentialLockTime = null;
          _latestDetection = const ArcBlueprintGridDetection.notFound();
        });
        _showMessage(
          'Rows 1–5 captured. Scroll to row 6 for the second capture.',
        );
        if (mounted) {
          await _startPreviewStream();
        }
        return;
      }

      final completed = _captureSession.captureBottom(corrected);
      final top = completed.topImageBytes;
      final bottom = completed.bottomImageBytes;
      if (top == null || bottom == null || !mounted) return;

      setState(() => _captureSession = completed);
      Navigator.of(context).pop(
        ArcBlueprintScannerResult(topImageBytes: top, bottomImageBytes: bottom),
      );
    } on FormatException catch (error) {
      _showMessage(error.message);
    } on CameraException catch (error) {
      _showMessage(error.description ?? error.code);
    } catch (_) {
      _showMessage('The Blueprint grid could not be captured. Please retry.');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : _error != null || controller == null
          ? _ErrorState(
              message: _error ?? 'Camera unavailable.',
              onRetry: _initialize,
              onCancel: () => Navigator.of(context).pop(),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final media = MediaQuery.of(context);
                final isPortrait = media.size.width < media.size.height;
                final captureStep = _capturingBottom
                    ? 'Capture 2 of 2'
                    : 'Capture 1 of 2';
                final captureInstructions = _capturingBottom
                    ? 'Scroll until Row 6 is at the top. Capture Rows 6–9. Duplicate rows are ignored automatically.'
                    : 'Fit the complete 10×5 blueprint grid inside the guides. Do not crop any edge.';
                final lockStatusText =
                    _lockState == _BlueprintLockState.searching
                    ? 'Searching for blueprint grid...'
                    : _lockState == _BlueprintLockState.detected
                    ? 'Blueprint grid detected'
                    : 'Grid locked ✓';
                final statusColor = _gridLocked
                    ? Colors.greenAccent
                    : Colors.white;
                // record viewport size for coordinate mapping
                _viewportSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return GestureDetector(
                  onScaleStart: (_) => _baseZoom = _zoom,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!isPortrait)
                        _CoverCameraPreview(controller: controller),
                      if (!isPortrait)
                        Positioned.fill(
                          child: _BlueprintScannerOverlay(
                            controller: _capturingBottom
                                ? _bottomAlignmentController
                                : _topAlignmentController,
                            locked: _gridLocked,
                            detection: _latestDetection,
                          ),
                        ),
                      if (!isPortrait)
                        Positioned(
                          left: 12,
                          right: 12,
                          top: media.padding.top + 6,
                          child: Row(
                            children: [
                              IconButton.filledTonal(
                                onPressed: _capturing
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      captureStep,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'VT323',
                                        fontSize: 22,
                                      ),
                                    ),
                                    Text(
                                      captureInstructions,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: _debugDetection
                                    ? 'Grid debug overlay on'
                                    : 'Grid debug overlay off',
                                onPressed: _capturing
                                    ? null
                                    : () => setState(
                                        () =>
                                            _debugDetection = !_debugDetection,
                                      ),
                                icon: Icon(
                                  _debugDetection
                                      ? Icons.bug_report_rounded
                                      : Icons.bug_report_outlined,
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton.filledTonal(
                                onPressed: _capturing ? null : _toggleFlash,
                                icon: Icon(
                                  _flashMode == FlashMode.off
                                      ? Icons.flash_off
                                      : Icons.flash_on,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isPortrait)
                        Positioned(
                          left: 16,
                          right: 16,
                          top: media.padding.top + 88,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 184.0),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                lockStatusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontFamily: 'VT323',
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (!isPortrait && _capturingBottom)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: media.padding.bottom + 102,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 184.0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.neonCyan),
                            ),
                            child: const Text(
                              'ROWS 1–5 SAVED — START AT ROW 6, NO DUPLICATE ROW',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'VT323',
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      if (!isPortrait)
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: media.padding.bottom + 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_capturingBottom)
                                IconButton.filledTonal(
                                  tooltip: 'Restart top capture',
                                  onPressed: _capturing
                                      ? null
                                      : () => setState(() {
                                          _captureSession =
                                              const ArcBlueprintDualCaptureSession();
                                          _lockState =
                                              _BlueprintLockState.searching;
                                          _potentialLockTime = null;
                                          _latestDetection =
                                              const ArcBlueprintGridDetection.notFound();
                                        }),
                                  icon: const Icon(Icons.restart_alt),
                                ),
                              if (_capturingBottom) const SizedBox(width: 12),

                              // Auto align uses the detector result to initialise manual frame
                              IconButton.filledTonal(
                                tooltip: 'Auto align',
                                onPressed: _capturing
                                    ? null
                                    : () {
                                        final controller = _capturingBottom
                                            ? _bottomAlignmentController
                                            : _topAlignmentController;
                                        controller.autoAlignFromDetection(
                                          _latestDetection,
                                        );
                                        setState(() {});
                                      },
                                icon: const Icon(Icons.auto_fix_high_rounded),
                              ),
                              const SizedBox(width: 8),

                              IconButton.filledTonal(
                                tooltip: 'Reset frame',
                                onPressed: _capturing
                                    ? null
                                    : () {
                                        final controller = _capturingBottom
                                            ? _bottomAlignmentController
                                            : _topAlignmentController;
                                        controller.resetToDefaults(
                                          bottomCapture: _capturingBottom,
                                        );
                                        setState(() {});
                                      },
                                icon: const Icon(Icons.crop_rounded),
                              ),
                              const SizedBox(width: 12),

                              InkResponse(
                                key: const Key(
                                  'blueprint-live-scanner-capture',
                                ),
                                onTap:
                                    (canStartCapture(
                                      controllerInitialized:
                                          controller.value.isInitialized,
                                      capturing: _capturing,
                                      isPortrait: isPortrait,
                                    ))
                                    ? _capture
                                    : null,
                                radius: 44,
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _capturing
                                        ? Colors.white38
                                        : (_gridLocked
                                              ? Colors.white
                                              : Colors.white12),
                                    border: Border.all(
                                      color: _gridLocked
                                          ? Colors.greenAccent
                                          : AppTheme.neonCyan,
                                      width: 5,
                                    ),
                                  ),
                                  child: _capturing
                                      ? const Padding(
                                          padding: EdgeInsets.all(22),
                                          child: CircularProgressIndicator(),
                                        )
                                      : Icon(
                                          _capturingBottom
                                              ? Icons.check_rounded
                                              : Icons.camera_alt_rounded,
                                          color: _gridLocked
                                              ? Colors.black
                                              : Colors.white54,
                                          size: 34,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isPortrait && kDebugMode)
                        Positioned(
                          left: 18,
                          bottom: media.padding.bottom + 100,
                          child: _DebugGridMetrics(
                            detection: _latestDetection,
                            locked: _gridLocked,
                          ),
                        ),
                      if (isPortrait) const _RotateToLandscapePage(),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _CoverCameraPreview extends StatelessWidget {
  const _CoverCameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final rawAspect = previewSize.width / previewSize.height;
        final reciprocal = 1 / rawAspect;
        final viewportAspect = viewport.width / viewport.height;
        final aspect =
            (rawAspect - viewportAspect).abs() <
                (reciprocal - viewportAspect).abs()
            ? rawAspect
            : reciprocal;

        var width = viewport.width;
        var height = width / aspect;
        if (height < viewport.height) {
          height = viewport.height;
          width = height * aspect;
        }

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: SizedBox(
              width: width,
              height: height,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }
}

class _BlueprintScannerOverlay extends StatefulWidget {
  const _BlueprintScannerOverlay({
    required this.controller,
    required this.locked,
    required this.detection,
  });

  final ManualAlignmentController controller;
  final bool locked;
  final ArcBlueprintGridDetection detection;

  @override
  State<_BlueprintScannerOverlay> createState() =>
      _BlueprintScannerOverlayState();
}

class _BlueprintScannerOverlayState extends State<_BlueprintScannerOverlay> {
  // drag target enum
  _DragTarget _dragTarget = _DragTarget.none;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanStart: (details) {
            final local = details.localPosition;
            final norm = Offset(local.dx / size.width, local.dy / size.height);
            final rect = widget.controller.calibration.normalizedRect;
            const handleThreshold = 0.04; // normalized units threshold

            if ((norm.dx - rect.left).abs() < handleThreshold) {
              _dragTarget = _DragTarget.left;
            } else if ((norm.dx - rect.right).abs() < handleThreshold) {
              _dragTarget = _DragTarget.right;
            } else if ((norm.dy - rect.top).abs() < handleThreshold) {
              _dragTarget = _DragTarget.top;
            } else if ((norm.dy - rect.bottom).abs() < handleThreshold) {
              _dragTarget = _DragTarget.bottom;
            } else if (rect.contains(norm)) {
              _dragTarget = _DragTarget.center;
            } else {
              _dragTarget = _DragTarget.none;
            }
          },
          onPanUpdate: (details) {
            final local = details.localPosition;
            final dx = details.delta.dx / size.width;
            final dy = details.delta.dy / size.height;
            final normX = (local.dx / size.width).clamp(0.0, 1.0);
            final normY = (local.dy / size.height).clamp(0.0, 1.0);

            setState(() {
              switch (_dragTarget) {
                case _DragTarget.left:
                  widget.controller.moveEdge(ArcBlueprintCropEdge.left, normX);
                  break;
                case _DragTarget.right:
                  widget.controller.moveEdge(ArcBlueprintCropEdge.right, normX);
                  break;
                case _DragTarget.top:
                  widget.controller.moveEdge(ArcBlueprintCropEdge.top, normY);
                  break;
                case _DragTarget.bottom:
                  widget.controller.moveEdge(
                    ArcBlueprintCropEdge.bottom,
                    normY,
                  );
                  break;
                case _DragTarget.center:
                  widget.controller.translate(dx, dy);
                  break;
                case _DragTarget.none:
                  break;
              }
            });
          },
          onPanEnd: (_) {
            _dragTarget = _DragTarget.none;
          },
          child: CustomPaint(
            painter: _BlueprintGuidePainter2(
              calibration: widget.controller.calibration,
              locked: widget.locked,
              detection: widget.detection,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

enum _DragTarget { left, right, top, bottom, center, none }

class _BlueprintGuidePainter2 extends CustomPainter {
  const _BlueprintGuidePainter2({
    required this.calibration,
    required this.locked,
    required this.detection,
  });

  final ArcBlueprintEdgeCalibration calibration;
  final bool locked;
  final ArcBlueprintGridDetection detection;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      calibration.left * size.width,
      calibration.top * size.height,
      (calibration.right - calibration.left) * size.width,
      (calibration.bottom - calibration.top) * size.height,
    );

    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutout = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)));
    final overlay = Path.combine(PathOperation.difference, outer, cutout);

    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 132.6),
    );

    final borderPaint = Paint()
      ..color = locked ? Colors.greenAccent : Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      borderPaint,
    );

    final bracketPaint = Paint()
      ..color = locked ? Colors.greenAccent : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const bracketLength = 28.0;

    void drawCorner(Offset corner, double dx, double dy) {
      canvas.drawLine(corner, corner.translate(dx, 0), bracketPaint);
      canvas.drawLine(corner, corner.translate(0, dy), bracketPaint);
    }

    drawCorner(rect.topLeft, bracketLength, 0);
    drawCorner(rect.topRight, -bracketLength, 0);
    drawCorner(rect.bottomLeft, bracketLength, 0);
    drawCorner(rect.bottomRight, -bracketLength, 0);

    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 51.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var column = 1; column < 10; column++) {
      final x = rect.left + (rect.width * column / 10);
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), guidePaint);
    }
    for (var row = 1; row < 5; row++) {
      final y = rect.top + (rect.height * row / 5);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), guidePaint);
    }

    final center = rect.center;
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 166.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const crossSize = 16.0;
    canvas.drawLine(
      Offset(center.dx - crossSize, center.dy),
      Offset(center.dx + crossSize, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - crossSize),
      Offset(center.dx, center.dy + crossSize),
      crossPaint,
    );

    // Draw subtle edge handles
    final handlePaint = Paint()..color = AppTheme.neonCyan.withValues(alpha: 229.5);
    const handleSize = 10.0;
    canvas.drawRect(
      Rect.fromCenter(
        center: rect.topLeft,
        width: handleSize,
        height: handleSize,
      ),
      handlePaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: rect.topRight,
        width: handleSize,
        height: handleSize,
      ),
      handlePaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: rect.bottomLeft,
        width: handleSize,
        height: handleSize,
      ),
      handlePaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: rect.bottomRight,
        width: handleSize,
        height: handleSize,
      ),
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BlueprintGuidePainter2 oldDelegate) {
    return oldDelegate.locked != locked ||
        oldDelegate.calibration != calibration ||
        oldDelegate.detection != detection;
  }
}

class _DebugGridMetrics extends StatelessWidget {
  const _DebugGridMetrics({required this.detection, required this.locked});

  final ArcBlueprintGridDetection detection;
  final bool locked;

  String get _confidence => '${(detection.confidence * 100).round()}%';

  String get _coverage {
    if (!detection.isValid) return '0%';
    final area =
        (detection.bottomRight.dx - detection.topLeft.dx) *
        (detection.bottomRight.dy - detection.topLeft.dy);
    return '${(area * 100).round()}%';
  }

  String get _angle {
    if (!detection.isValid) return '0.0°';
    final deltaX = detection.topRight.dx - detection.topLeft.dx;
    final deltaY = detection.topRight.dy - detection.topLeft.dy;
    return '${(math.atan2(deltaY, deltaX) * 180 / math.pi).abs().toStringAsFixed(1)}°';
  }

  String get _perspective {
    if (!detection.isValid) return '0.0%';
    final topWidth = (detection.topRight.dx - detection.topLeft.dx).abs();
    final bottomWidth = (detection.bottomRight.dx - detection.bottomLeft.dx)
        .abs();
    final widthDiff = (topWidth - bottomWidth).abs();
    final widthRatio = widthDiff / math.max(topWidth, bottomWidth);
    final leftHeight = (detection.bottomLeft.dy - detection.topLeft.dy).abs();
    final rightHeight = (detection.bottomRight.dy - detection.topRight.dy)
        .abs();
    final heightDiff = (leftHeight - rightHeight).abs();
    final heightRatio = heightDiff / math.max(leftHeight, rightHeight);
    final result = ((widthRatio + heightRatio) / 2 * 100).clamp(0, 100);
    return '${result.round()}%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 158.0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: locked ? Colors.greenAccent : Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grid angle: $_angle',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Perspective: $_perspective',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Lock confidence: $_confidence',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Coverage: $_coverage',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RotateToLandscapePage extends StatelessWidget {
  const _RotateToLandscapePage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.screen_rotation_rounded,
            color: Colors.white,
            size: 68,
          ),
          const SizedBox(height: 20),
          const Text(
            'Rotate your phone to landscape',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'The Blueprint Scanner is designed for landscape mode.\nRotate your phone and continue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white70,
              size: 54,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Retry Camera'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
