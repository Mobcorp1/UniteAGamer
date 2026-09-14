import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/widgets/uag_programme_section.dart';

void main() {
  testWidgets(
    'programme detail mounts only while open and supports large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var mounts = 0;
      var disposals = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(1.8),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: UagProgrammeSection(
                  title: 'EARNINGS & COMMUNITY ACTIVITY',
                  subtitle: 'Review commission history and validation status.',
                  icon: Icons.receipt_long_outlined,
                  child: _MountProbe(
                    onMount: () => mounts++,
                    onDispose: () => disposals++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(mounts, 0);
      expect(find.text('Private live activity'), findsNothing);
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(mounts, 1);
      expect(find.text('Private live activity'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(disposals, 1);
      expect(find.text('Private live activity'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _MountProbe extends StatefulWidget {
  const _MountProbe({required this.onMount, required this.onDispose});
  final VoidCallback onMount;
  final VoidCallback onDispose;
  @override
  State<_MountProbe> createState() => _MountProbeState();
}

class _MountProbeState extends State<_MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Text('Private live activity');
}
