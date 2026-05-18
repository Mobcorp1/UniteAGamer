import 'package:flutter/material.dart';

import 'package:uag_traders_hub/widgets/theme.dart';

class BlueprintActionsMenu extends StatelessWidget {
  const BlueprintActionsMenu({super.key, required this.onResetGrid});

  final VoidCallback onResetGrid;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Blueprint actions',
      color: AppTheme.cardBackgroundAlt,
      surfaceTintColor: Colors.transparent,
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) {
        if (value == 'reset') {
          onResetGrid();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'reset',
          child: Row(
            children: [
              Icon(
                Icons.restart_alt_rounded,
                color: Colors.redAccent.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 10),
              Text(
                'Reset Grid',
                style: AppTheme.bodyTextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  isBold: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
