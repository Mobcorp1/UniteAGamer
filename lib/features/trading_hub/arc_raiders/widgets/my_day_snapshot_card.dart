import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class MyDaySnapshotCard extends StatelessWidget {
  const MyDaySnapshotCard({
    super.key,
    this.activeObjective = 'Build the next clean trading route',
    this.sessionWindow = 'Tonight / next available run',
    this.resetLabel = 'Daily reset window',
    this.intelStatus = 'Check latest ARC intel before launch',
    this.tradeStatus = 'Review wanted blueprints and active offers',
    this.onOpenPlanner,
    this.onOpenIntel,
    this.onOpenTrades,
  });

  final String activeObjective;
  final String sessionWindow;
  final String resetLabel;
  final String intelStatus;
  final String tradeStatus;
  final VoidCallback? onOpenPlanner;
  final VoidCallback? onOpenIntel;
  final VoidCallback? onOpenTrades;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Container(
      padding: EdgeInsets.all(compact ? AppTheme.spaceM : AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        radius: 28,
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.28),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.88),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SnapshotHeader(compact: compact),
          const SizedBox(height: AppTheme.spaceM),
          _ObjectiveStrip(
            icon: Icons.track_changes_rounded,
            label: 'ACTIVE OBJECTIVE',
            value: activeObjective,
            accent: AppTheme.neonPink,
          ),
          const SizedBox(height: AppTheme.spaceS),
          _SnapshotGrid(
            compact: compact,
            children: [
              _SnapshotMetric(
                icon: Icons.schedule_rounded,
                label: 'SESSION',
                value: sessionWindow,
                accent: AppTheme.neonCyan,
              ),
              _SnapshotMetric(
                icon: Icons.restart_alt_rounded,
                label: 'RESET',
                value: resetLabel,
                accent: AppTheme.neonPink,
              ),
              _SnapshotMetric(
                icon: Icons.radar_rounded,
                label: 'INTEL',
                value: intelStatus,
                accent: AppTheme.neonCyan,
              ),
              _SnapshotMetric(
                icon: Icons.swap_horiz_rounded,
                label: 'TRADES',
                value: tradeStatus,
                accent: AppTheme.neonPink,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: AppTheme.spaceS,
            runSpacing: AppTheme.spaceS,
            children: [
              _CommandButton(
                label: 'Raid Planner',
                icon: Icons.map_rounded,
                onPressed: onOpenPlanner,
              ),
              _CommandButton(
                label: 'Latest Intel',
                icon: Icons.insights_rounded,
                onPressed: onOpenIntel,
              ),
              _CommandButton(
                label: 'Trade Board',
                icon: Icons.handshake_rounded,
                onPressed: onOpenTrades,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotHeader extends StatelessWidget {
  const _SnapshotHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 40 : 46,
          height: compact ? 40 : 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.neonCyan.withValues(alpha: 0.12),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.34),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.16),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.today_rounded,
            color: AppTheme.neonCyan,
            size: compact ? 22 : 25,
          ),
        ),
        const SizedBox(width: AppTheme.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Day Snapshot',
                style: AppTheme.tradingHeading(
                  fontSize: compact ? 20 : 24,
                  color: AppTheme.neonCyan,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                'Your next run, trade checks, intel status and daily ops in one command view.',
                style: AppTheme.bodyTextStyle(
                  fontSize: compact ? 12 : 13,
                  color: Colors.white70,
                  isBold: true,
                ).copyWith(height: 1.28),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ObjectiveStrip extends StatelessWidget {
  const _ObjectiveStrip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 11,
                    color: accent,
                    isBold: true,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    isBold: true,
                  ).copyWith(height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotGrid extends StatelessWidget {
  const _SnapshotGrid({required this.compact, required this.children});

  final bool compact;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: [
          for (final child in children) ...[
            child,
            if (child != children.last) const SizedBox(height: AppTheme.spaceS),
          ],
        ],
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppTheme.spaceS,
      mainAxisSpacing: AppTheme.spaceS,
      childAspectRatio: 2.85,
      children: children,
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: accent,
                    isBold: true,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    isBold: true,
                  ).copyWith(height: 1.18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandButton extends StatelessWidget {
  const _CommandButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.neonCyan,
        side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.34)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceM,
          vertical: AppTheme.spaceS,
        ),
      ),
    );
  }
}
