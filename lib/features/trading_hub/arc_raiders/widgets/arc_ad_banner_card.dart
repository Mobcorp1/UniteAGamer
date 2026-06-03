import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcAdBannerCard extends StatelessWidget {
  const ArcAdBannerCard({
    super.key,
    this.isAdFree = false,
    this.isPremium = false,
    this.title,
    this.message,
    this.onUpgradePressed,
    this.onManagePressed,
  });

  final bool isAdFree;
  final bool isPremium;
  final String? title;
  final String? message;
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onManagePressed;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 520;
    final accent = isAdFree ? AppTheme.neonPink : AppTheme.neonCyan;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: AppTheme.tradingCardDecoration(
        radius: compact ? 20 : 24,
        borderColor: accent.withValues(alpha: 0.30),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.86),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -18,
            child: IgnorePointer(
              child: Container(
                width: compact ? 94 : 132,
                height: compact ? 94 : 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.07),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.08),
                      blurRadius: 28,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 38 : 44,
                height: compact ? 38 : 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: accent.withValues(alpha: 0.10),
                  border: Border.all(color: accent.withValues(alpha: 0.42)),
                ),
                child: Icon(
                  isAdFree
                      ? Icons.workspace_premium_rounded
                      : Icons.campaign_rounded,
                  color: accent,
                  size: compact ? 22 : 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ??
                          (isAdFree
                              ? 'AD-FREE ACTIVE'
                              : 'SUPPORTED FREE ACCESS'),
                      style: AppTheme.tradingHeading(
                        fontSize: compact ? 17 : 19,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      message ??
                          (isAdFree
                              ? 'Premium access is active. In-app banner placements stay hidden while your entitlement is valid.'
                              : 'Free access may show cinematic in-app sponsor placements. Upgrade later to remove supported banner slots.'),
                      style: AppTheme.bodyTextStyle(
                        fontSize: compact ? 12 : 13,
                        color: Colors.white70,
                        isBold: true,
                      ).copyWith(height: 1.32),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _ArcAdPill(
                          label: isAdFree ? 'Premium' : 'Free tier',
                          icon: isAdFree
                              ? Icons.lock_open_rounded
                              : Icons.visibility_rounded,
                          color: accent,
                        ),
                        _ArcAdPill(
                          label: isPremium
                              ? 'Ad-free eligible'
                              : 'Banner ready',
                          icon: isPremium
                              ? Icons.verified_rounded
                              : Icons.view_agenda_rounded,
                          color: AppTheme.neonCyan,
                        ),
                        _ArcAdPill(
                          label: 'Future AdMob slot',
                          icon: Icons.bolt_rounded,
                          color: AppTheme.neonPink,
                        ),
                      ],
                    ),
                    if (onUpgradePressed != null ||
                        onManagePressed != null) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          if (onUpgradePressed != null)
                            _ArcAdActionButton(
                              label: isPremium ? 'Upgrade plan' : 'Remove ads',
                              icon: Icons.arrow_upward_rounded,
                              onPressed: onUpgradePressed!,
                              color: AppTheme.neonCyan,
                            ),
                          if (onManagePressed != null)
                            _ArcAdActionButton(
                              label: 'Manage',
                              icon: Icons.tune_rounded,
                              onPressed: onManagePressed!,
                              color: AppTheme.neonPink,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcAdPill extends StatelessWidget {
  const _ArcAdPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.bodyTextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.82),
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcAdActionButton extends StatelessWidget {
  const _ArcAdActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.52)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppTheme.bodyTextStyle(
          fontSize: 12,
          color: color,
          isBold: true,
        ),
      ),
    );
  }
}
