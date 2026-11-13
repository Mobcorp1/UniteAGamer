import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trust/models/arc_raider_contract_models.dart';
import 'package:uag_arc_raiders_hub/features/trust/screens/arc_raider_contracts_screen.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final heading = FontLoader(AppTheme.headingFontFamily)
      ..addFont(rootBundle.load('assets/fonts/SpaceGrotesk-SemiBold.ttf'));
    final body = FontLoader(AppTheme.bodyFontFamily)
      ..addFont(
        rootBundle.load('assets/fonts/Inter-VariableFont_opsz,wght.ttf'),
      );
    await heading.load();
    await body.load();
  });

  for (final width in [320.0, 1080.0]) {
    testWidgets('issuer deliberately confirms once at $width', (tester) async {
      var calls = 0;
      final completed = Completer<void>();
      await _mount(
        tester,
        width,
        ArcHunterContractCard(
          contract: _contract(),
          issuer: true,
          onOpenEvidence: () async {},
          onReview: (confirmed, reason) {
            expect(confirmed, isTrue);
            expect(reason, isEmpty);
            calls++;
            return completed.future;
          },
        ),
      );
      await tester.ensureVisible(find.text('CONFIRM COMPLETION'));
      await tester.tap(find.text('CONFIRM COMPLETION'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      final confirmButton = find.widgetWithText(
        FilledButton,
        'YES, CONFIRM COMPLETION',
      );
      expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await tester.pump();
      expect(calls, 1);
      expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);
      completed.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'rejection requires reason and preserves it after a failed save',
    (tester) async {
      var calls = 0;
      await _mount(
        tester,
        320,
        ArcHunterContractCard(
          contract: _contract(),
          issuer: true,
          onReview: (confirmed, reason) async {
            expect(confirmed, isFalse);
            expect(reason, 'The clip does not show the outcome.');
            calls++;
            if (calls == 1) throw StateError('private server detail');
          },
        ),
      );
      await tester.ensureVisible(find.text('REJECT EVIDENCE'));
      await tester.tap(find.text('REJECT EVIDENCE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SEND REJECTION'));
      await tester.pump();
      expect(calls, 0);
      expect(
        find.text('Explain why this clip does not confirm completion.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextField),
        'The clip does not show the outcome.',
      );
      await tester.tap(find.text('SEND REJECTION'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('private server detail'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'The clip does not show the outcome.',
      );
      await tester.tap(find.text('SEND REJECTION'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rejected hunter sees reason and can submit a replacement', (
    tester,
  ) async {
    var submissions = 0;
    await _mount(
      tester,
      320,
      ArcHunterContractCard(
        contract: _contract(verification: 'rejected'),
        onSubmit: () async => submissions++,
      ),
    );
    expect(find.text('EVIDENCE REJECTED'), findsOneWidget);
    expect(find.text('The outcome is not visible.'), findsOneWidget);
    expect(find.text('CONFIRM COMPLETION'), findsNothing);
    await tester.ensureVisible(find.text('SUBMIT NEW VIDEO'));
    await tester.tap(find.text('SUBMIT NEW VIDEO'));
    await tester.pumpAndSettle();
    expect(submissions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'verified completion has no mutation actions and legacy completed is unverified',
    (tester) async {
      await _mount(
        tester,
        320,
        ArcHunterContractCard(
          contract: _contract(
            verification: 'verified',
            status: ArcRaiderContractStatus.completed,
          ),
          issuer: true,
          onSubmit: () async {},
          onReview: (_, _) async {},
        ),
      );
      expect(find.text('VERIFIED COMPLETE'), findsOneWidget);
      expect(find.text('CONFIRM COMPLETION'), findsNothing);
      expect(find.text('REJECT EVIDENCE'), findsNothing);
      expect(find.text('SUBMIT VIDEO EVIDENCE'), findsNothing);
      expect(tester.takeException(), isNull);
      await _mount(
        tester,
        320,
        ArcHunterContractCard(
          contract: _contract(
            verification: '',
            status: ArcRaiderContractStatus.completed,
          ),
        ),
      );
      expect(find.text('COMPLETED · NOT ISSUER VERIFIED'), findsOneWidget);
      expect(find.text('VERIFIED COMPLETE'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

ArcRaiderContract _contract({
  String verification = 'pending',
  ArcRaiderContractStatus status = ArcRaiderContractStatus.evidenceSubmitted,
}) => ArcRaiderContract(
  id: 'contract-1',
  reportId: 'report-1',
  reporterUid: 'issuer',
  hunterUid: 'hunter',
  targetDisplayName: 'Private contract encounter',
  status: status,
  verificationStatus: verification,
  evidenceSubmissionId: 'submission-1',
  verifiedByUid: verification == 'verified' ? 'issuer' : '',
  verifiedAt: verification == 'verified' ? DateTime.utc(2026, 9, 14) : null,
  rejectionReason: verification == 'rejected'
      ? 'The outcome is not visible.'
      : '',
  evidence: const [
    ArcRaiderEvidence(
      id: 'video-1',
      submittedByUid: 'hunter',
      kind: 'video',
      url: 'https://example.invalid/private-video',
      storagePath: 'contract_evidence/contract-1/hunter/video-1.mp4',
    ),
  ],
);

Future<void> _mount(WidgetTester tester, double width, Widget card) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.5)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: card,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}
