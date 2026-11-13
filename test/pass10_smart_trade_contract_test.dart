import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sharing uses art, cinematic canvas, real TradingRepository and final confirmation', () {
    final share = File('lib/features/trading_hub/arc_raiders/widgets/arc_collection_visual_share.dart').readAsStringSync();
    final offers = File('lib/features/trading_hub/arc_raiders/screens/trading_make_offer_screen.dart').readAsStringSync();
    final repo = File('lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart').readAsStringSync();
    expect(share, contains('await rootBundle.load(path)'));
    expect(share, contains('ArcSmartTradeTerms.recommend'));
    expect(share, contains('TradingRepository().createListing('));
    expect(share, contains('9:16 social image'));
    expect(share, contains('SPARES FOR TRADE'));
    expect(share, contains('NEEDED'));
    expect(share, contains('wantedPriorityRanks'));
    expect(offers, contains('_selectedSmartWantedIds'));
    expect(offers, contains('ArcBlueprintRepository().loadMyBlueprintStates()'));
    expect(repo, contains("bundle.terms.notes == 'UAG_SMART_TRADE_V1'"));
  });
}
