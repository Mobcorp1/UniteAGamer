import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class UagDialogs {
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    Color titleColor = AppTheme.neonCyan,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Confirm',
    Color? confirmBackgroundColor,
    Color? confirmForegroundColor,
    Color? borderColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackgroundDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: (borderColor ?? titleColor).withValues(alpha: 0.32),
            ),
          ),
          title: Text(
            title,
            style: AppTheme.tradingHeading(fontSize: 22, color: titleColor),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            ElevatedButton(
              style:
                  confirmBackgroundColor == null &&
                      confirmForegroundColor == null
                  ? null
                  : ElevatedButton.styleFrom(
                      backgroundColor: confirmBackgroundColor,
                      foregroundColor: confirmForegroundColor,
                    ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  static Future<int?> chooseIndex({
    required BuildContext context,
    required String title,
    required int itemCount,
    required String Function(int index) labelBuilder,
  }) {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackgroundDeep,
          title: Text(
            title,
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonCyan,
            ),
          ),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(itemCount, (index) {
              return ActionChip(
                label: Text(labelBuilder(index)),
                onPressed: () => Navigator.of(dialogContext).pop(index),
              );
            }),
          ),
        );
      },
    );
  }

  static Future<void> info({
    required BuildContext context,
    required String title,
    required String message,
    String buttonLabel = 'Got it',
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackgroundDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.20)),
          ),
          title: Text(
            title,
            style: AppTheme.tradingHeading(
              fontSize: 22,
              color: AppTheme.neonCyan,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(buttonLabel),
            ),
          ],
        );
      },
    );
  }
}
