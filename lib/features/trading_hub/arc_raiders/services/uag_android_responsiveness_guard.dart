import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Low-overhead Android stability guard for the UAG closed beta.
///
/// The October 19 ANR captured Flutter/Dart frames on the Android main thread,
/// but not a symbolicated Dart call site. This guard does not claim to identify
/// that call site or prevent all ANRs. It bounds the framework's retained image
/// cache and, with an opt-in dart-define, records frame and event-loop stalls
/// locally in Android logcat for evidence-led profiling.
///
/// No collection, blueprint, scanner, Firestore or advertising data is read.
class UagAndroidResponsivenessGuard with WidgetsBindingObserver {
  UagAndroidResponsivenessGuard._();

  static final UagAndroidResponsivenessGuard instance =
      UagAndroidResponsivenessGuard._();

  static const bool diagnosticsRequested = bool.fromEnvironment(
    'UAG_ANDROID_ANR_DIAGNOSTICS',
    defaultValue: false,
  );

  // 72 MiB leaves headroom for Flutter's raster surfaces / Android WebViews.
  // This is a conservative retention limit, not an overall memory limit.
  static const int retainedImageCacheLimitBytes = 72 * 1024 * 1024;
  static const int retainedImageCountLimit = 350;

  bool _installed = false;
  Timer? _heartbeat;
  Stopwatch? _clock;
  int _lastHeartbeatMs = 0;
  String _surface = 'unspecified';

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get diagnosticsEnabled => _android && diagnosticsRequested;

  /// Called immediately after WidgetsFlutterBinding.ensureInitialized().
  /// Idempotent across splash and authenticated app runApp calls.
  void install() {
    if (_installed || !_android) return;
    _installed = true;
    WidgetsBinding.instance.addObserver(this);

    // ImageCache limits apply to retained decoded images, never to the user's
    // persisted blueprint states or the live images currently on screen.
    final cache = PaintingBinding.instance.imageCache;
    if (cache.maximumSizeBytes > retainedImageCacheLimitBytes) {
      cache.maximumSizeBytes = retainedImageCacheLimitBytes;
    }
    if (cache.maximumSize > retainedImageCountLimit) {
      cache.maximumSize = retainedImageCountLimit;
    }

    if (!diagnosticsEnabled) return;
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    _clock = Stopwatch()..start();
    _lastHeartbeatMs = _clock!.elapsedMilliseconds;
    _heartbeat = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = _clock!.elapsedMilliseconds;
      final gap = now - _lastHeartbeatMs;
      _lastHeartbeatMs = now;
      if (UagAndroidFramePolicy.isEventLoopGap(gap)) {
        debugPrint('UAG_ANR_DIAG EVENT_LOOP_GAP_MS=$gap '
            'SURFACE=$_surface IMAGE_CACHE_BYTES='
            '${PaintingBinding.instance.imageCache.currentSizeBytes}');
      }
    });
    debugPrint('UAG_ANR_DIAG ENABLED image_cache_limit_bytes='
        '$retainedImageCacheLimitBytes image_count_limit='
        '$retainedImageCountLimit');
  }

  /// Labels the active collections surface without recording user data.
  /// Only emits/updates markers in opted-in diagnostic builds.
  void enterSurface(String surface) {
    if (!diagnosticsEnabled) return;
    _surface = surface;
    debugPrint('UAG_ANR_DIAG ENTER_SURFACE=$surface');
  }

  void exitSurface(String surface) {
    if (!diagnosticsEnabled) return;
    if (_surface == surface) {
      debugPrint('UAG_ANR_DIAG EXIT_SURFACE=$surface');
      _surface = 'unspecified';
    }
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final buildMs = timing.buildDuration.inMilliseconds;
      final rasterMs = timing.rasterDuration.inMilliseconds;
      if (UagAndroidFramePolicy.isSlowFrame(buildMs, rasterMs)) {
        debugPrint('UAG_ANR_DIAG SLOW_FRAME_BUILD_MS=$buildMs '
            'RASTER_MS=$rasterMs SURFACE=$_surface');
      }
    }
  }

  @override
  void didHaveMemoryPressure() {
    if (!_android) return;
    final cache = PaintingBinding.instance.imageCache;
    final before = cache.currentSizeBytes;
    // Drop retained keep-alive images on a real OS pressure signal. Flutter's
    // own framework also handles pressure; this action is safe and idempotent.
    cache.clear();
    if (diagnosticsEnabled) {
      debugPrint('UAG_ANR_DIAG MEMORY_PRESSURE cache_bytes_before=$before '
          'cache_bytes_after=${cache.currentSizeBytes} SURFACE=$_surface');
    }
  }

  /// Useful for tests and app teardown; not called during ordinary navigation.
  void dispose() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _clock?.stop();
    _clock = null;
    if (_installed && _android) {
      if (diagnosticsEnabled) {
        SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
      }
      WidgetsBinding.instance.removeObserver(this);
    }
    _installed = false;
    _surface = 'unspecified';
  }
}

/// Pure timing thresholds, independently regression-testable without a device.
class UagAndroidFramePolicy {
  const UagAndroidFramePolicy._();

  static const int slowFrameThresholdMs = 100;
  static const int eventLoopGapThresholdMs = 2500;

  static bool isSlowFrame(int buildMs, int rasterMs) =>
      buildMs >= slowFrameThresholdMs || rasterMs >= slowFrameThresholdMs;

  static bool isEventLoopGap(int elapsedMs) =>
      elapsedMs >= eventLoopGapThresholdMs;
}
