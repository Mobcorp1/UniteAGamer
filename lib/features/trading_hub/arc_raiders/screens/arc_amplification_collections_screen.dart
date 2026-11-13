import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart' as uag_theme;
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_ad_service.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_collections_category_bar.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_additional_collections_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_tactical_banner_ad.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/amplification/arc_amplification_workspace.dart';

enum ArcAmplificationCollectionFilter { all, complete, stepOne, stepTwo, notStarted }

class ArcAmplificationCollectionsScreen extends StatefulWidget {
  const ArcAmplificationCollectionsScreen({super.key});

  @override
  State<ArcAmplificationCollectionsScreen> createState() =>
      _ArcAmplificationCollectionsScreenState();
}

class _ArcAmplificationCollectionsScreenState extends State<ArcAmplificationCollectionsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final ArcAmplificationRepository _repository = ArcAmplificationRepository();
  late final Stream<ArcAmplificationState> _state;
  ArcAmplificationCollectionFilter _filter = ArcAmplificationCollectionFilter.all;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _state = _repository.watch();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  static ArcAmplificationCollectionFilter status(
    ArcAmplificationProject project,
    ArcAmplificationState state,
  ) {
    if (state.completed.contains(project.id)) return ArcAmplificationCollectionFilter.complete;
    if (!state.active.contains(project.id)) return ArcAmplificationCollectionFilter.notStarted;
    return state.objectivesDone(project.id)
        ? ArcAmplificationCollectionFilter.stepTwo
        : ArcAmplificationCollectionFilter.stepOne;
  }

  static const Map<ArcAmplificationCollectionFilter, String> _labels = {
    ArcAmplificationCollectionFilter.all: 'ALL',
    ArcAmplificationCollectionFilter.complete: 'RESEARCH COMPLETE',
    ArcAmplificationCollectionFilter.stepOne: 'STEP 1',
    ArcAmplificationCollectionFilter.stepTwo: 'STEP 2',
    ArcAmplificationCollectionFilter.notStarted: 'NOT STARTED',
  };

  static String artworkName(ArcAmplificationProject project) {
    final id = project.id == 'magazine_geometry_101' ? 'magazine_geometry' : project.id;
    return 'assets/arc_raiders/blueprints/$id.webp';
  }

  Future<void> _openProject(ArcAmplificationProject project) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFF07111B),
          appBar: AppBar(title: Text(project.title)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: ArcAmplificationWorkspace(initialProjectId: project.id),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _update(
    ArcAmplificationState Function(ArcAmplificationState) change,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _repository.update(change);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Research progress could not be saved. Please try again.'),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return answer == true;
  }

  Future<void> _quickAction(ArcAmplificationProject project,
      ArcAmplificationCollectionFilter progress) async {
    if (_busy || progress == ArcAmplificationCollectionFilter.complete) return;
    if (progress == ArcAmplificationCollectionFilter.notStarted) {
      await _update((state) => state.start(project.id));
      return;
    }
    if (progress == ArcAmplificationCollectionFilter.stepOne) {
      if (await _confirm('Step 1 complete?',
          'Confirm you completed every Step 1 objective for ${project.title} in ARC Raiders. This records your in-game progress; it does not create materials or Research Points.')) {
        await _update((state) => state.confirmStepOneInGame(project.id));
      }
      return;
    }
    if (await _confirm('Research completed in-game?',
        'Confirm you finished Step 2 and unlocked ${project.title} in ARC Raiders. Tracked material quantities and Research Points will not be changed automatically.')) {
      await _update((state) => state.confirmResearchCompletedInGame(project.id));
    }
  }

  Future<void> _resetSelected(ArcAmplificationProject project) async {
    if (await _confirm('Reset ${project.title}?',
        'Clear this project\'s research stages, objectives and completion status? Shared Research Points and materials will be preserved.')) {
      await _update((state) => state.resetProject(project.id));
    }
  }

  Future<void> _resetAll() async {
    if (await _confirm('Reset all amplification research?',
        'Clear all 15 projects, including active research, completed research, and objective progress? Shared Research Points and material stock will be preserved.')) {
      await _update((state) => state.resetAllProjects());
    }
  }

  void _showActions(ArcAmplificationProject project, ArcAmplificationState state) {
    if (_busy) return;
    final progress = status(project, state);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF10212D),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        title: Text(project.title,
          style: const TextStyle(color: Color(0xFF64E8EF), fontSize: 19, fontWeight: FontWeight.bold)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Text(_labels[progress]!, style: const TextStyle(color: Colors.white70)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (progress != ArcAmplificationCollectionFilter.complete)
              FilledButton.icon(
                key: Key('amplification-advance-${project.id}'),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(switch (progress) {
                  ArcAmplificationCollectionFilter.notStarted => 'START RESEARCH',
                  ArcAmplificationCollectionFilter.stepOne => 'STEP 1 COMPLETE',
                  _ => 'RESEARCH COMPLETE',
                }),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _quickAction(project, progress);
                },
              ),
            OutlinedButton.icon(
              key: Key('amplification-details-${project.id}'),
              icon: const Icon(Icons.tune_outlined),
              label: const Text('OBJECTIVES, MATERIALS & RAID INTEL'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _openProject(project);
              },
            ),
            OutlinedButton.icon(
              key: Key('amplification-reset-${project.id}'),
              icon: const Icon(Icons.restart_alt),
              label: const Text('RESET SELECTED'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _resetSelected(project);
              },
            ),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CLOSE')),
          ]),
        ],
      ),
    );
  }

  Widget _projectTile(ArcAmplificationProject project, ArcAmplificationState state) {
    final progress = status(project, state);
    final statusColor = switch (progress) {
      ArcAmplificationCollectionFilter.complete => uag_theme.AppTheme.neonCyan,
      ArcAmplificationCollectionFilter.stepTwo => uag_theme.AppTheme.neonPink,
      ArcAmplificationCollectionFilter.stepOne => uag_theme.AppTheme.neonCyan,
      _ => const Color(0xFF536671),
    };
    final completed = progress == ArcAmplificationCollectionFilter.complete;
    return Material(
      color: const Color(0xFF10232D),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('amplification-project-${project.id}'),
        onTap: () => _showActions(project, state),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: progress == ArcAmplificationCollectionFilter.notStarted ? .34 : .95), width: progress == ArcAmplificationCollectionFilter.notStarted ? 1 : 1.5),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: progress == ArcAmplificationCollectionFilter.complete
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.matrix(<double>[
                        .2126, .7152, .0722, 0, 0,
                        .2126, .7152, .0722, 0, 0,
                        .2126, .7152, .0722, 0, 0,
                        0, 0, 0, 1, 0,
                      ]),
                child: Image.asset(
                  artworkName(project),
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (context, error, stack) => Container(
                    color: const Color(0xFF122633),
                    alignment: Alignment.center,
                    child: const Icon(Icons.science_outlined, size: 30,
                      color: Color(0xFF8397A2)),
                  ),
                ),
              ),
              if (progress == ArcAmplificationCollectionFilter.notStarted)
                const Positioned.fill(child: ColoredBox(color: Color(0x70030E17))),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xF008121B)],
                      stops: [.48, 1],
                    ),
                  ),
                ),
              ),
              if (progress == ArcAmplificationCollectionFilter.stepOne ||
                  progress == ArcAmplificationCollectionFilter.stepTwo)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) => CustomPaint(
                        painter: _AmplificationElectricEdgePainter(
                          progress: _pulse.value,
                          tint: statusColor,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 3, right: 3, bottom: 3,
                child: Text(
                  project.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 9,
                    height: 1.12, fontWeight: FontWeight.w800),
                ),
              ),
              Positioned(
                top: 3, right: 3,
                child: completed
                    ? Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10232D), shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle,
                          size: 16, color: Color(0xFF66F7E6)),
                      )
                    : Container(
                        width: 9, height: 9,
                        decoration: BoxDecoration(color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: statusColor.withValues(alpha: .5), blurRadius: 6)]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const Map<ArcAmplificationCollectionFilter, IconData> _icons = {
    ArcAmplificationCollectionFilter.all: Icons.apps_rounded,
    ArcAmplificationCollectionFilter.complete: Icons.check_circle_outline,
    ArcAmplificationCollectionFilter.stepOne: Icons.filter_1_outlined,
    ArcAmplificationCollectionFilter.stepTwo: Icons.filter_2_outlined,
    ArcAmplificationCollectionFilter.notStarted: Icons.help_outline_rounded,
  };

  // The filter dock doubles as a live legend for research progress.
  // In-progress categories carry the same animated electric hue as their tiles.
  Color _filterTint(ArcAmplificationCollectionFilter filter) => switch (filter) {
    ArcAmplificationCollectionFilter.all => uag_theme.AppTheme.neonCyan,
    ArcAmplificationCollectionFilter.complete => const Color(0xFF66F7E6),
    ArcAmplificationCollectionFilter.stepOne => uag_theme.AppTheme.neonCyan,
    ArcAmplificationCollectionFilter.stepTwo => uag_theme.AppTheme.neonPink,
    ArcAmplificationCollectionFilter.notStarted => const Color(0xFF8494A2),
  };

  Widget _filterButton(ArcAmplificationCollectionFilter filter) {
    final tint = _filterTint(filter);
    final selected = _filter == filter;
    final inProgress = filter == ArcAmplificationCollectionFilter.stepOne ||
        filter == ArcAmplificationCollectionFilter.stepTwo;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Tooltip(
          message: _labels[filter]!,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              // Only progress filters animate. Other statuses remain static.
              final strength = inProgress
                  ? .5 + .5 * math.sin(_pulse.value * math.pi * 2)
                  : 0.0;
              final borderOpacity = selected
                  ? .9 + .1 * strength
                  : inProgress ? .45 + .4 * strength : .38;
              return Container(
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: inProgress
                      ? [BoxShadow(
                          color: tint.withValues(alpha: (selected ? .26 : .10) * strength),
                          blurRadius: 5 + 7 * strength,
                          spreadRadius: selected ? .8 : 0,
                        )]
                      : null,
                ),
                child: OutlinedButton(
                  key: Key('amplification-filter-${filter.name}'),
                  onPressed: () => setState(() => _filter = filter),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    backgroundColor: selected
                        ? uag_theme.AppTheme.cardBackgroundAlt
                        : uag_theme.AppTheme.cardBackground,
                    foregroundColor: selected ? tint : tint.withValues(alpha: .76),
                    side: BorderSide(
                      color: tint.withValues(alpha: borderOpacity),
                      width: selected ? 1.6 : 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_icons[filter], size: 17),
                      const SizedBox(width: 4),
                      Text(_labels[filter]!, maxLines: 1,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static const _amplifyAdRoute = '/trading-hub/arc-raiders/amplification';

  String _adStatus() => UagAdService.instance
      .bannerBlockReasonForPlacement(_amplifyAdRoute) ?? 'AD READY';

  Widget _adLane() => AnimatedBuilder(
    animation: UagAdService.instance,
    builder: (context, _) => UagAdService.instance.canShowBannerForPlacement(_amplifyAdRoute)
        ? _eligibleAdLane()
        : SizedBox(
            width: 344,
            height: 74,
            child: Center(child: Text(
              _adStatus(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: .58)),
            )),
          ),
  );

  Widget _eligibleAdLane() => SizedBox(
    key: const Key('amplification-framed-ad'),
    height: 74,
    width: 344,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: IgnorePointer(child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF0E1F2A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A6877), width: 1),
          ),
        ))),
        const UagTacticalBannerAd(
          placementRoute: _amplifyAdRoute,
          margin: EdgeInsets.fromLTRB(2, 6, 2, 8),
        ),
      ],
    ),
  );

  Widget _bottomDock() => SafeArea(
    top: false,
    child: Container(
      key: const Key('amplification-collections-bottom-dock'),
      padding: const EdgeInsets.fromLTRB(7, 2, 7, 2),
      decoration: const BoxDecoration(
        color: Color(0xFF07111B),
        border: Border(top: BorderSide(color: Color(0xFF21606E))),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        // The 320px AdMob banner must never be scaled or clipped.
        if (constraints.maxWidth < 650) {
          return Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(height: 42, child: Row(children: [
              for (final filter in ArcAmplificationCollectionFilter.values)
                _filterButton(filter),
            ])),
            const SizedBox(height: 4),
            if (constraints.maxWidth >= 344) _adLane(),
          ]);
        }
        return SizedBox(height: 74, child: Row(children: [
          Expanded(child: Row(children: [
            _filterButton(ArcAmplificationCollectionFilter.all),
            _filterButton(ArcAmplificationCollectionFilter.complete),
          ])),
          const SizedBox(width: 6),
          _adLane(),
          const SizedBox(width: 6),
          Expanded(child: Row(children: [
            _filterButton(ArcAmplificationCollectionFilter.stepOne),
            _filterButton(ArcAmplificationCollectionFilter.stepTwo),
            _filterButton(ArcAmplificationCollectionFilter.notStarted),
          ])),
        ]));
      }),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: const Color(0xFF07111B),
      appBar: AppBar(
        toolbarHeight: 48,
        titleSpacing: 0,
        backgroundColor: const Color(0xFF07111B),
        actions: [
          PopupMenuButton<String>(
            key: const Key('amplification-menu'),
            icon: const Icon(Icons.menu),
            tooltip: 'Amplification options',
            onSelected: (value) {
              if (value == 'resetAll') _resetAll();
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(value: 'resetAll',
                child: Text('Reset all amplification progress')),
            ],
          ),
        ],
        title: Row(
          children: [
            Text('Collections Tracker', style: TextStyle(
              fontSize: screenWidth < 430 ? 17 : 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4CDDE8),
            )),
            const SizedBox(width: 18),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: ArcCollectionsCategoryBar(
                    selected: ArcCollectionsCategory.amplification,
                    onSelected: (category) {
                      if (category == ArcCollectionsCategory.blueprints) {
                        Navigator.of(context).pop();
                      } else if (category == ArcCollectionsCategory.stencils ||
                          category == ArcCollectionsCategory.designs) {
                        Navigator.of(context).pushReplacement<void, void>(
                          MaterialPageRoute<void>(
                            builder: (_) => ArcAdditionalCollectionsScreen(
                              initialKind: category == ArcCollectionsCategory.stencils
                                  ? ArcNativeCollectionKind.stencils
                                  : ArcNativeCollectionKind.designs,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomDock(),
      body: SafeArea(
        child: StreamBuilder<ArcAmplificationState>(
          stream: _state,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text(
                'Unable to sync amplification progress. Check your connection and account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ));
            }
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final state = snapshot.data!;
            final visible = ArcAmplificationCatalog.projects.where((project) =>
              _filter == ArcAmplificationCollectionFilter.all ||
              status(project, state) == _filter).toList();
            if (visible.isEmpty) {
              return const Center(child: Text('No research projects match this filter.',
                style: TextStyle(color: Colors.white70)));
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 650 ? 9 : width >= 380 ? 5 : 3;
                final tileWidth = (width - 20 - 6 * (columns - 1)) / columns;
                final rows = (visible.length / columns).ceil();
                final availableHeight = constraints.maxHeight - 16 - 6 * (rows - 1);
                final tileHeight = math.min(tileWidth * .98,
                    math.max(32.0, availableHeight / rows));
                return GridView.builder(
                  key: const Key('amplification-collections-image-grid'),
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visible.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    mainAxisExtent: tileHeight,
                  ),
                  itemBuilder: (context, index) => _projectTile(visible[index], state),
                );
              },
            );
          },
        ),
      ),
    );
  }
}


/// Moves short bright segments around the frame without affecting touch input.
/// Purely visual: research completion remains Firestore's source of truth.
class _AmplificationElectricEdgePainter extends CustomPainter {
  const _AmplificationElectricEdgePainter({required this.progress, required this.tint});
  final double progress;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 7 || size.height <= 7) return;
    final rect = Rect.fromLTWH(2.5, 2.5, size.width - 5, size.height - 5);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)));
    final metric = path.computeMetrics().first;
    final perimeter = metric.length;
    final paint = Paint()
      ..color = tint.withValues(alpha: .95)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < 4; i++) {
      final start = ((progress + i / 4) % 1) * perimeter;
      final length = perimeter * .075;
      final end = math.min(start + length, perimeter);
      canvas.drawPath(metric.extractPath(start, end), paint);
      if (end - start < length) {
        canvas.drawPath(metric.extractPath(0, length - (end - start)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AmplificationElectricEdgePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.tint != tint;
}
