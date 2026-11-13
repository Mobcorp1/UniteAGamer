import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final screen = File(
    'lib/features/trust/screens/arc_raider_contracts_screen.dart',
  ).readAsStringSync();
  final model = File(
    'lib/features/trust/models/arc_raider_contract_models.dart',
  ).readAsStringSync();
  final repo = File(
    'lib/features/trust/repositories/arc_raider_contracts_repository.dart',
  ).readAsStringSync();

  test('target identity is screen username, not Embark ID', () {
    expect(screen, contains("labelText: 'Screen username *'"));
    expect(screen, contains("key: const Key('report-rat-screen-username')"));
    expect(screen, isNot(contains("labelText: 'Embark ID *'")));
  });

  test(
    'incident stage has one report type and no duplicate behaviour flow',
    () {
      expect(
        screen,
        contains("'Choose the report type that best describes the incident.'"),
      );
      expect(screen, isNot(contains("'Behaviour'")));
      expect(screen, isNot(contains("'Repeat behaviour'")));
      expect(screen, isNot(contains("'What happened? *'")));
    },
  );

  test('requested report categories are present', () {
    for (final token in <String>[
      'lootRatting',
      'pvpThirdParty',
      'pveThirdParty',
      'falseFriendly',
    ]) {
      expect(model, contains(token));
    }
    for (final label in <String>[
      'Extraction camping',
      'Spawn camping',
      'Loot ratted',
      'PvP third partying',
      'PvE third partying',
      'False friendly',
      'Scam / trade misconduct',
    ]) {
      expect(screen, contains(label));
    }
  });

  test('event is a canonical map-condition dropdown', () {
    expect(screen, contains("key: const Key('report-rat-event-dropdown')"));
    expect(screen, contains('ArcMapConditions.combinedOptionsForMap'));
    expect(screen, isNot(contains("'Event / activity (optional)'")));
  });

  test('evidence is a private MP4 clip upload instead of URLs', () {
    expect(screen, contains("key: const Key('report-rat-attach-clip')"));
    expect(screen, contains('pickVideo('));
    expect(screen, contains('maxDuration: const Duration(seconds: 30)'));
    expect(screen, isNot(contains("'Evidence URL (optional)'")));
    expect(screen, isNot(contains("'TikTok / social URL (optional)'")));
    expect(repo, contains(r"'conduct_evidence/$reportId/$uid/"));
    expect(repo, contains("SettableMetadata(contentType: 'video/mp4')"));
  });

  test('description is no longer required to submit a report', () {
    expect(model, isNot(contains('description.trim().length >= 20')));
  });
}
