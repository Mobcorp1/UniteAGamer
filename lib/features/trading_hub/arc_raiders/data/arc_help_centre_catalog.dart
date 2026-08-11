import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/operations_command_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_profile_screen.dart';
import 'package:uag_arc_raiders_hub/screens/build/feedback_screen.dart';

class ArcHelpAnswer {
  const ArcHelpAnswer({required this.question, required this.answer});

  final String question;
  final String answer;
}

class ArcHelpCategory {
  const ArcHelpCategory({
    required this.id,
    required this.title,
    required this.summary,
    required this.answers,
    this.routeName,
  });

  final String id;
  final String title;
  final String summary;
  final String? routeName;
  final List<ArcHelpAnswer> answers;
}

class ArcHelpCentreCatalog {
  const ArcHelpCentreCatalog._();

  static const List<ArcHelpCategory> categories = [
    ArcHelpCategory(
      id: 'getting-started',
      title: 'Getting Started',
      summary: 'Home routing, Command Centre basics and first setup steps.',
      routeName: ArcCommandCentreScreen.routeName,
      answers: [
        ArcHelpAnswer(
          question: 'Where should I start?',
          answer:
              'Open Command Centre first. It ranks today\'s mission, the next three actions, blockers and compact system summaries.',
        ),
        ArcHelpAnswer(
          question: 'What is My Hub for now?',
          answer:
              'My Hub is the personal tool deck for things you own or configure, while Command Centre answers what to do next.',
        ),
      ],
    ),
    ArcHelpCategory(
      id: 'blueprint-tracker',
      title: 'Blueprint Tracker',
      summary: 'Owned, missing, duplicate and wanted blueprint tracking.',
      routeName: BlueprintGridScreen.routeName,
      answers: [
        ArcHelpAnswer(
          question: 'How do I mark a blueprint?',
          answer:
              'Tap a blueprint for details and use the existing ownership controls. Long press opens loadout and trade actions.',
        ),
        ArcHelpAnswer(
          question: 'Do duplicates affect trade suggestions?',
          answer:
              'Yes. Duplicate state feeds Smart Trade Assist and Command Centre recommendations without changing collection order.',
        ),
      ],
    ),
    ArcHelpCategory(
      id: 'favourite-loadout',
      title: 'Favourite Loadout',
      summary:
          'Weapons, attachment slots, Quick Use, shield and augment setup.',
      routeName: FavouriteLoadoutScreen.routeName,
      answers: [
        ArcHelpAnswer(
          question: 'Why do weapons show different slot counts?',
          answer:
              'Slots come from the canonical weapon data. Zero-slot weapons do not reserve fake attachment spaces.',
        ),
        ArcHelpAnswer(
          question: 'Where did bench and material detail go?',
          answer:
              'Use the detail panels or picker sheets. The default loadout view stays focused on the selected weapons and slots.',
        ),
      ],
    ),
    ArcHelpCategory(
      id: 'trading',
      title: 'Trading',
      summary: 'Listings, offers, watches, sessions and trade intelligence.',
      routeName: TraderHubScreen.routeName,
      answers: [
        ArcHelpAnswer(
          question: 'What feeds trade intelligence?',
          answer:
              'Missing blueprints, duplicates, wanted items, listings and safe repository data feed the trade recommendation layer.',
        ),
        ArcHelpAnswer(
          question: 'Can reputation block a trade?',
          answer:
              'No. Reputation can add context, but it should not block a trade by itself.',
        ),
      ],
    ),
    ArcHelpCategory(
      id: 'match-rider',
      title: 'Match Raider',
      summary: 'Squad matching, play-style fit and session planning.',
      routeName: ArcMatchRiderScreen.routeName,
      answers: [
        ArcHelpAnswer(
          question: 'What is Match Raider for?',
          answer:
              'Use it to find players with compatible goals, roles and session preferences.',
        ),
        ArcHelpAnswer(
          question: 'Where do planned raids live?',
          answer:
              'Raid Planner handles route planning and hunt targets; Match Raider focuses on people fit.',
        ),
      ],
    ),
    ArcHelpCategory(
      id: 'operations',
      title: 'Operations',
      summary: 'Operations, Reward Vault cosmetics and seasonal progression.',
      routeName: OperationsCommandScreen.routeName,
      answers: [
        ArcHelpAnswer(
          question: 'Where are rewards managed?',
          answer:
              'Operations contains Reward Vault, seasonal progression and earned cosmetic state.',
        ),
        ArcHelpAnswer(
          question: 'Do cosmetics affect profile display?',
          answer:
              'Equipped cosmetics are persisted from Reward Vault and shown by profile surfaces where supported.',
        ),
      ],
    ),
    ArcHelpCategory(
      id: 'profile-reputation',
      title: 'Profile and Reputation',
      summary: 'Public identity, profile cosmetics, trust and beta reputation.',
      routeName: TradingProfileScreen.routeName,
      answers: [
        ArcHelpAnswer(
          question: 'What belongs in my profile?',
          answer:
              'Profile shows identity, cosmetics, trader information and trust signals rather than daily task recommendations.',
        ),
        ArcHelpAnswer(
          question: 'Can I change cosmetics from profile?',
          answer:
              'Reward Vault remains the source of truth for equipped cosmetics.',
        ),
      ],
    ),
    ArcHelpCategory(
      id: 'privacy-safety-reporting',
      title: 'Privacy, Safety and Reporting',
      summary: 'Legal docs, conduct expectations and safer beta reporting.',
      answers: [
        ArcHelpAnswer(
          question: 'Where are legal documents?',
          answer:
              'Terms, Privacy and Trader Code of Conduct remain available from Help and onboarding.',
        ),
        ArcHelpAnswer(
          question: 'How should reports be used?',
          answer:
              'Report no-shows, scams, abusive conduct and inaccurate listings truthfully. Do not use reports as retaliation.',
        ),
      ],
    ),
    ArcHelpCategory(
      id: 'closed-beta-feedback',
      title: 'Closed Beta Feedback',
      summary: 'Send bugs, UX notes and beta feedback to the UAG team.',
      routeName: FeedbackScreen.routeName,
      answers: [
        ArcHelpAnswer(
          question: 'What feedback helps most?',
          answer:
              'Clear bug summaries, reproduction steps, screenshots and where you were in the app are most useful.',
        ),
        ArcHelpAnswer(
          question: 'Can I send feature ideas?',
          answer:
              'Yes. Use the feedback form and choose the closest category for the idea.',
        ),
      ],
    ),
  ];

  static ArcHelpCategory resolve(String? idOrTitle) {
    final target = (idOrTitle ?? '').trim().toLowerCase();
    if (target.isEmpty) return categories.first;

    return categories.firstWhere(
      (category) =>
          category.id == target || category.title.toLowerCase() == target,
      orElse: () => categories.first,
    );
  }
}
