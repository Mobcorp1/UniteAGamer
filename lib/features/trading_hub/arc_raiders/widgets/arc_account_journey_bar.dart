import 'package:flutter/material.dart';

import 'foundation/arc_ui_tokens.dart';

enum ArcAccountJourneyStage { access, onboarding, profile }

class ArcAccountJourneyBar extends StatelessWidget {
  const ArcAccountJourneyBar({
    super.key,
    required this.stage,
    this.compact = false,
  });

  final ArcAccountJourneyStage stage;
  final bool compact;

  static const _steps = <_JourneyStep>[
    _JourneyStep(
      stage: ArcAccountJourneyStage.access,
      label: 'ACCESS',
      icon: Icons.login_rounded,
    ),
    _JourneyStep(
      stage: ArcAccountJourneyStage.onboarding,
      label: 'INITIALISE',
      icon: Icons.tune_rounded,
    ),
    _JourneyStep(
      stage: ArcAccountJourneyStage.profile,
      label: 'PROFILE',
      icon: Icons.badge_outlined,
    ),
  ];

  int get _activeIndex => _steps.indexWhere((step) => step.stage == stage);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 360;
        final dense = compact || constraints.maxWidth < 520;
        final activeIndex = _activeIndex;

        return Semantics(
          label: 'UAG account journey',
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(dense ? 8 : 10),
            decoration: ArcUiTokens.surfaceDecoration(
              role: ArcSurfaceRole.raised,
              accent: ArcUiTokens.primaryAccent,
              borderOpacity: 0.18,
            ),
            child: vertical
                ? Column(
                    children: List.generate(
                      _steps.length,
                      (index) => Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _steps.length - 1 ? 0 : 6,
                        ),
                        child: _JourneySegment(
                          step: _steps[index],
                          index: index,
                          activeIndex: activeIndex,
                          dense: true,
                          expand: false,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      for (var index = 0; index < _steps.length; index++) ...[
                        Expanded(
                          child: _JourneySegment(
                            step: _steps[index],
                            index: index,
                            activeIndex: activeIndex,
                            dense: dense,
                            expand: true,
                          ),
                        ),
                        if (index != _steps.length - 1)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: dense ? 5 : 8,
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: dense ? 15 : 17,
                              color: index < activeIndex
                                  ? ArcUiTokens.primaryAccent.withValues(
                                      alpha: 0.72,
                                    )
                                  : ArcUiTokens.textDisabled,
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _JourneySegment extends StatelessWidget {
  const _JourneySegment({
    required this.step,
    required this.index,
    required this.activeIndex,
    required this.dense,
    required this.expand,
  });

  final _JourneyStep step;
  final int index;
  final int activeIndex;
  final bool dense;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final active = index == activeIndex;
    final complete = index < activeIndex;
    final accent = active
        ? ArcUiTokens.secondaryAccent
        : complete
        ? ArcUiTokens.primaryAccent
        : ArcUiTokens.textDisabled;

    final content = Container(
      height: dense ? 34 : 38,
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: active ? 0.13 : 0.055),
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusM),
        border: Border.all(
          color: accent.withValues(alpha: active ? 0.56 : 0.24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            complete ? Icons.check_rounded : step.icon,
            size: dense ? 15 : 17,
            color: accent,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              step.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArcUiTokens.label(
                color: active || complete
                    ? ArcUiTokens.textPrimary
                    : ArcUiTokens.textTertiary,
              ).copyWith(letterSpacing: 0.7),
            ),
          ),
        ],
      ),
    );

    return expand
        ? content
        : Align(alignment: Alignment.centerLeft, child: content);
  }
}

class _JourneyStep {
  const _JourneyStep({
    required this.stage,
    required this.label,
    required this.icon,
  });

  final ArcAccountJourneyStage stage;
  final String label;
  final IconData icon;
}
