import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_capture_draft.dart';

class ArcBlueprintPhotoCaptureSessionRepository {
  ArcBlueprintPhotoCaptureSessionRepository._();

  static final ArcBlueprintPhotoCaptureSessionRepository instance =
      ArcBlueprintPhotoCaptureSessionRepository._();

  static const _metadataKey = 'arc_blueprint_photo_capture_draft_v1';

  ArcBlueprintPhotoCaptureDraft _draft = const ArcBlueprintPhotoCaptureDraft();

  ArcBlueprintPhotoCaptureDraft get current => _draft;

  Future<ArcBlueprintPhotoCaptureDraft> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_metadataKey);
    if (raw == null || raw.isEmpty) return _draft;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _draft = ArcBlueprintPhotoCaptureDraft(
        topImageBytes: _draft.topImageBytes,
        bottomImageBytes: _draft.bottomImageBytes,
        topFileName: map['topFileName'] as String? ?? '',
        bottomFileName: map['bottomFileName'] as String? ?? '',
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      );
    } catch (_) {
      await preferences.remove(_metadataKey);
    }
    return _draft;
  }

  Future<void> saveSection({
    required ArcBlueprintCaptureSection section,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final now = DateTime.now();
    _draft = switch (section) {
      ArcBlueprintCaptureSection.top => _draft.copyWith(
        topImageBytes: bytes,
        topFileName: fileName,
        updatedAt: now,
      ),
      ArcBlueprintCaptureSection.bottom => _draft.copyWith(
        bottomImageBytes: bytes,
        bottomFileName: fileName,
        updatedAt: now,
      ),
    };
    await _saveMetadata();
  }

  Future<void> clearSection(ArcBlueprintCaptureSection section) async {
    _draft = switch (section) {
      ArcBlueprintCaptureSection.top => _draft.copyWith(
        clearTop: true,
        updatedAt: DateTime.now(),
      ),
      ArcBlueprintCaptureSection.bottom => _draft.copyWith(
        clearBottom: true,
        updatedAt: DateTime.now(),
      ),
    };
    await _saveMetadata();
  }

  Future<void> clear() async {
    _draft = const ArcBlueprintPhotoCaptureDraft();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_metadataKey);
  }

  Future<void> _saveMetadata() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _metadataKey,
      jsonEncode({
        'topFileName': _draft.topFileName,
        'bottomFileName': _draft.bottomFileName,
        'updatedAt': _draft.updatedAt?.toIso8601String(),
      }),
    );
  }
}
