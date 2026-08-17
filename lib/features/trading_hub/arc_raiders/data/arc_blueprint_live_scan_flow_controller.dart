import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_occupancy_stabilizer.dart';

enum ArcBlueprintLiveScanPhase {
  topScanning,
  awaitingBottomScroll,
  bottomScanning,
  complete,
}

@immutable
class ArcBlueprintLiveScanTransition {
  const ArcBlueprintLiveScanTransition({
    required this.accepted,
    required this.phase,
  });

  final bool accepted;
  final ArcBlueprintLiveScanPhase phase;
}

@immutable
class ArcBlueprintLiveScanFramePair {
  ArcBlueprintLiveScanFramePair({
    required Uint8List topFrameBytes,
    required Uint8List bottomFrameBytes,
  }) : topFrameBytes = Uint8List.fromList(topFrameBytes),
       bottomFrameBytes = Uint8List.fromList(bottomFrameBytes);

  final Uint8List topFrameBytes;
  final Uint8List bottomFrameBytes;
}

class ArcBlueprintLiveScanFlowController {
  ArcBlueprintLiveScanPhase _phase = ArcBlueprintLiveScanPhase.topScanning;
  Uint8List? _topFrameBytes;
  Uint8List? _bottomFrameBytes;

  ArcBlueprintLiveScanPhase get phase => _phase;

  ArcBlueprintLiveScanFramePair? get result {
    final top = _topFrameBytes;
    final bottom = _bottomFrameBytes;
    if (_phase != ArcBlueprintLiveScanPhase.complete ||
        top == null ||
        bottom == null) {
      return null;
    }
    return ArcBlueprintLiveScanFramePair(
      topFrameBytes: top,
      bottomFrameBytes: bottom,
    );
  }

  ArcBlueprintLiveScanTransition acceptStableFrame({
    required ArcBlueprintLiveOccupancySnapshot snapshot,
    required Uint8List frameBytes,
  }) {
    if (!snapshot.sectionStable || frameBytes.isEmpty) {
      return ArcBlueprintLiveScanTransition(accepted: false, phase: _phase);
    }

    switch (_phase) {
      case ArcBlueprintLiveScanPhase.topScanning:
        _topFrameBytes = Uint8List.fromList(frameBytes);
        _phase = ArcBlueprintLiveScanPhase.awaitingBottomScroll;
        return ArcBlueprintLiveScanTransition(accepted: true, phase: _phase);
      case ArcBlueprintLiveScanPhase.bottomScanning:
        _bottomFrameBytes = Uint8List.fromList(frameBytes);
        _phase = ArcBlueprintLiveScanPhase.complete;
        return ArcBlueprintLiveScanTransition(accepted: true, phase: _phase);
      case ArcBlueprintLiveScanPhase.awaitingBottomScroll:
      case ArcBlueprintLiveScanPhase.complete:
        return ArcBlueprintLiveScanTransition(accepted: false, phase: _phase);
    }
  }

  bool beginBottomSection() {
    if (_phase != ArcBlueprintLiveScanPhase.awaitingBottomScroll ||
        _topFrameBytes == null) {
      return false;
    }
    _phase = ArcBlueprintLiveScanPhase.bottomScanning;
    return true;
  }

  void restart() {
    _phase = ArcBlueprintLiveScanPhase.topScanning;
    _topFrameBytes = null;
    _bottomFrameBytes = null;
  }
}
