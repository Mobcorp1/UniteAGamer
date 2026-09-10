import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String source(String name) => File(
    'lib/features/trading_hub/arc_raiders/screens/$name',
  ).readAsStringSync();

  test('create listing has guarded profile and publish states', () {
    final text = source('arc_create_trade_listing_screen.dart');
    expect(text, contains("title: 'TRADE REQUEST'"));
    expect(text, contains("title: 'Trader profile unavailable'"));
    expect(text, contains("'Could not create this listing. Try again.'"));
    expect(text, contains("'Publish Trade Listing'"));
    expect(text, contains('catch (_)'));
  });

  test('smart build draft exposes production loading and failure states', () {
    final text = source('arc_smart_build_trade_draft_screen.dart');
    expect(text, contains("title: 'SMART BUILD // TRADE DRAFT'"));
    expect(text, contains("title: 'Smart Build unavailable'"));
    expect(text, contains("title: 'Blueprint state unavailable'"));
    expect(text, contains("title: 'Checking build readiness'"));
  });

  test('trader hub keeps six destinations readable on narrow devices', () {
    final text = source('trader_hub_screen.dart');
    expect(text, contains('final compactBottomNav = viewportWidth < 720;'));
    expect(
      text,
      contains('NavigationDestinationLabelBehavior.onlyShowSelected'),
    );
  });

  test('communications centre has ARC hierarchy and state panels', () {
    final text = source('trading_notifications_screen.dart');
    expect(text, contains("title: 'COMMUNICATIONS CENTRE'"));
    expect(text, contains("title: 'Communications unavailable'"));
    expect(text, contains("title: 'Syncing communications'"));
    expect(text, contains("'No communications yet'"));
  });
}
