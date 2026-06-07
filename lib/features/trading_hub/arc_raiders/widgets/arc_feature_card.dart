import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_feature_model.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcFeatureCard extends StatelessWidget {
  const ArcFeatureCard({super.key, required this.item, required this.selected});

  final ArcFeatureItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: selected ? 1 : 0.92,
      child: GestureDetector(
        onTap: item.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: item.accent.withValues(alpha: selected ? 0.92 : 0.34),
              width: selected ? 2.4 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: item.accent.withValues(alpha: selected ? 0.28 : 0.10),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(item.image, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.16),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, color: item.accent, size: 26),
                      const Spacer(),
                      Text(
                        item.title,
                        style: AppTheme.neonTextStyle(
                          fontSize: 23,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
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
      ),
    );
  }
}
