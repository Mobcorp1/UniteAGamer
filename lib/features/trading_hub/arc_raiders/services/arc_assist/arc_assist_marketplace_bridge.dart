import '../automation/smart_trade_assist_controller.dart';
import '../automation/smart_trade_inventory_input.dart';
import 'arc_assist_marketplace_speech_service.dart';
import 'arc_assist_marketplace_summary.dart';

class ArcAssistMarketplaceBridge {
  final SmartTradeAssistController controller;
  final ArcAssistMarketplaceSummaryBuilder summaryBuilder;
  final ArcAssistMarketplaceSpeechService speechService;

  const ArcAssistMarketplaceBridge({
    required this.controller,
    this.summaryBuilder = const ArcAssistMarketplaceSummaryBuilder(),
    this.speechService = const ArcAssistMarketplaceSpeechService(),
  });

  ArcAssistMarketplaceSummary scan(SmartTradeInventoryInput input) {
    controller.rebuild(input);
    return summaryBuilder.build(controller.opportunities);
  }

  String scanAndSpeak(SmartTradeInventoryInput input) {
    final summary = scan(input);
    return speechService.buildSpokenReadout(summary);
  }
}
