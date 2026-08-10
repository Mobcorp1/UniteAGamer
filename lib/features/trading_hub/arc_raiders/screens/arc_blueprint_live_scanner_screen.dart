import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_automatic_grid_selector.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_camera_lifecycle_guard.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_camera_frame_adapter.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_detector.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_grid_lock_tracker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_section_grid_extractor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_dual_capture_session.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_grid_detection_overlay.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_live_targeting_overlay.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

/// Pure shutter-availability contract retained for scanner regression tests.
///
/// Grid-lock state is intentionally not part of this predicate. Live grid lock
/// can improve guidance, but camera availability itself is determined only by
/// controller readiness, capture-in-progress state, and unsupported portrait
/// orientation.
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

class _ArcBlueprintLiveScannerScreenState
    extends State<ArcBlueprintLiveScannerScreen>
    with WidgetsBindingObserver {
  final ArcBlueprintAutomaticGridSelector _selector =
      const ArcBlueprintAutomaticGridSelector();
  final ArcBlueprintCameraFrameAdapter _frameAdapter =
      const ArcBlueprintCameraFrameAdapter(maximumWidth: 480);
  final ArcBlueprintLiveGridLockTracker _liveLockTracker =
      ArcBlueprintLiveGridLockTracker(
        requiredStableFrames: 3,
        minimumConfidence: 0.62,
      );

  ArcBlueprintGridDetection? _lastDetection;

  final ArcCameraLifecycleGuard _cameraLifecycle = ArcCameraLifecycleGuard();
  CameraController? _controller;
  Future<void>? _initializationFuture;
  bool _disposed = false;
  CameraDescription? _description;
  bool _initializing = true;
  bool _capturing = false;
  bool _processingLiveFrame = false;
  DateTime? _lastLiveFrameAt;
  bool _stableLiveLock = false;
  bool _debugDetection = false;
  String? _error;
  String _lockMessage = 'AUTO GRID READY';
  double _lastConfidence = 0;
  FlashMode _flashMode = FlashMode.off;
  double _zoom = 1;
  double _baseZoom = 1;
  double _minZoom = 1;
  double _maxZoom = 1;
  ArcBlueprintDualCaptureSession _captureSession =
      const ArcBlueprintDualCaptureSession();

  bool get _capturingBottom => _captureSession.hasTop;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cameraLifecycle.invalidate();

    final controller = _controller;
    _controller = null;

    if (controller != null) {
      unawaited(_disposeController(controller));
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_pauseCamera());
      return;
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(_resumeCamera());
    }
  }

  Future<void> _pauseCamera() async {
    if (_disposed) return;

    _cameraLifecycle.invalidate();
    final controller = _controller;

    if (controller == null) return;

    if (mounted) {
      setState(() {
        if (identical(_controller, controller)) {
          _controller = null;
        }
        _stableLiveLock = false;
        _lastDetection = null;
        _lastConfidence = 0;
      });

      // Remove CameraPreview from the widget tree before disposing the
      // controller referenced by the previous frame.
      await Future<void>.delayed(const Duration(milliseconds: 20));
    } else if (identical(_controller, controller)) {
      _controller = null;
    }

    await _disposeController(controller);
  }

  Future<void> _resumeCamera() async {
    if (_disposed || !mounted || _controller != null) return;
    await _initialize(description: _description);
  }

  Future<void> _disposeController(CameraController controller) async {
    try {
      if (controller.value.isInitialized &&
          controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } on CameraException {
      // The platform may already have closed the stream while backgrounding.
    } catch (_) {
      // Disposal must continue even if CameraX reports a stale stream.
    }

    try {
      await controller.dispose();
    } on CameraException {
      // CameraX can report a device error while the controller is closing.
    } catch (_) {
      // Best-effort cleanup; never reuse this controller after this point.
    }
  }

  Future<void> _initialize({CameraDescription? description}) async {
    if (_disposed || !mounted) return;

    final existingInitialization = _initializationFuture;
    if (existingInitialization != null) {
      await existingInitialization;
      if (_disposed || !mounted || _controller != null) return;
    }

    final generation = _cameraLifecycle.beginGeneration();
    final future = _initializeGeneration(
      generation: generation,
      description: description,
    );
    _initializationFuture = future;

    try {
      await future;
    } finally {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
      }
    }
  }

  Future<void> _initializeGeneration({
    required int generation,
    CameraDescription? description,
  }) async {
    if (_disposed || !mounted || !_cameraLifecycle.isCurrent(generation)) {
      return;
    }

    setState(() {
      _initializing = true;
      _error = null;
    });

    CameraController? createdController;

    try {
      final cameras = description == null ? await availableCameras() : null;

      if (!_cameraLifecycle.isCurrent(generation) || _disposed || !mounted) {
        return;
      }

      if (description == null && (cameras == null || cameras.isEmpty)) {
        setState(() {
          _initializing = false;
          _error = 'No camera was found on this device.';
        });
        return;
      }

      final selected =
          description ??
          cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );

      final previous = _controller;
      if (previous != null) {
        setState(() => _controller = null);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await _disposeController(previous);
      }

      if (!_cameraLifecycle.isCurrent(generation) || _disposed || !mounted) {
        return;
      }

      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );
      createdController = controller;

      await controller.initialize();

      if (!_cameraLifecycle.isCurrent(generation) || _disposed || !mounted) {
        await _disposeController(controller);
        return;
      }

      await controller.setFlashMode(FlashMode.off);
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();

      if (!_cameraLifecycle.isCurrent(generation) || _disposed || !mounted) {
        await _disposeController(controller);
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

      await _startLiveDetection(controller, generation: generation);
    } on CameraException catch (error) {
      if (createdController != null &&
          !identical(_controller, createdController)) {
        await _disposeController(createdController);
      }

      if (!_cameraLifecycle.isCurrent(generation) || _disposed || !mounted) {
        return;
      }

      setState(() {
        _initializing = false;
        _controller = null;
        _error = error.description ?? error.code;
      });
    } on PlatformException catch (error) {
      if (createdController != null &&
          !identical(_controller, createdController)) {
        await _disposeController(createdController);
      }

      if (!_cameraLifecycle.isCurrent(generation) || _disposed || !mounted) {
        return;
      }

      setState(() {
        _initializing = false;
        _controller = null;
        _error = error.message ?? 'The camera could not be started.';
      });
    } catch (_) {
      if (createdController != null &&
          !identical(_controller, createdController)) {
        await _disposeController(createdController);
      }

      if (!_cameraLifecycle.isCurrent(generation) || _disposed || !mounted) {
        return;
      }

      setState(() {
        _initializing = false;
        _controller = null;
        _error = 'No usable camera could be started.';
      });
    }
  }

  Future<void> _startLiveDetection(
    CameraController controller, {
    int? generation,
  }) async {
    final expectedGeneration = generation ?? _cameraLifecycle.currentGeneration;

    if (_disposed ||
        !_cameraLifecycle.isCurrent(expectedGeneration) ||
        !identical(_controller, controller) ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }

    _liveLockTracker.reset();
    _stableLiveLock = false;
    _lastDetection = null;
    _lastConfidence = 0;

    try {
      await controller.startImageStream(
        (frame) => _processLiveFrame(
          frame,
          controller: controller,
          generation: expectedGeneration,
        ),
      );
    } on CameraException {
      // Still-photo capture remains available if streaming is unsupported.
    }
  }

  Future<void> _stopLiveDetection({CameraController? controller}) async {
    final activeController = controller ?? _controller;
    if (activeController == null ||
        !activeController.value.isInitialized ||
        !activeController.value.isStreamingImages) {
      return;
    }

    try {
      await activeController.stopImageStream();
    } on CameraException {
      // Capture/disposal will surface any real camera failure.
    }
  }

  void _processLiveFrame(
    CameraImage frame, {
    required CameraController controller,
    required int generation,
  }) {
    if (_disposed ||
        _capturing ||
        _processingLiveFrame ||
        !mounted ||
        !_cameraLifecycle.isCurrent(generation) ||
        !identical(_controller, controller)) {
      return;
    }

    final now = DateTime.now();
    final last = _lastLiveFrameAt;
    if (last != null &&
        now.difference(last) < const Duration(milliseconds: 350)) {
      return;
    }

    _lastLiveFrameAt = now;
    _processingLiveFrame = true;

    Future<void>(() {
      try {
        final image = _frameAdapter.convert(
          frame,
          rotationDegrees: _description?.sensorOrientation ?? 0,
        );

        final detector = ArcBlueprintGridDetector(
          columns: 10,
          rows: _capturingBottom ? 3 : 5,
          analysisWidth: 480,
          minimumConfidence: 0.58,
        );

        final detection = detector.detectImage(image);
        final state = _liveLockTracker.update(detection);

        if (_disposed ||
            !mounted ||
            !_cameraLifecycle.isCurrent(generation) ||
            !identical(_controller, controller)) {
          return;
        }

        setState(() {
          _lastDetection = state.detection;
          _lastConfidence = state.detection?.confidence ?? 0;
          _stableLiveLock = state.isStable;

          if (state.isStable) {
            _lockMessage =
                'GRID LOCKED ${(_lastConfidence * 100).round()}% — READY';
          } else if (state.detection != null) {
            _lockMessage = 'HOLD STEADY ${(_lastConfidence * 100).round()}%';
          } else {
            _lockMessage = 'ALIGN BLUEPRINT GRID INSIDE THE CORNERS';
          }
        });
      } finally {
        _processingLiveFrame = false;
      }
    });
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await controller.setFlashMode(next);
      if (mounted && identical(_controller, controller)) {
        setState(() => _flashMode = next);
      }
    } on CameraException {
      _showMessage('Flash is not available for this camera.');
    }
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
    _zoom = next;
    try {
      await controller.setZoomLevel(next);
    } on CameraException {
      // Ignore a zoom update racing with camera pause/disposal.
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _baseZoom = _zoom;
  }

  Future<void> _showDetectionDebug({
    required Uint8List imageBytes,
    required ArcBlueprintGridDetection detection,
  }) async {
    if (!_debugDetection || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            detection.isLocked
                ? 'GRID LOCKED ${(detection.confidence * 100).round()}%'
                : 'GRID NOT LOCKED',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'VT323',
              fontSize: 24,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ArcBlueprintGridDetectionOverlay(
              imageBytes: imageBytes,
              detection: detection,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      _capturing = true;
      _lockMessage = 'ANALYSING GRID…';
    });

    await _stopLiveDetection(controller: controller);

    if (_disposed ||
        !mounted ||
        !identical(_controller, controller) ||
        !controller.value.isInitialized) {
      if (mounted) setState(() => _capturing = false);
      return;
    }

    try {
      final photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      final section = _capturingBottom
          ? ArcBlueprintGridSection.bottom
          : ArcBlueprintGridSection.top;
      final selection = _selector.select(bytes, section: section);
      final detection = selection.detection;
      if (mounted) setState(() => _lastDetection = detection);
      await _showDetectionDebug(imageBytes: bytes, detection: detection);
      final corrected = selection.imageBytes;
      if (!mounted) return;
      setState(() {
        _lastConfidence = detection.confidence;
        _lockMessage = 'GRID LOCKED ${(detection.confidence * 100).round()}%';
      });

      if (!_capturingBottom) {
        setState(() {
          _captureSession = _captureSession.captureTop(corrected);
        });
        _showMessage(
          'Rows 1–5 captured. Scroll to row 6 for the second capture.',
        );
        _liveLockTracker.reset();
        if (mounted) {
          setState(() {
            _lastDetection = null;
            _lastConfidence = 0;
            _stableLiveLock = false;
            _lockMessage = 'ALIGN ROW 6 INSIDE THE CORNERS';
          });
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
      if (mounted) {
        setState(() => _capturing = false);
        final activeController = _controller;
        if (!_disposed &&
            activeController != null &&
            activeController.value.isInitialized &&
            Navigator.of(context).canPop()) {
          unawaited(
            _startLiveDetection(
              activeController,
              generation: _cameraLifecycle.currentGeneration,
            ),
          );
        }
      }
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
    final cameraReady =
        controller != null && controller.value.isInitialized && !_disposed;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : _error != null || !cameraReady
          ? _ErrorState(
              message: _error ?? 'Camera unavailable.',
              onRetry: _initialize,
              onCancel: () => Navigator.of(context).pop(),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onScaleStart: (_) => _baseZoom = _zoom,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _CoverCameraPreview(controller: controller),
                      ArcBlueprintLiveTargetingOverlay(
                        detection: _lastDetection,
                        isLocked: _stableLiveLock,
                        isBottomCapture: _capturingBottom,
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        top: MediaQuery.paddingOf(context).top + 6,
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
                                    _capturingBottom
                                        ? 'CAPTURE ROWS 6–8 + FINAL 3'
                                        : 'LIVE BLUEPRINT SCANNER',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'VT323',
                                      fontSize: 22,
                                    ),
                                  ),
                                  Text(
                                    _capturingBottom
                                        ? 'Start at row 6. Include rows 6–8 and the final three slots only.'
                                        : 'The scanner automatically locks rows 1–5.',
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
                                      () => _debugDetection = !_debugDetection,
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
                      Positioned(
                        left: 16,
                        right: 16,
                        top: MediaQuery.paddingOf(context).top + 78,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _stableLiveLock
                                    ? Colors.greenAccent
                                    : AppTheme.neonCyan,
                              ),
                            ),
                            child: Text(
                              _lockMessage,
                              style: TextStyle(
                                color: _stableLiveLock
                                    ? Colors.greenAccent
                                    : Colors.white,
                                fontFamily: 'VT323',
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_capturingBottom)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: MediaQuery.paddingOf(context).bottom + 102,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
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
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: MediaQuery.paddingOf(context).bottom + 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_capturingBottom)
                              IconButton.filledTonal(
                                tooltip: 'Restart top capture',
                                onPressed: _capturing
                                    ? null
                                    : () => setState(
                                        () => _captureSession =
                                            const ArcBlueprintDualCaptureSession(),
                                      ),
                                icon: const Icon(Icons.restart_alt),
                              ),
                            if (_capturingBottom) const SizedBox(width: 16),
                            InkResponse(
                              key: const Key('blueprint-live-scanner-capture'),
                              onTap: _capturing || !_stableLiveLock
                                  ? null
                                  : _capture,
                              radius: 44,
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _capturing || !_stableLiveLock
                                      ? Colors.white38
                                      : Colors.white,
                                  border: Border.all(
                                    color: AppTheme.neonCyan,
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
                                        color: Colors.black,
                                        size: 34,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
    if (!controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }

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
