import 'dart:typed_data';

class ArcBlueprintDualCaptureSession {
  const ArcBlueprintDualCaptureSession({
    this.topImageBytes,
    this.bottomImageBytes,
  });

  final Uint8List? topImageBytes;
  final Uint8List? bottomImageBytes;

  bool get hasTop => topImageBytes != null && topImageBytes!.isNotEmpty;
  bool get hasBottom =>
      bottomImageBytes != null && bottomImageBytes!.isNotEmpty;
  bool get isComplete => hasTop && hasBottom;

  ArcBlueprintDualCaptureSession captureTop(Uint8List bytes) {
    return ArcBlueprintDualCaptureSession(
      topImageBytes: Uint8List.fromList(bytes),
      bottomImageBytes: bottomImageBytes == null
          ? null
          : Uint8List.fromList(bottomImageBytes!),
    );
  }

  ArcBlueprintDualCaptureSession captureBottom(Uint8List bytes) {
    return ArcBlueprintDualCaptureSession(
      topImageBytes: topImageBytes == null
          ? null
          : Uint8List.fromList(topImageBytes!),
      bottomImageBytes: Uint8List.fromList(bytes),
    );
  }

  ArcBlueprintDualCaptureSession clearTop() {
    return ArcBlueprintDualCaptureSession(
      bottomImageBytes: bottomImageBytes == null
          ? null
          : Uint8List.fromList(bottomImageBytes!),
    );
  }

  ArcBlueprintDualCaptureSession clearBottom() {
    return ArcBlueprintDualCaptureSession(
      topImageBytes: topImageBytes == null
          ? null
          : Uint8List.fromList(topImageBytes!),
    );
  }
}
