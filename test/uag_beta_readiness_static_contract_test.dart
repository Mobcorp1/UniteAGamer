import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UAG beta readiness static contracts', () {
    test('normal entry routes land on Discover instead of Command Centre', () {
      final appEntryGate = File(
        'lib/build/app_entry_gate.dart',
      ).readAsStringSync();
      final legacyEntryGate = File(
        'lib/screens/build/app_entry_gate.dart',
      ).readAsStringSync();
      final homeScreen = File('lib/build/home_screen.dart').readAsStringSync();
      final main = File('lib/main.dart').readAsStringSync();
      final hub = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart',
      ).readAsStringSync();

      expect(
        appEntryGate,
        contains(
          "export 'package:uag_arc_raiders_hub/screens/build/app_entry_gate.dart';",
        ),
      );
      expect(appEntryGate, isNot(contains('class AppEntryGate')));
      expect(legacyEntryGate, contains('class AppEntryGate'));
      expect(legacyEntryGate, contains('return const ArcRaidersHubScreen();'));
      expect(homeScreen, contains('ArcRaidersHubScreen.routeName'));
      expect(main, contains('case ArcRaidersHubScreen.routeName:'));

      final firstCommand = hub.indexOf("title: 'Command Centre'");
      final firstBlueprint = hub.indexOf("title: 'Blueprint Tracker'");
      expect(firstCommand, greaterThan(0));
      expect(firstCommand, lessThan(firstBlueprint));
      expect(hub, contains("activeLabel: 'discover'"));
    });

    test('major beta routes remain registered in the route dispatcher', () {
      final main = File('lib/main.dart').readAsStringSync();
      final routeContracts = <String>[
        'ArcRaidersHubScreen.routeName',
        'ArcCommandCentreScreen.routeName',
        'BlueprintGridScreen.routeName',
        'FavouriteLoadoutScreen.routeName',
        'ScrappyGridScreen.routeName',
        'ScrappyGridScreen.benchRouteName',
        'ScrappyGridScreen.questRouteName',
        'RaidPlannerScreen.routeName',
        'RaidPlannerHuntTargetsScreen.routeName',
        'ArcRaidIntelligenceScreen.routeName',
        'ArcMarketIntelligenceScreen.routeName',
        'MyIntelScreen.routeName',
        'ArcMatchRiderScreen.routeName',
        'TraderHubScreen.routeName',
        'TradingListingsScreen.routeName',
        'TradingCreateListingScreen.routeName',
        'TradingMyOffersScreen.routeName',
        'TradingBlueprintWatchesScreen.routeName',
        'TradingListingQueuesScreen.routeName',
        'TradingTradeSessionsScreen.routeName',
        'TradingNotificationsScreen.routeName',
        'SmartTradeAssistScreen.routeName',
        'TradingProfileScreen.routeName',
        'MonetisationScreen.routeName',
        'WallOfLegendsScreen.routeName',
        'ArcBetaFeedbackScreen.routeName',
        'FeedbackScreen.routeName',
      ];

      for (final route in routeContracts) {
        expect(main, contains('case $route:'), reason: route);
      }
    });

    test('mobile brand app bars keep the full two-line product name', () {
      for (final path in const [
        'lib/build/app_bar.dart',
        'lib/screens/build/app_bar.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, contains("fullBrandTitle && compact"), reason: path);
        expect(source, contains("'UAG ARC'"), reason: path);
        expect(source, contains("'RAIDERS HUB'"), reason: path);
        expect(source, contains("'UAG ARC RAIDERS HUB'"), reason: path);
      }
    });

    test('player-facing UI does not render raw backend exception text', () {
      final offenders = <String>[];
      final riskyPatterns = <RegExp>[
        RegExp(r'snapshot\.error'),
        RegExp(r'\$error(?![A-Za-z0-9_])'),
        RegExp(r'\$\{error\}'),
        RegExp(r'\$e(?![A-Za-z0-9_])'),
        RegExp(r'\$\{e\}'),
        RegExp(r'error\.toString\(\)'),
        RegExp(r'e\.toString\(\)'),
      ];
      final uiHints = <String>[
        'SnackBar',
        'Text(',
        'content:',
        'copy:',
        '_message =',
        '_showSnack',
        '_showMessage',
      ];
      final logHints = <String>[
        'debugPrint',
        '_debugLog',
        '_log(',
        'debugPrintStack',
      ];
      final ignoredPathFragments = <String>[
        '/arc_admin_map_editor_screen.dart',
        '/arc_camera_diagnostic_screen.dart',
        '/blueprint_grid_screen.dart',
      ];

      for (final file in _dartFiles('lib')) {
        final path = _normalisedPath(file);
        if (!_isPlayerFacingUiPath(path)) continue;
        if (ignoredPathFragments.any(path.endsWith)) continue;

        final lines = file.readAsLinesSync();
        for (var index = 0; index < lines.length; index += 1) {
          final line = lines[index];
          final hasRiskyToken = riskyPatterns.any((pattern) {
            return pattern.hasMatch(line);
          });
          final hasUiHint = uiHints.any(line.contains);
          final isLogLine = logHints.any(line.contains);
          if (hasRiskyToken && hasUiHint && !isLogLine) {
            offenders.add('$path:${index + 1}: ${line.trim()}');
          }
        }
      }

      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('user-facing Dart source has no mojibake signatures', () {
      final signatures = <String, String>{
        'latin capital A with tilde': String.fromCharCode(0x00c3),
        'latin capital A with circumflex': String.fromCharCode(0x00c2),
        'mojibake euro prefix': String.fromCharCodes([0x00e2, 0x20ac]),
        'replacement character': String.fromCharCode(0xfffd),
      };
      final offenders = <String>[];

      for (final file in _dartFiles('lib')) {
        final source = file.readAsStringSync();
        for (final entry in signatures.entries) {
          if (source.contains(entry.value)) {
            offenders.add('${_normalisedPath(file)}: ${entry.key}');
          }
        }
      }

      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('direct literal image asset references exist and are non-empty', () {
      final offenders = <String>[];
      final assetReference = RegExp(
        r'''(?:Image\.asset|AssetImage|ExactAssetImage|SvgPicture\.asset)\(\s*(?:const\s*)?(['"])(assets/[^'"]+\.(?:png|jpe?g|webp|svg|gif|json))\1''',
        multiLine: true,
      );

      for (final file in _dartFiles('lib')) {
        final source = file.readAsStringSync();
        for (final match in assetReference.allMatches(source)) {
          final path = match.group(2)!;
          final asset = File(path);
          if (!asset.existsSync()) {
            offenders.add('${_normalisedPath(file)} -> missing $path');
            continue;
          }
          if (asset.lengthSync() == 0) {
            offenders.add('${_normalisedPath(file)} -> empty $path');
          }
        }
      }

      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('declared asset roots exist', () {
      final offenders = <String>[];
      final pubspec = File('pubspec.yaml').readAsLinesSync();
      final assetLine = RegExp(r'^\s*-\s+(assets/[^#\s]+)\s*$');

      for (final line in pubspec) {
        final match = assetLine.firstMatch(line);
        if (match == null) continue;

        final path = match.group(1)!;
        final exists = path.endsWith('/')
            ? Directory(path).existsSync()
            : File(path).existsSync() || Directory(path).existsSync();
        if (!exists) {
          offenders.add(path);
        }
      }

      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('high-priority UI actions are not wired to empty callbacks', () {
      final offenders = <String>[];
      final emptyCallback = RegExp(
        r'(onPressed|onTap|onLongPress):\s*\(\)\s*\{\s*\}',
      );

      for (final file in _dartFiles('lib')) {
        final path = _normalisedPath(file);
        if (!_isPlayerFacingUiPath(path)) continue;
        if (path.endsWith('/blueprint_grid_screen.dart')) continue;

        final lines = file.readAsLinesSync();
        for (var index = 0; index < lines.length; index += 1) {
          if (emptyCallback.hasMatch(lines[index])) {
            offenders.add('$path:${index + 1}: ${lines[index].trim()}');
          }
        }
      }

      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });
}

Iterable<File> _dartFiles(String root) sync* {
  final directory = Directory(root);
  if (!directory.existsSync()) return;
  for (final entity in directory.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}

String _normalisedPath(File file) => file.path.replaceAll(r'\', '/');

bool _isPlayerFacingUiPath(String path) {
  return path.contains('/screens/') ||
      path.contains('/widgets/') ||
      path.contains('/build/') ||
      path.contains('/reg/');
}
