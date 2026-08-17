import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_automatic_grid_selector.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_detector.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_occupancy_stabilizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_scan_flow_controller.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_scan_result_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_section_grid_extractor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_dual_capture_session.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/manual_alignment_controller.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_perspective_cropper.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_preview_frame_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_camera_session_policy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_camera_health_guard.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_camera_operation_queue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_camera_diagnostic_screen.dart';

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
    required this.decisions,
    required this.uncertainIgnoredCount,
  }) : topImageBytes = Uint8List.fromList(topImageBytes),
       bottomImageBytes = Uint8List.fromList(bottomImageBytes);

  final Uint8List topImageBytes;
  final Uint8List bottomImageBytes;
  final List<ArcBlueprintPhotoCellDecision> decisions;
  final int uncertainIgnoredCount;
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

  bool get _capturingBottom =>
      _liveScanFlow.phase == ArcBlueprintLiveScanPhase.bottomScanning ||
      _liveScanFlow.phase == ArcBlueprintLiveScanPhase.complete;

  bool get _gridLocked => _lockState == _BlueprintLockState.locked;

  // One persistent manual frame is shared by both captures. The in-game
  // panel stays in the same physical position when the user scrolls from the
  // top section to rows 6-9, so changing to a second default frame causes the
  // guide to jump smaller/lower between captures.
  final ManualAlignmentController _alignmentController =
      ManualAlignmentController()..resetToTopDefault();

  // Last known viewport size used for normalized->source coordinate mapping.
  Size? _viewportSize;

  bool _cameraInitializing = false;
  int _cameraRecoveryAttempts = 0;
  bool _previewStreamPending = false;
  bool _lifecycleTransitionInProgress = false;
  bool _cameraHealthy = false;
  bool _controllerErrorRecoveryInFlight = false;
  DateTime? _controllerReadyAt;
  final ArcCameraOperationQueue _cameraOperations = ArcCameraOperationQueue();

  final ArcBlueprintCameraHealthGuard _cameraHealthGuard =
      const ArcBlueprintCameraHealthGuard(
        minimumReadyAge: Duration(milliseconds: 900),
      );

  bool get _liveAnalysisEnabled =>
      arcBlueprintLiveAnalysisEnabled(defaultTargetPlatform);

  final ArcBlueprintPreviewFrameGate _previewFrameGate =
      ArcBlueprintPreviewFrameGate(
        minimumInterval: const Duration(milliseconds: 250),
      );
  int _previewFramesSeen = 0;
  int _previewFramesProcessed = 0;
  int _previewFramesDropped = 0;
  DateTime _lastPreviewStatsLog = DateTime.fromMillisecondsSinceEpoch(0);
  final ArcBlueprintLiveOccupancyEngine _liveOccupancyEngine =
      const ArcBlueprintLiveOccupancyEngine();
  final ArcBlueprintLiveOccupancyStabilizer _liveOccupancyStabilizer =
      ArcBlueprintLiveOccupancyStabilizer();
  ArcBlueprintLiveOccupancySnapshot _liveOccupancySnapshot =
      const ArcBlueprintLiveOccupancySnapshot.empty();
  final ArcBlueprintLiveScanFlowController _liveScanFlow =
      ArcBlueprintLiveScanFlowController();
  bool _autoCompletingLiveSection = false;
  DateTime? _lastLiveOccupancyAnalysisAt;
  static const Duration _liveOccupancyInterval = Duration(milliseconds: 650);

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('ARC SCANNER: $message');
    }
  }

  bool _isCameraDeviceError(CameraException error) {
    return error.code == 'ERROR_CAMERA_DEVICE' ||
        error.description?.contains('ERROR_CAMERA_DEVICE') == true;
  }

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

    // Detach widget ownership synchronously before the asynchronous platform
    // disposal begins. This prevents CameraPreview from rebuilding against a
    // controller that is already being disposed.
    final controller = _controller;
    _controller = null;

    if (controller != null) {
      unawaited(
        _cameraOperations.run<void>(() => _disposeController(controller)),
      );
    }

    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _debugLog('Lifecycle $state');

    // Android can emit transient inactive/hidden states while camera surfaces,
    // system overlays, navigation and focus are changing. Disposing the native
    // Camera2 session during those transient states races the plugin's own
    // onClosed callback. Only tear down when the app is genuinely paused or
    // detached.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _debugLog('Lifecycle transient state ignored for camera ownership');
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_pauseCameraForLifecycle());
      return;
    }

    if (state == AppLifecycleState.resumed && _description != null) {
      unawaited(_resumeCameraForLifecycle());
    }
  }

  Future<void> _pauseCameraForLifecycle() {
    return _cameraOperations.run<void>(_pauseCameraForLifecycleUnlocked);
  }

  Future<void> _pauseCameraForLifecycleUnlocked() async {
    if (_lifecycleTransitionInProgress) return;

    final controller = _controller;
    if (controller == null) return;

    _lifecycleTransitionInProgress = true;
    try {
      _debugLog('Lifecycle pause/detach preview');

      if (mounted) {
        setState(() {
          if (identical(_controller, controller)) {
            _controller = null;
          }
        });

        // Give Flutter one frame to remove CameraPreview before the native
        // controller tears down its preview surface.
        await WidgetsBinding.instance.endOfFrame;
      } else if (identical(_controller, controller)) {
        _controller = null;
      }

      _debugLog('Lifecycle disposing detached controller');
      await _disposeController(controller);
    } finally {
      _lifecycleTransitionInProgress = false;
    }
  }

  Future<void> _resumeCameraForLifecycle() {
    return _cameraOperations.run<void>(() async {
      if (_lifecycleTransitionInProgress ||
          _controller != null ||
          _cameraInitializing ||
          !mounted) {
        return;
      }

      _debugLog('Lifecycle resume/reinitialize controller');
      await _initializeUnlocked(description: _description);
    });
  }

  Future<void> _disposeController(CameraController? controller) async {
    if (controller == null) return;
    if (controller.value.isStreamingImages) {
      try {
        _debugLog('Image stream stopping before dispose');
        await controller.stopImageStream();
        _debugLog('Image stream stopped before dispose');
      } on CameraException catch (_) {
        _debugLog('Image stream stop failed during dispose');
      }
    }

    try {
      await controller.dispose();
      _cameraHealthy = false;
      _controllerReadyAt = null;
      _debugLog('Controller disposed');
    } on CameraException catch (_) {
      _debugLog('Controller dispose failed');
    }
  }

  Future<void> _initialize({CameraDescription? description}) {
    return _cameraOperations.run<void>(
      () => _initializeUnlocked(description: description),
    );
  }

  Future<void> _initializeUnlocked({CameraDescription? description}) async {
    if (_cameraInitializing) {
      _debugLog('Camera initialization already in progress; skipping');
      return;
    }

    _cameraInitializing = true;
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

      if (_controller != null) {
        _debugLog('Disposing previous controller during initialization');
        await _disposeController(_controller);
        _controller = null;
      }

      _debugLog('Controller created');
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      controller.addListener(() {
        if (!mounted || !identical(_controller, controller)) {
          return;
        }

        if (controller.value.hasError) {
          final description =
              controller.value.errorDescription ?? 'Unknown camera error';
          _debugLog('Controller reported error: $description');

          _cameraHealthy = false;
          _controllerReadyAt = null;

          if (!_controllerErrorRecoveryInFlight &&
              _cameraRecoveryAttempts == 0) {
            _controllerErrorRecoveryInFlight = true;
            _cameraRecoveryAttempts += 1;
            unawaited(_recoverFromControllerError(controller));
          }
        }
      });

      await controller.initialize();
      _debugLog('Controller initialised');
      await controller.setFlashMode(FlashMode.off);
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      if (!mounted) {
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
        _cameraHealthy = !controller.value.hasError;
        _controllerReadyAt = DateTime.now();
      });

      if (_liveAnalysisEnabled) {
        _schedulePreviewStreamStart(controller);
      } else {
        _debugLog(
          'Live ImageAnalysis is unavailable on this platform; '
          'Preview + ImageCapture remain active',
        );
      }
    } on CameraException catch (error) {
      if (!mounted) return;
      _handleCameraException(error);
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
    } finally {
      _cameraInitializing = false;
    }
  }

  void _handleCameraException(CameraException error) {
    if (!mounted) return;
    final errorMessage = error.description ?? error.code;
    _debugLog('Camera exception: $errorMessage');

    if (_isCameraDeviceError(error) && _cameraRecoveryAttempts == 0) {
      _cameraRecoveryAttempts += 1;
      _debugLog('CameraX recovery');
      unawaited(_recoverCameraSession());
    }

    setState(() {
      _initializing = false;
      _error = errorMessage;
    });
  }

  Future<void> _schedulePreviewStreamStart(CameraController controller) async {
    if (!_liveAnalysisEnabled) return;
    if (_previewStreamPending) return;
    _previewStreamPending = true;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) {
      _previewStreamPending = false;
      return;
    }
    if (_controller != controller) {
      _previewStreamPending = false;
      return;
    }
    _debugLog('Preview attached; starting image stream after delay');
    _previewStreamPending = false;
    await _startPreviewStream();
  }

  Future<void> _recoverCameraSession() {
    return _cameraOperations.run<void>(_recoverCameraSessionUnlocked);
  }

  Future<void> _recoverCameraSessionUnlocked() async {
    if (!mounted) return;
    _debugLog('Recovering camera session');
    _cameraHealthy = false;
    _controllerReadyAt = null;
    final description = _description;
    final activeController = _controller;

    if (activeController != null) {
      if (mounted) {
        setState(() {
          if (identical(_controller, activeController)) {
            _controller = null;
          }
        });
        await WidgetsBinding.instance.endOfFrame;
      } else if (identical(_controller, activeController)) {
        _controller = null;
      }

      await _disposeController(activeController);
    }

    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await _initializeUnlocked(description: description);
  }

  Future<void> _recoverFromControllerError(
    CameraController failedController,
  ) async {
    try {
      if (!mounted || !identical(_controller, failedController)) {
        return;
      }

      _debugLog('Recovering from Camera2 controller error');
      await _recoverCameraSession();
    } finally {
      _controllerErrorRecoveryInFlight = false;
    }
  }

  Future<void> _startPreviewStream() async {
    if (!_liveAnalysisEnabled) return;

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;
    if (_previewStreamPending) return;

    try {
      _previewFrameGate.reset();
      _previewFramesSeen = 0;
      _previewFramesProcessed = 0;
      _previewFramesDropped = 0;
      _lastPreviewStatsLog = DateTime.now();
      _debugLog('Image stream starting');
      await controller.startImageStream(_processPreviewFrame);
      _debugLog('Image stream started');
    } on CameraException catch (error) {
      _debugLog('Image stream failed: ${error.description ?? error.code}');
      if (_isCameraDeviceError(error) && _cameraRecoveryAttempts == 0) {
        _cameraRecoveryAttempts += 1;
        _debugLog('CameraX recovery from stream failure');
        unawaited(_recoverCameraSession());
      }
      // Ignore preview streaming errors and continue with capture-only mode.
    }
  }

  Future<void> _stopPreviewStream() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (!controller.value.isStreamingImages) return;

    try {
      _debugLog('Image stream stopping');
      await controller.stopImageStream();
      _previewFrameGate.reset();
      _debugLog(
        'Image stream stopped '
        '(seen=$_previewFramesSeen processed=$_previewFramesProcessed '
        'dropped=$_previewFramesDropped)',
      );
    } on CameraException catch (error) {
      _debugLog('Image stream stop failed: ${error.description ?? error.code}');
      // Ignore if the stream is already stopped.
    }
  }

  void _processPreviewFrame(CameraImage image) {
    _previewFramesSeen += 1;

    if (_capturing || _analyzingPreview || !mounted) {
      _previewFramesDropped += 1;
      _logPreviewStatsIfDue();
      return;
    }

    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    if (!_previewFrameGate.shouldProcess(nowMicros)) {
      _previewFramesDropped += 1;
      _logPreviewStatsIfDue();
      return;
    }

    _analyzingPreview = true;
    final stopwatch = Stopwatch()..start();

    try {
      final detectionRows = _capturingBottom ? 3 : 5;
      final frameImage = _convertCameraImage(image);
      if (frameImage == null) {
        _previewFramesDropped += 1;
        return;
      }

      final detection = ArcBlueprintGridDetector(
        columns: 10,
        rows: detectionRows,
        analysisWidth: 320,
      ).detectImage(frameImage);

      _previewFramesProcessed += 1;
      _updateLockState(detection);

      if (detection.isLocked) {
        _processLiveOccupancy(frameImage, detection);
      }
    } finally {
      stopwatch.stop();
      _analyzingPreview = false;

      if (stopwatch.elapsedMilliseconds >= 100) {
        _debugLog(
          'Slow preview analysis: ${stopwatch.elapsedMilliseconds}ms '
          '${image.width}x${image.height} ${image.format.group.name}',
        );
      }
      _logPreviewStatsIfDue();
    }
  }

  void _processLiveOccupancy(
    img.Image frameImage,
    ArcBlueprintGridDetection detection,
  ) {
    if (_liveScanFlow.phase == ArcBlueprintLiveScanPhase.awaitingBottomScroll ||
        _liveScanFlow.phase == ArcBlueprintLiveScanPhase.complete) {
      return;
    }

    final now = DateTime.now();
    final last = _lastLiveOccupancyAnalysisAt;
    if (last != null && now.difference(last) < _liveOccupancyInterval) {
      return;
    }
    _lastLiveOccupancyAnalysisAt = now;

    final section = _capturingBottom
        ? ArcBlueprintGridSection.bottom
        : ArcBlueprintGridSection.top;
    final analysis = _liveOccupancyEngine.analyzeFrame(
      frameImage: frameImage,
      detection: detection,
      section: section,
      captureId: 'live-${now.microsecondsSinceEpoch}',
    );

    if (!analysis.succeeded) {
      _debugLog('Live occupancy unavailable: ${analysis.error}');
      return;
    }

    final snapshot = _liveOccupancyStabilizer.addFrame(analysis.samples);
    if (!mounted) return;

    setState(() {
      _liveOccupancySnapshot = snapshot;
    });

    _debugLog(
      'Live occupancy: '
      '${snapshot.stableCellCount}/${snapshot.totalCellCount} stable '
      'owned=${snapshot.ownedStableCount} '
      'missing=${snapshot.missingStableCount} '
      'uncertain=${snapshot.uncertainCellCount} '
      'confidence=${analysis.captureConfidence.toStringAsFixed(3)}',
    );

    if (snapshot.sectionStable && !_autoCompletingLiveSection) {
      _completeStableLiveSection(frameImage, snapshot);
    }
  }

  void _completeStableLiveSection(
    img.Image frameImage,
    ArcBlueprintLiveOccupancySnapshot snapshot,
  ) {
    if (_autoCompletingLiveSection || !snapshot.sectionStable || !mounted) {
      return;
    }
    _autoCompletingLiveSection = true;

    try {
      final frameBytes = Uint8List.fromList(
        img.encodeJpg(frameImage, quality: 92),
      );
      final transition = _liveScanFlow.acceptStableFrame(
        snapshot: snapshot,
        frameBytes: frameBytes,
      );
      if (!transition.accepted) return;

      _liveOccupancyStabilizer.reset();
      _lastLiveOccupancyAnalysisAt = null;

      if (transition.phase == ArcBlueprintLiveScanPhase.awaitingBottomScroll) {
        setState(() {
          _liveOccupancySnapshot =
              const ArcBlueprintLiveOccupancySnapshot.empty();
          _lockState = _BlueprintLockState.searching;
          _potentialLockTime = null;
          _latestDetection = const ArcBlueprintGridDetection.notFound();
        });
        _showMessage(
          'Rows 1-5 scanned. Scroll the in-game Blueprint list until Row 6 is at the top, then continue.',
        );
        return;
      }

      if (transition.phase == ArcBlueprintLiveScanPhase.complete) {
        final result = _liveScanFlow.result;
        if (result == null) return;
        const resultEngine = ArcBlueprintLiveScanResultEngine();
        final decisionResult = resultEngine.build(
          top: result.topSnapshot,
          bottom: result.bottomSnapshot,
        );
        if (!decisionResult.succeeded) {
          _showMessage(decisionResult.errors.join(' '));
          _restartLiveScan();
          return;
        }
        Navigator.of(context).pop(
          ArcBlueprintScannerResult(
            topImageBytes: result.topFrameBytes,
            bottomImageBytes: result.bottomFrameBytes,
            decisions: decisionResult.decisions,
            uncertainIgnoredCount: 0,
          ),
        );
      }
    } finally {
      _autoCompletingLiveSection = false;
    }
  }

  void _beginBottomLiveScan() {
    if (!_liveScanFlow.beginBottomSection()) return;
    _liveOccupancyStabilizer.reset();
    setState(() {
      _liveOccupancySnapshot = const ArcBlueprintLiveOccupancySnapshot.empty();
      _lastLiveOccupancyAnalysisAt = null;
      _lockState = _BlueprintLockState.searching;
      _potentialLockTime = null;
      _latestDetection = const ArcBlueprintGridDetection.notFound();
    });
  }

  void _restartLiveScan() {
    _liveScanFlow.restart();
    _liveOccupancyStabilizer.reset();
    setState(() {
      _liveOccupancySnapshot = const ArcBlueprintLiveOccupancySnapshot.empty();
      _lastLiveOccupancyAnalysisAt = null;
      _lockState = _BlueprintLockState.searching;
      _potentialLockTime = null;
      _latestDetection = const ArcBlueprintGridDetection.notFound();
    });
  }

  void _logPreviewStatsIfDue() {
    if (!kDebugMode) return;

    final now = DateTime.now();
    if (now.difference(_lastPreviewStatsLog) < const Duration(seconds: 2)) {
      return;
    }

    _lastPreviewStatsLog = now;
    _debugLog(
      'Preview stats: seen=$_previewFramesSeen '
      'processed=$_previewFramesProcessed '
      'dropped=$_previewFramesDropped '
      'streaming=${_controller?.value.isStreamingImages ?? false} '
      'analyzing=$_analyzingPreview',
    );
  }

  img.Image? _convertCameraImage(CameraImage image) {
    // Live detection does not need capture-resolution RGB conversion.
    // 360px keeps enough structure for grid lock while cutting per-frame
    // conversion work by roughly 75% versus the previous 720px path.
    const maxPreviewWidth = 360;
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

    if (image.format.group == ImageFormatGroup.nv21 &&
        image.planes.isNotEmpty) {
      final plane = image.planes.first;
      final bytes = plane.bytes;
      final yStride = plane.bytesPerRow;
      final yPlaneLength = yStride * srcHeight;
      final uvStride = srcWidth;
      final result = img.Image(width: targetWidth, height: targetHeight);

      for (var y = 0; y < targetHeight; y++) {
        final sourceY = (y * scale).floor().clamp(0, srcHeight - 1);
        for (var x = 0; x < targetWidth; x++) {
          final sourceX = (x * scale).floor().clamp(0, srcWidth - 1);
          final yIndex = (sourceY * yStride) + sourceX;
          final uvIndex =
              yPlaneLength + ((sourceY ~/ 2) * uvStride) + ((sourceX ~/ 2) * 2);

          if (yIndex >= bytes.length || uvIndex + 1 >= bytes.length) {
            continue;
          }

          final yValue = bytes[yIndex];
          final vValue = bytes[uvIndex];
          final uValue = bytes[uvIndex + 1];
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

  // PASS 348 keeps the still-capture implementation as a recovery fallback for
  // PASS 349 integration, but normal scanner UX never invokes it.
  // ignore: unused_element
  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.hasError || !_cameraHealthy) {
      _showMessage('Camera is recovering. Please wait a moment and retry.');
      if (!_controllerErrorRecoveryInFlight && _cameraRecoveryAttempts == 0) {
        _controllerErrorRecoveryInFlight = true;
        _cameraRecoveryAttempts += 1;
        unawaited(_recoverFromControllerError(controller));
      }
      return;
    }

    final remainingDelay = _cameraHealthGuard.remainingReadyDelay(
      readyAt: _controllerReadyAt,
      now: DateTime.now(),
    );

    if (remainingDelay > Duration.zero) {
      _debugLog(
        'Capture waiting ${remainingDelay.inMilliseconds}ms for Camera2 session',
      );
      await Future<void>.delayed(remainingDelay);
    }

    if (!mounted ||
        !identical(_controller, controller) ||
        !_cameraHealthGuard.canCapture(
          initialized: controller.value.isInitialized,
          hasError: controller.value.hasError,
          isTakingPicture: controller.value.isTakingPicture,
          capturing: _capturing,
          readyAt: _controllerReadyAt,
          now: DateTime.now(),
        )) {
      _showMessage('Camera is not ready yet. Please retry.');
      return;
    }

    setState(() {
      _capturing = true;
    });

    var didNavigateAway = false;

    try {
      _debugLog('Capture started');
      await _stopPreviewStream();

      if (!mounted ||
          !identical(_controller, controller) ||
          controller.value.hasError ||
          !controller.value.isInitialized) {
        throw CameraException(
          'cameraNotReady',
          'Camera session changed before capture.',
        );
      }

      final photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      final section = _capturingBottom
          ? ArcBlueprintGridSection.bottom
          : ArcBlueprintGridSection.top;

      // Use manual alignment calibration where possible as the authoritative crop.
      Uint8List corrected;
      try {
        final alignmentController = _alignmentController;
        if (_viewportSize != null && alignmentController.calibration.isValid) {
          final manuallyRectified = ArcBlueprintPerspectiveCropper().rectify(
            imageBytes: bytes,
            viewportSize: _viewportSize!,
            calibration: alignmentController.calibration,
            outputRows: section == ArcBlueprintGridSection.bottom ? 4 : 5,
          );

          try {
            final normalized = _selector.select(
              manuallyRectified,
              section: section,
            );
            corrected = normalized.imageBytes;
            _debugLog(
              'Post-capture grid normalized: '
              '${normalized.detection.confidence.toStringAsFixed(3)}',
            );
          } on FormatException catch (error) {
            corrected = manuallyRectified;
            _debugLog(
              'Post-capture normalization unavailable; using manual frame: '
              '${error.message}',
            );
          }
        } else {
          // Fallback to automatic selector when viewport not available
          final selection = _selector.select(bytes, section: section);
          corrected = selection.imageBytes;
        }
      } catch (_) {
        // If cropper fails, fallback to automatic selection
        final selection = _selector.select(bytes, section: section);
        corrected = selection.imageBytes;
      }

      if (!mounted) return;

      if (!_capturingBottom) {
        final nextSession = _captureSession.captureTop(corrected);
        _liveOccupancyStabilizer.reset();
        _liveOccupancySnapshot =
            const ArcBlueprintLiveOccupancySnapshot.empty();
        _lastLiveOccupancyAnalysisAt = null;
        setState(() {
          _captureSession = nextSession;
          _lockState = _BlueprintLockState.searching;
          _potentialLockTime = null;
          _latestDetection = const ArcBlueprintGridDetection.notFound();
        });
        _showMessage(
          'Rows 1-5 captured. Scroll to row 6 for the second capture.',
        );
        if (mounted && _liveAnalysisEnabled) {
          await _startPreviewStream();
        }
        return;
      }

      final completed = _captureSession.captureBottom(corrected);
      final top = completed.topImageBytes;
      final bottom = completed.bottomImageBytes;
      if (top == null || bottom == null || !mounted) return;

      setState(() => _captureSession = completed);
      didNavigateAway = true;
      Navigator.of(context).pop(
        ArcBlueprintScannerResult(
          topImageBytes: top,
          bottomImageBytes: bottom,
          decisions: const <ArcBlueprintPhotoCellDecision>[],
          uncertainIgnoredCount: 0,
        ),
      );
    } on FormatException catch (error) {
      _showMessage(error.message);
    } on CameraException catch (error) {
      _cameraHealthy = false;
      _controllerReadyAt = null;
      _showMessage(error.description ?? error.code);

      if (_cameraRecoveryAttempts == 0) {
        _cameraRecoveryAttempts += 1;
        _debugLog('Camera2 recovery from capture failure');
        unawaited(_recoverCameraSession());
      }
    } on PlatformException catch (error) {
      _cameraHealthy = false;
      _controllerReadyAt = null;
      _debugLog(
        'Camera2 platform capture failure: ${error.code} ${error.message}',
      );
      _showMessage('Camera session reset. Please retry the photo.');

      if (_cameraRecoveryAttempts == 0) {
        _cameraRecoveryAttempts += 1;
        unawaited(_recoverCameraSession());
      }
    } catch (error) {
      _debugLog('Capture failure: $error');
      _showMessage('The Blueprint grid could not be captured. Please retry.');
    } finally {
      if (mounted) setState(() => _capturing = false);
      if (!didNavigateAway &&
          mounted &&
          controller == _controller &&
          controller.value.isInitialized &&
          !controller.value.isStreamingImages &&
          _liveAnalysisEnabled) {
        await _startPreviewStream();
      }
      _debugLog('Capture finished');
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
                final awaitingBottom =
                    _liveScanFlow.phase ==
                    ArcBlueprintLiveScanPhase.awaitingBottomScroll;
                final scanStep = _capturingBottom
                    ? 'Live scan - rows 6-9'
                    : awaitingBottom
                    ? 'Top section complete'
                    : 'Live scan - rows 1-5';
                final scanInstructions = awaitingBottom
                    ? 'Scroll the in-game Blueprint list until Row 6 is at the top, then continue. No photo is required.'
                    : 'Keep the complete outer edge of the Blueprint cell grid in view. UAG frames the grid automatically. No manual alignment or photo capture is required.';
                final liveOccupancySuffix =
                    _liveOccupancySnapshot.totalCellCount > 0
                    ? ' - Live ${_liveOccupancySnapshot.stableCellCount}/${_liveOccupancySnapshot.totalCellCount} stable'
                    : '';
                final lockStatusText = awaitingBottom
                    ? 'Rows 1-5 scanned - scroll to Row 6'
                    : _lockState == _BlueprintLockState.searching
                    ? 'Finding the outer Blueprint grid edges...'
                    : _lockState == _BlueprintLockState.detected
                    ? 'Blueprint grid found - framing edges...'
                    : 'Auto frame locked$liveOccupancySuffix';
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
                          child: IgnorePointer(
                            child: _BlueprintAutoFrameOverlay(
                              locked: _gridLocked,
                              detection: _latestDetection,
                            ),
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
                                      scanStep,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'VT323',
                                        fontSize: 22,
                                      ),
                                    ),
                                    Text(
                                      scanInstructions,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: 'Open minimal camera diagnostic',
                                onPressed: _capturing
                                    ? null
                                    : () async {
                                        await Navigator.of(context).push<void>(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const ArcCameraDiagnosticScreen(),
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.videocam_outlined),
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
                              'ROWS 1-5 SAVED - START AT ROW 6, NO DUPLICATE ROW',
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
                          child: Center(
                            child: awaitingBottom
                                ? FilledButton.icon(
                                    key: const Key(
                                      'blueprint-live-scanner-begin-bottom',
                                    ),
                                    onPressed: _beginBottomLiveScan,
                                    icon: const Icon(
                                      Icons.keyboard_double_arrow_down_rounded,
                                    ),
                                    label: const Text('SCAN ROWS 6-9'),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 184.0,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _gridLocked
                                            ? Colors.greenAccent
                                            : AppTheme.neonCyan,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _gridLocked
                                              ? Icons
                                                    .center_focus_strong_rounded
                                              : Icons.center_focus_weak_rounded,
                                          color: _gridLocked
                                              ? Colors.greenAccent
                                              : Colors.white70,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _liveOccupancySnapshot
                                                      .totalCellCount >
                                                  0
                                              ? 'AUTO SCANNING - ${_liveOccupancySnapshot.stableCellCount}/${_liveOccupancySnapshot.totalCellCount} STABLE'
                                              : 'AUTO FRAMING BLUEPRINT GRID',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'VT323',
                                            fontSize: 17,
                                          ),
                                        ),
                                        if (_capturingBottom) ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Restart live scan',
                                            onPressed: _restartLiveScan,
                                            icon: const Icon(
                                              Icons.restart_alt_rounded,
                                            ),
                                            color: Colors.white70,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
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

class _BlueprintAutoFrameOverlay extends StatelessWidget {
  const _BlueprintAutoFrameOverlay({
    required this.locked,
    required this.detection,
  });

  final bool locked;
  final ArcBlueprintGridDetection detection;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BlueprintAutoFramePainter(locked: locked, detection: detection),
      size: Size.infinite,
    );
  }
}

class _BlueprintAutoFramePainter extends CustomPainter {
  const _BlueprintAutoFramePainter({
    required this.locked,
    required this.detection,
  });

  final bool locked;
  final ArcBlueprintGridDetection detection;

  Offset _point(Offset normalized, Size size) =>
      Offset(normalized.dx * size.width, normalized.dy * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    if (!detection.isValid) return;

    final topLeft = _point(detection.topLeft, size);
    final topRight = _point(detection.topRight, size);
    final bottomRight = _point(detection.bottomRight, size);
    final bottomLeft = _point(detection.bottomLeft, size);

    final frame = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    final framePaint = Paint()
      ..color = locked ? Colors.greenAccent : AppTheme.neonCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = locked ? 3.5 : 2.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(frame, framePaint);

    final cornerPaint = Paint()
      ..color = locked ? Colors.greenAccent : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const length = 30.0;

    void bracket(Offset corner, Offset horizontal, Offset vertical) {
      canvas.drawLine(corner, corner + horizontal * length, cornerPaint);
      canvas.drawLine(corner, corner + vertical * length, cornerPaint);
    }

    bracket(topLeft, const Offset(1, 0), const Offset(0, 1));
    bracket(topRight, const Offset(-1, 0), const Offset(0, 1));
    bracket(bottomLeft, const Offset(1, 0), const Offset(0, -1));
    bracket(bottomRight, const Offset(-1, 0), const Offset(0, -1));
  }

  @override
  bool shouldRepaint(covariant _BlueprintAutoFramePainter oldDelegate) {
    return oldDelegate.locked != locked || oldDelegate.detection != detection;
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
    if (!detection.isValid) return '0.0 deg';
    final deltaX = detection.topRight.dx - detection.topLeft.dx;
    final deltaY = detection.topRight.dy - detection.topLeft.dy;
    return '${(math.atan2(deltaY, deltaX) * 180 / math.pi).abs().toStringAsFixed(1)} deg';
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
