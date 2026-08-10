import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_camera_operation_queue.dart';

class ArcCameraDiagnosticScreen extends StatefulWidget {
  const ArcCameraDiagnosticScreen({super.key});

  @override
  State<ArcCameraDiagnosticScreen> createState() =>
      _ArcCameraDiagnosticScreenState();
}

class _ArcCameraDiagnosticScreenState extends State<ArcCameraDiagnosticScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _description;
  bool _initializing = true;
  bool _capturing = false;
  String? _error;
  String? _lastCapturePath;
  final ArcCameraOperationQueue _cameraOperations = ArcCameraOperationQueue();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('ARC CAMERA DIAG: $message');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    unawaited(_initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    _log('Lifecycle $state');

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _log('Transient lifecycle state ignored for camera ownership');
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_pauseCamera());
      return;
    }

    if (state == AppLifecycleState.resumed &&
        _controller == null &&
        _description != null) {
      unawaited(
        _cameraOperations.run<void>(
          () => _initializeUnlocked(description: _description),
        ),
      );
    }
  }

  Future<void> _pauseCamera() {
    return _cameraOperations.run<void>(_pauseCameraUnlocked);
  }

  Future<void> _pauseCameraUnlocked() async {
    final controller = _controller;
    if (controller == null) return;

    if (mounted) {
      setState(() => _controller = null);
      await WidgetsBinding.instance.endOfFrame;
    } else {
      _controller = null;
    }

    await _disposeController(controller);
  }

  Future<void> _disposeController(CameraController controller) async {
    try {
      await controller.dispose();
      _log('Controller disposed');
    } catch (error) {
      _log('Controller dispose error: $error');
    }
  }

  Future<void> _initialize({CameraDescription? description}) {
    return _cameraOperations.run<void>(
      () => _initializeUnlocked(description: description),
    );
  }

  Future<void> _initializeUnlocked({CameraDescription? description}) async {
    if (!mounted) return;

    setState(() {
      _initializing = true;
      _error = null;
      _lastCapturePath = null;
    });

    try {
      final cameras = description == null ? await availableCameras() : null;

      final selected =
          description ??
          cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );

      final previous = _controller;
      if (previous != null) {
        setState(() => _controller = null);
        await WidgetsBinding.instance.endOfFrame;
        await _disposeController(previous);
      }

      _log(
        'Creating controller '
        'name=${selected.name} '
        'lens=${selected.lensDirection} '
        'orientation=${selected.sensorOrientation}',
      );

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      controller.addListener(() {
        if (!mounted || !identical(_controller, controller)) return;

        if (controller.value.hasError) {
          final message =
              controller.value.errorDescription ?? 'Unknown camera error';
          _log('Controller error: $message');
          setState(() => _error = message);
        }
      });

      await controller.initialize();

      if (!mounted) {
        await _disposeController(controller);
        return;
      }

      _log(
        'Controller initialized '
        'preview=${controller.value.previewSize} '
        'aspect=${controller.value.aspectRatio} '
        'exposure=${controller.value.exposureMode} '
        'focus=${controller.value.focusMode}',
      );

      setState(() {
        _description = selected;
        _controller = controller;
        _initializing = false;
      });
    } on CameraException catch (error) {
      _log('CameraException ${error.code}: ${error.description}');
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = '${error.code}: ${error.description ?? 'Camera error'}';
      });
    } on PlatformException catch (error) {
      _log('PlatformException ${error.code}: ${error.message}');
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = '${error.code}: ${error.message ?? 'Platform error'}';
      });
    } catch (error, stackTrace) {
      _log('Unexpected initialization error: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.hasError ||
        controller.value.isTakingPicture ||
        _capturing) {
      return;
    }

    setState(() {
      _capturing = true;
      _error = null;
    });

    try {
      _log('Capture requested');
      final photo = await controller.takePicture();
      _log('Capture success: ${photo.path}');

      if (mounted) {
        setState(() => _lastCapturePath = photo.path);
      }
    } on CameraException catch (error) {
      _log('Capture CameraException ${error.code}: ${error.description}');
      if (mounted) {
        setState(() {
          _error = '${error.code}: ${error.description ?? 'Capture failed'}';
        });
      }
    } on PlatformException catch (error) {
      _log('Capture PlatformException ${error.code}: ${error.message}');
      if (mounted) {
        setState(() {
          _error = '${error.code}: ${error.message ?? 'Capture failed'}';
        });
      }
    } catch (error, stackTrace) {
      _log('Capture unexpected error: $error\n$stackTrace');
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null && controller.value.isInitialized)
              CameraPreview(controller)
            else
              const ColoredBox(color: Colors.black),
            Positioned(
              left: 12,
              top: 12,
              child: IconButton.filledTonal(
                tooltip: 'Close diagnostic',
                onPressed: _capturing
                    ? null
                    : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: IconButton.filledTonal(
                tooltip: 'Restart camera',
                onPressed: _capturing
                    ? null
                    : () => _initialize(description: _description),
                icon: const Icon(Icons.refresh),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'MINIMAL CAMERA DIAGNOSTIC',
                                style: TextStyle(
                                  fontFamily: 'VT323',
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _initializing
                                    ? 'Initializing camera...'
                                    : controller == null
                                    ? 'No controller'
                                    : 'Initialized: ${controller.value.isInitialized}  '
                                          'Error: ${controller.value.hasError}  '
                                          'Preview: ${controller.value.previewSize ?? 'unknown'}',
                              ),
                              if (_description != null)
                                Text(
                                  'Camera: ${_description!.name}  '
                                  '${_description!.lensDirection}  '
                                  'Sensor: ${_description!.sensorOrientation}°',
                                ),
                              if (_lastCapturePath != null)
                                Text(
                                  'Last capture: $_lastCapturePath',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (_error != null)
                                Text(
                                  'ERROR: $_error',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed:
                            controller != null &&
                                controller.value.isInitialized &&
                                !controller.value.hasError &&
                                !_capturing
                            ? _capture
                            : null,
                        icon: _capturing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.camera_alt),
                        label: Text(_capturing ? 'CAPTURING' : 'CAPTURE'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
