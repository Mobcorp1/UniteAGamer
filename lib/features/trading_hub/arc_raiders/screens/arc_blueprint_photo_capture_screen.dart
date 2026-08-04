import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_pixel_analyzer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_capture_draft.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_photo_capture_session_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_review_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_grid_alignment_overlay.dart';
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

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2400,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) return;
      await _repository.saveSection(
        section: _activeSection,
        bytes: bytes,
        fileName: image.name,
      );
      if (!mounted) return;
      setState(() {
        _draft = _repository.current;
        if (_activeSection == ArcBlueprintCaptureSection.top) {
          _activeSection = ArcBlueprintCaptureSection.bottom;
        }
      });
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

  Future<void> _continueToReview() async {
    if (!_draft.isComplete || _busy) return;
    final topBytes = _draft.topImageBytes;
    final bottomBytes = _draft.bottomImageBytes;
    if (topBytes == null || bottomBytes == null) return;

    setState(() => _busy = true);
    try {
      const analyzer = ArcBlueprintPhotoPixelAnalyzer(columns: 10, rows: 5);
      final top = analyzer.analyze(bytes: topBytes, captureId: 'top');
      final bottom = analyzer.analyze(bytes: bottomBytes, captureId: 'bottom');
      if (!top.succeeded || !bottom.succeeded) {
        final message = [
          top.error,
          bottom.error,
        ].where((item) => item.isNotEmpty).join(' ');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }

      const engine = ArcBlueprintPhotoOccupancyEngine(columns: 10);
      final result = engine.classify(
        orderedBlueprintIds: ArcBlueprintSeedData.blueprints
            .map((blueprint) => blueprint.id)
            .toList(growable: false),
        topCapture: top.samples,
        bottomCapture: bottom.samples,
        bottomStartRow: 4,
        overlapRows: 1,
      );
      if (!mounted) return;
      final imported = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ArcBlueprintPhotoReviewScreen(
            initialDecisions: result.decisions,
            analysisWarnings: result.errors,
          ),
        ),
      );
      if (imported == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _stepTitle => _activeSection == ArcBlueprintCaptureSection.top
      ? 'Capture the top of your grid'
      : 'Capture the bottom of your grid';

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
                  ? 'Align the first five rows of the in-game grid with the frame. The importer only checks whether each fixed slot is filled or empty.'
                  : 'Scroll down so the first visible row matches the final row from your top capture, then align the final five rows.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            AspectRatio(
              aspectRatio: 10 / 5,
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
                    ArcBlueprintGridAlignmentOverlay(
                      columns: 10,
                      rows: 5,
                      isAligned: bytes != null,
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
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
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
              onSelect: (section) => setState(() => _activeSection = section),
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
                    ? 'Privacy: photos are held only for this import session and are analysed locally. Review every uncertain result before applying. Duplicate counts are never read or changed.'
                    : 'This device uses screenshot upload rather than direct camera capture. Images are analysed locally and cleared after a confirmed import. Duplicate counts are never changed.',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('blueprint-import-continue'),
              onPressed: complete && !_busy ? _continueToReview : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue to Review'),
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
    required this.onSelect,
    required this.onRetake,
  });

  final ArcBlueprintPhotoCaptureDraft draft;
  final ValueChanged<ArcBlueprintCaptureSection> onSelect;
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
                onTap: () => onSelect(section),
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
                        onPressed: () => onRetake(section),
                        icon: const Icon(Icons.refresh),
                      )
                    : const Icon(Icons.chevron_right),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
