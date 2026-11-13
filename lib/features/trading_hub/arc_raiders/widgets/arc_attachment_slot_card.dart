import 'package:flutter/material.dart';

import '../../../../widgets/theme.dart';

class ArcAttachmentSlotCard extends StatelessWidget {
  const ArcAttachmentSlotCard({
    super.key,
    required this.slotName,
    required this.isOwned,
    required this.isLocked,
    required this.imagePath,
  });

  final String slotName;
  final bool isOwned;
  final bool isLocked;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final borderColor = isLocked
        ? Colors.orangeAccent
        : isOwned
        ? AppTheme.neonCyan
        : Colors.grey;

    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.tradingCardDecoration(
        radius: 18,
        borderColor: borderColor.withValues(alpha: 0.28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Opacity(
              opacity: isOwned ? 1 : 0.35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            slotName.toUpperCase(),
            style: AppTheme.tradingHeading(fontSize: 11, color: borderColor),
          ),
          const SizedBox(height: 4),
          Text(
            isLocked
                ? 'Workshop Locked'
                : isOwned
                ? 'Owned'
                : 'Missing',
            style: AppTheme.bodyTextStyle(
              fontSize: 10,
              color: Colors.white70,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }
}
