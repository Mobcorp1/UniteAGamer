import 'dart:typed_data';

enum ArcBlueprintCaptureSection { top, bottom }

class ArcBlueprintPhotoCaptureDraft {
  const ArcBlueprintPhotoCaptureDraft({
    this.topImageBytes,
    this.bottomImageBytes,
    this.topFileName = '',
    this.bottomFileName = '',
    this.updatedAt,
  });

  final Uint8List? topImageBytes;
  final Uint8List? bottomImageBytes;
  final String topFileName;
  final String bottomFileName;
  final DateTime? updatedAt;

  bool get hasTop => topImageBytes != null && topImageBytes!.isNotEmpty;
  bool get hasBottom =>
      bottomImageBytes != null && bottomImageBytes!.isNotEmpty;
  bool get isComplete => hasTop && hasBottom;
  int get completedSections => (hasTop ? 1 : 0) + (hasBottom ? 1 : 0);

  ArcBlueprintPhotoCaptureDraft copyWith({
    Uint8List? topImageBytes,
    Uint8List? bottomImageBytes,
    String? topFileName,
    String? bottomFileName,
    bool clearTop = false,
    bool clearBottom = false,
    DateTime? updatedAt,
  }) {
    return ArcBlueprintPhotoCaptureDraft(
      topImageBytes: clearTop ? null : topImageBytes ?? this.topImageBytes,
      bottomImageBytes: clearBottom
          ? null
          : bottomImageBytes ?? this.bottomImageBytes,
      topFileName: clearTop ? '' : topFileName ?? this.topFileName,
      bottomFileName: clearBottom ? '' : bottomFileName ?? this.bottomFileName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
