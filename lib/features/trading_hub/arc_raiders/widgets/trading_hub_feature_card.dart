import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class TradingHubFeatureCard extends StatelessWidget {
  const TradingHubFeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
    this.backgroundImagePath,
  });

  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onTap;
  final String? backgroundImagePath;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.25),
              width: AppTheme.cardBorderWidth,
            ),
            color: AppTheme.cardFillColor,
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.08),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (backgroundImagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.cardRadius),
                    topRight: Radius.circular(AppTheme.cardRadius),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 110,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          backgroundImagePath!,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, 0.28),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppTheme.cardFillColor.withValues(alpha: 0.12),
                                AppTheme.cardFillColor.withValues(alpha: 0.68),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: AppTheme.neonPink, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.neonTextStyle(
                              fontSize: 22,
                              color: AppTheme.neonCyan,
                              isBold: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppTheme.neonCyan,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.neonPink,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
