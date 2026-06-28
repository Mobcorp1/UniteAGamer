import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';

class ArcOperationsTelemetryEvents {
  const ArcOperationsTelemetryEvents._();

  static const tradeCompleted = ArcOperationTelemetryType.tradeCompleted;
  static const listingCreated = ArcOperationTelemetryType.listingCreated;
  static const matchmakingCompleted =
      ArcOperationTelemetryType.matchmakingCompleted;
  static const blueprintReportSubmitted =
      ArcOperationTelemetryType.blueprintReportSubmitted;
  static const profileCompleted = ArcOperationTelemetryType.profileCompleted;
  static const referralCompleted = ArcOperationTelemetryType.referralCompleted;
  static const playerHelped = ArcOperationTelemetryType.playerHelped;
  static const guardianSessionCompleted =
      ArcOperationTelemetryType.guardianSessionCompleted;
  static const favouriteLoadoutSaved =
      ArcOperationTelemetryType.favouriteLoadoutSaved;
  static const feedbackSubmitted = ArcOperationTelemetryType.feedbackSubmitted;
  static const loginRecorded = ArcOperationTelemetryType.loginRecorded;
}
