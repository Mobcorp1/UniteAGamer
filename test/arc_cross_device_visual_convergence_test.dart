import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';

void main() {
  test('viewport classes and padding are platform-agnostic', () {
    expect(
      ArcLayoutTokens.viewportClassForWidth(320),
      ArcViewportClass.compact,
    );
    expect(ArcLayoutTokens.viewportClassForWidth(800), ArcViewportClass.medium);
    expect(
      ArcLayoutTokens.viewportClassForWidth(1280),
      ArcViewportClass.expanded,
    );
    expect(ArcLayoutTokens.viewportClassForWidth(1700), ArcViewportClass.wide);

    expect(
      ArcLayoutTokens.pagePaddingForSize(const Size(390, 844)),
      const EdgeInsets.fromLTRB(12, 10, 12, 16),
    );
    expect(
      ArcLayoutTokens.pagePaddingForSize(const Size(1440, 900)),
      const EdgeInsets.fromLTRB(22, 18, 22, 22),
    );
  });

  for (final width in [320.0, 390.0, 800.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'shared ARC chrome renders at width $width and text scale $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1000),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: const SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        children: [
                          ArcRaidersPageHeader(
                            title: 'Cross-device command surface',
                            subtitle:
                                'The same hierarchy must survive compact and wide hosts.',
                            trailing: Text('STATUS'),
                          ),
                          SizedBox(height: 12),
                          ArcRaidersHeroBanner(
                            title: 'TACTICAL OVERVIEW',
                            subtitle:
                                'Android, iOS and web share one responsive presentation contract.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  bottomNavigationBar: const ArcCompanionBottomDock(
                    activeLabel: 'RUN',
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(find.text('Cross-device command surface'), findsOneWidget);
          expect(find.text('TACTICAL OVERVIEW'), findsOneWidget);
          expect(find.text('RUN'), findsOneWidget);
          expect(find.text('DISCOVER'), findsOneWidget);
          expect(find.text('TRACK'), findsOneWidget);
          expect(find.text('TRADE'), findsOneWidget);
          expect(find.text('PROFILE'), findsOneWidget);
        },
      );
    }
  }

  test('shared source owns the convergence contracts', () {
    final shell = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_raiders_screen_shell.dart',
    ).readAsStringSync();
    final appBar = File('lib/screens/build/app_bar.dart').readAsStringSync();
    final dock = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart',
    ).readAsStringSync();

    expect(shell, contains('ArcLayoutTokens.pagePaddingForSize'));
    expect(shell, contains('final stackTrailing ='));
    expect(shell, contains('final veryCompact ='));
    expect(appBar, contains('static const double toolbarHeight = 60;'));
    expect(appBar, contains('toolbarHeight: toolbarHeight'));
    expect(dock, contains('ArcLayoutTokens.tabletBreakpoint'));
    expect(dock, contains('final compactChrome ='));
    expect(dock, contains('FittedBox('));
  });
}
