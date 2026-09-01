import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

/// Full-screen loading treatment used while UAG resolves authentication,
/// session policy and onboarding state.
class UagCinematicLoadingScreen extends StatefulWidget {
  const UagCinematicLoadingScreen({super.key});

  @override
  State<UagCinematicLoadingScreen> createState() =>
      _UagCinematicLoadingScreenState();
}

class _UagCinematicLoadingScreenState extends State<UagCinematicLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0.35,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 700;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ArcTacticalPageBody(
        width: ArcPageWidth.form,
        scrollable: false,
        child: ArcTacticalPanel(
          title: 'UAG ARC RAIDERS HUB',
          subtitle: 'Initialising systems',
          icon: Icons.radar_rounded,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => Opacity(
                  opacity: _pulse.value,
                  child: Text(
                    'AUTH / SESSION / ONBOARDING',
                    textAlign: TextAlign.center,
                    style: AppTheme.tradingHeading(
                      fontSize: compact ? 11 : 13,
                      color: ArcUiTokens.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(ArcUiTokens.radiusS),
                child: SizedBox(
                  width: compact ? size.width * 0.72 : 380,
                  height: 6,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.black.withValues(alpha: 0.55),
                    color: AppTheme.neonCyan,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
