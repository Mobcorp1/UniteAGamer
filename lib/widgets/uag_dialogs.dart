import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class UagDialogs {
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    Color titleColor = ArcUiTokens.primaryAccent,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Confirm',
    Color? confirmBackgroundColor,
    Color? confirmForegroundColor,
    Color? borderColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final accent = borderColor ?? titleColor;
        return AlertDialog(
          backgroundColor: ArcUiTokens.surfaceOverlay,
          surfaceTintColor: Colors.transparent,
          shape: _dialogShape(accent),
          title: Text(title, style: _titleStyle(titleColor)),
          content: Text(message, style: _contentStyle()),
          actions: [
            TextButton(
              style: ArcUiTokens.textButtonStyle(accent: accent),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            TextButton(
              style: confirmBackgroundColor == null
                  ? ArcUiTokens.textButtonStyle(accent: accent, primary: true)
                  : TextButton.styleFrom(
                      backgroundColor: confirmBackgroundColor,
                      foregroundColor:
                          confirmForegroundColor ?? ArcUiTokens.background,
                      padding: ArcUiTokens.buttonPadding,
                      textStyle: ArcUiTokens.buttonLabel(
                        color: confirmForegroundColor ?? ArcUiTokens.background,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ArcUiTokens.radiusM,
                        ),
                      ),
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
          backgroundColor: ArcUiTokens.surfaceOverlay,
          surfaceTintColor: Colors.transparent,
          shape: _dialogShape(ArcUiTokens.primaryAccent),
          title: Text(title, style: _titleStyle(ArcUiTokens.primaryAccent)),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(itemCount, (index) {
              return ActionChip(
                backgroundColor: ArcUiTokens.surfaceRaised,
                side: BorderSide(
                  color: ArcUiTokens.primaryAccent.withValues(alpha: 0.24),
                ),
                labelStyle: ArcUiTokens.buttonLabel(
                  color: ArcUiTokens.textPrimary,
                ),
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
          backgroundColor: ArcUiTokens.surfaceOverlay,
          surfaceTintColor: Colors.transparent,
          shape: _dialogShape(ArcUiTokens.primaryAccent),
          title: Text(title, style: _titleStyle(ArcUiTokens.primaryAccent)),
          content: Text(message, style: _contentStyle()),
          actions: [
            TextButton(
              style: ArcUiTokens.textButtonStyle(
                accent: ArcUiTokens.primaryAccent,
                primary: true,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(buttonLabel),
            ),
          ],
        );
      },
    );
  }

  static ShapeBorder _dialogShape(Color accent) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ArcUiTokens.radiusXL),
      side: BorderSide(color: accent.withValues(alpha: 0.28)),
    );
  }

  static TextStyle _titleStyle(Color color) {
    return ArcUiTokens.sectionTitle(fontSize: 18, color: color);
  }

  static TextStyle _contentStyle() {
    return ArcUiTokens.body(color: ArcUiTokens.textSecondary);
  }
}
