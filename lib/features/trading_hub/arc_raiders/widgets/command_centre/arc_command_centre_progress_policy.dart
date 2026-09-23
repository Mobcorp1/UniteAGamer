import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';

class ArcCommandCentreProgressPolicy {
  const ArcCommandCentreProgressPolicy._();

  static int? measuredPercent({
    required ArcCommandStatus status,
    required String label,
    required String detail,
  }) {
    final text = '$label $detail'.toLowerCase();
    final percentMatch = RegExp(r'(\d{1,3})\s*%').firstMatch(text);
    if (percentMatch != null) {
      return (int.tryParse(percentMatch.group(1) ?? '') ?? 0).clamp(0, 100);
    }

    final fractionMatch = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(text);
    if (fractionMatch != null) {
      final current = int.tryParse(fractionMatch.group(1) ?? '') ?? 0;
      final target = int.tryParse(fractionMatch.group(2) ?? '') ?? 0;
      if (target > 0) {
        return ((current / target) * 100).round().clamp(0, 100);
      }
    }

    if (status == ArcCommandStatus.success) return 100;
    return null;
  }
}
