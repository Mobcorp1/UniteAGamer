import 'arc_assist_intent.dart';

class ArcAssistIntentParser {
  const ArcAssistIntentParser();

  ArcAssistIntent parse(String spokenText) {
    final normalised = spokenText.trim().toLowerCase();

    if (normalised.isEmpty) {
      return ArcAssistIntent(
        type: ArcAssistIntentType.unknown,
        spokenText: spokenText,
        blueprintQuery: null,
      );
    }

    if (normalised.contains('found ') ||
        normalised.contains('i found ') ||
        normalised.contains('got ') ||
        normalised.contains('picked up ')) {
      return ArcAssistIntent(
        type: ArcAssistIntentType.foundBlueprint,
        spokenText: spokenText,
        blueprintQuery: _extractBlueprintQuery(normalised),
      );
    }

    if (normalised.contains('duplicate') || normalised.contains('dupe')) {
      return ArcAssistIntent(
        type: ArcAssistIntentType.addDuplicate,
        spokenText: spokenText,
        blueprintQuery: _extractBlueprintQuery(normalised),
      );
    }

    if (normalised.contains('find trade') ||
        normalised.contains('who wants') ||
        normalised.contains('trade for')) {
      return ArcAssistIntent(
        type: ArcAssistIntentType.findTrade,
        spokenText: spokenText,
        blueprintQuery: _extractBlueprintQuery(normalised),
      );
    }

    if (normalised.contains('create listing') ||
        normalised.contains('list this')) {
      return ArcAssistIntent(
        type: ArcAssistIntentType.createListing,
        spokenText: spokenText,
        blueprintQuery: _extractBlueprintQuery(normalised),
      );
    }

    if (normalised.contains('open tracker')) {
      return ArcAssistIntent(
        type: ArcAssistIntentType.openTracker,
        spokenText: spokenText,
        blueprintQuery: null,
      );
    }

    if (normalised.contains('open planner')) {
      return ArcAssistIntent(
        type: ArcAssistIntentType.openPlanner,
        spokenText: spokenText,
        blueprintQuery: null,
      );
    }

    return ArcAssistIntent(
      type: ArcAssistIntentType.unknown,
      spokenText: spokenText,
      blueprintQuery: normalised,
    );
  }

  String? _extractBlueprintQuery(String normalised) {
    var result = normalised
        .replaceAll('arc assist', '')
        .replaceAll('i found', '')
        .replaceAll('found', '')
        .replaceAll('picked up', '')
        .replaceAll('got', '')
        .replaceAll('duplicate', '')
        .replaceAll('dupe', '')
        .replaceAll('create listing', '')
        .replaceAll('list this', '')
        .replaceAll('find trade', '')
        .replaceAll('who wants', '')
        .replaceAll('trade for', '')
        .trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }
}
