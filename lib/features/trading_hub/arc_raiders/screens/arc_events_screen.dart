import 'package:flutter/material.dart';
import '../raid_planner/screens/raid_planner_screen.dart';
import '../widgets/arc_events_workspace.dart';

/// Keeps saved Events links working through the canonical Raid Planner route.
class ArcEventsScreen extends StatefulWidget {
  const ArcEventsScreen({super.key});
  static const routeName = arcEventsRoute;

  @override
  State<ArcEventsScreen> createState() => _ArcEventsScreenState();
}

class _ArcEventsScreenState extends State<ArcEventsScreen> {
  bool _redirectScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_redirectScheduled) {
      return;
    }
    _redirectScheduled = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          RaidPlannerScreen.routeName,
          arguments: arguments,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
