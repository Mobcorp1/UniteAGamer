import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_profile_social_models.dart';

enum PlayLikeAProCategory {
  combat,
  pve,
  pvp,
  survival,
  extraction,
  positioning,
  movement,
  mapRoutes,
  lootRoutes,
  blueprintRoutes,
  eventPreparation,
  weapons,
  attachments,
  loadouts,
  squadTactics,
  soloTactics,
  encounterDecisions,
  inventoryPreparation,
  resourcePriorities,
  advanced,
}

extension PlayLikeAProCategoryX on PlayLikeAProCategory {
  String get label => switch (this) {
    PlayLikeAProCategory.combat => 'Combat',
    PlayLikeAProCategory.pve => 'PvE',
    PlayLikeAProCategory.pvp => 'PvP',
    PlayLikeAProCategory.survival => 'Survival',
    PlayLikeAProCategory.extraction => 'Extraction',
    PlayLikeAProCategory.positioning => 'Positioning',
    PlayLikeAProCategory.movement => 'Movement',
    PlayLikeAProCategory.mapRoutes => 'Map Routes',
    PlayLikeAProCategory.lootRoutes => 'Loot Routes',
    PlayLikeAProCategory.blueprintRoutes => 'Blueprint Routes',
    PlayLikeAProCategory.eventPreparation => 'Event Prep',
    PlayLikeAProCategory.weapons => 'Weapons',
    PlayLikeAProCategory.attachments => 'Attachments',
    PlayLikeAProCategory.loadouts => 'Loadouts',
    PlayLikeAProCategory.squadTactics => 'Squad Tactics',
    PlayLikeAProCategory.soloTactics => 'Solo Tactics',
    PlayLikeAProCategory.encounterDecisions => 'Encounter Decisions',
    PlayLikeAProCategory.inventoryPreparation => 'Inventory Prep',
    PlayLikeAProCategory.resourcePriorities => 'Resource Priorities',
    PlayLikeAProCategory.advanced => 'Advanced',
  };
}

enum PlayLikeAProSkillLevel { starter, intermediate, advanced, expert }

extension PlayLikeAProSkillLevelX on PlayLikeAProSkillLevel {
  String get label => switch (this) {
    PlayLikeAProSkillLevel.starter => 'Starter',
    PlayLikeAProSkillLevel.intermediate => 'Intermediate',
    PlayLikeAProSkillLevel.advanced => 'Advanced',
    PlayLikeAProSkillLevel.expert => 'Expert',
  };
}

enum PlayLikeAProSquadScope { any, solo, duo, squad }

extension PlayLikeAProSquadScopeX on PlayLikeAProSquadScope {
  String get label => switch (this) {
    PlayLikeAProSquadScope.any => 'Any squad size',
    PlayLikeAProSquadScope.solo => 'Solo',
    PlayLikeAProSquadScope.duo => 'Duo',
    PlayLikeAProSquadScope.squad => 'Squad',
  };
}

enum PlayLikeAProContentState { draft, published, archived }

enum PlayLikeAProMediaType { image, video, social }

class PlayLikeAProAuthor {
  const PlayLikeAProAuthor({
    required this.displayName,
    this.profileId,
    this.creatorTitle,
    this.socialLinks = const <ArcProfileSocialLink>[],
  });

  final String displayName;
  final String? profileId;
  final String? creatorTitle;
  final List<ArcProfileSocialLink> socialLinks;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'displayName': displayName.trim(),
    if (profileId?.trim().isNotEmpty == true) 'profileId': profileId!.trim(),
    if (creatorTitle?.trim().isNotEmpty == true)
      'creatorTitle': creatorTitle!.trim(),
    'socialLinks': socialLinks
        .map((link) => link.toMap())
        .toList(growable: false),
  };

  factory PlayLikeAProAuthor.fromMap(dynamic raw) {
    final map = raw is Map
        ? raw.map((key, value) => MapEntry('$key', value))
        : const <String, dynamic>{};
    return PlayLikeAProAuthor(
      displayName: (map['displayName'] ?? 'UAG Intel Team').toString().trim(),
      profileId: _nullableString(map['profileId']),
      creatorTitle: _nullableString(map['creatorTitle']),
      socialLinks: ArcProfileSocialLinks.fromRaw(map['socialLinks']),
    );
  }
}

class PlayLikeAProMedia {
  const PlayLikeAProMedia({required this.type, required this.url, this.label});

  final PlayLikeAProMediaType type;
  final String url;
  final String? label;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'type': type.name,
    'url': url.trim(),
    if (label?.trim().isNotEmpty == true) 'label': label!.trim(),
  };

  factory PlayLikeAProMedia.fromMap(dynamic raw) {
    final map = raw is Map
        ? raw.map((key, value) => MapEntry('$key', value))
        : const <String, dynamic>{};
    return PlayLikeAProMedia(
      type: _enumValue(
        PlayLikeAProMediaType.values,
        map['type'],
        PlayLikeAProMediaType.social,
      ),
      url: (map['url'] ?? '').toString().trim(),
      label: _nullableString(map['label']),
    );
  }
}

class PlayLikeAProSection {
  const PlayLikeAProSection({
    required this.heading,
    required this.body,
    this.bullets = const <String>[],
  });

  final String heading;
  final String body;
  final List<String> bullets;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'heading': heading.trim(),
    'body': body.trim(),
    'bullets': bullets,
  };

  factory PlayLikeAProSection.fromMap(dynamic raw) {
    final map = raw is Map
        ? raw.map((key, value) => MapEntry('$key', value))
        : const <String, dynamic>{};
    return PlayLikeAProSection(
      heading: (map['heading'] ?? '').toString().trim(),
      body: (map['body'] ?? '').toString().trim(),
      bullets: _stringList(map['bullets']),
    );
  }
}

class PlayLikeAProGuide {
  const PlayLikeAProGuide({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.skillLevel,
    required this.sections,
    this.tags = const <String>{},
    this.mapIds = const <String>{},
    this.weaponNames = const <String>{},
    this.loadoutTags = const <String>{},
    this.squadScope = PlayLikeAProSquadScope.any,
    this.eventIds = const <String>{},
    this.author = const PlayLikeAProAuthor(displayName: 'UAG Intel Team'),
    this.media = const <PlayLikeAProMedia>[],
    this.state = PlayLikeAProContentState.published,
    this.version = 1,
    this.publishedAt,
    this.updatedAt,
    this.featured = false,
    this.relatedGuideIds = const <String>[],
  });

  final String id;
  final String title;
  final String summary;
  final PlayLikeAProCategory category;
  final Set<String> tags;
  final PlayLikeAProSkillLevel skillLevel;
  final Set<String> mapIds;
  final Set<String> weaponNames;
  final Set<String> loadoutTags;
  final PlayLikeAProSquadScope squadScope;
  final Set<String> eventIds;
  final PlayLikeAProAuthor author;
  final List<PlayLikeAProMedia> media;
  final PlayLikeAProContentState state;
  final int version;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final bool featured;
  final List<String> relatedGuideIds;
  final List<PlayLikeAProSection> sections;

  bool get isPublished => state == PlayLikeAProContentState.published;
  bool get isMapRelevant => mapIds.isNotEmpty;
  bool get isLoadoutRelevant =>
      weaponNames.isNotEmpty || loadoutTags.isNotEmpty;
  bool get hasCreatorAttribution => author.displayName.trim().isNotEmpty;

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return <String>[
      title,
      summary,
      category.label,
      skillLevel.label,
      ...tags,
      ...weaponNames,
      ...mapIds,
      ...eventIds,
    ].any((value) => value.toLowerCase().contains(q));
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'title': title.trim(),
    'summary': summary.trim(),
    'category': category.name,
    'tags': tags.toList(growable: false),
    'skillLevel': skillLevel.name,
    'mapIds': mapIds.toList(growable: false),
    'weaponNames': weaponNames.toList(growable: false),
    'loadoutTags': loadoutTags.toList(growable: false),
    'squadScope': squadScope.name,
    'eventIds': eventIds.toList(growable: false),
    'author': author.toMap(),
    'media': media.map((item) => item.toMap()).toList(growable: false),
    'state': state.name,
    'version': version,
    'publishedAt': publishedAt == null
        ? null
        : Timestamp.fromDate(publishedAt!),
    'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    'featured': featured,
    'relatedGuideIds': relatedGuideIds,
    'sections': sections
        .map((section) => section.toMap())
        .toList(growable: false),
  };

  factory PlayLikeAProGuide.fromMap(String id, Map<String, dynamic> map) {
    return PlayLikeAProGuide(
      id: id,
      title: (map['title'] ?? 'Untitled guide').toString().trim(),
      summary: (map['summary'] ?? '').toString().trim(),
      category: _enumValue(
        PlayLikeAProCategory.values,
        map['category'],
        PlayLikeAProCategory.advanced,
      ),
      tags: _stringList(map['tags']).toSet(),
      skillLevel: _enumValue(
        PlayLikeAProSkillLevel.values,
        map['skillLevel'],
        PlayLikeAProSkillLevel.intermediate,
      ),
      mapIds: _stringList(map['mapIds'] ?? map['maps']).toSet(),
      weaponNames: _stringList(map['weaponNames'] ?? map['weapons']).toSet(),
      loadoutTags: _stringList(map['loadoutTags']).toSet(),
      squadScope: _enumValue(
        PlayLikeAProSquadScope.values,
        map['squadScope'],
        PlayLikeAProSquadScope.any,
      ),
      eventIds: _stringList(map['eventIds'] ?? map['events']).toSet(),
      author: PlayLikeAProAuthor.fromMap(map['author']),
      media: (map['media'] is List ? map['media'] as List : const <dynamic>[])
          .map(PlayLikeAProMedia.fromMap)
          .where((item) => item.url.isNotEmpty)
          .toList(growable: false),
      state: _enumValue(
        PlayLikeAProContentState.values,
        map['state'],
        PlayLikeAProContentState.published,
      ),
      version: _intValue(map['version'], 1),
      publishedAt: _dateValue(map['publishedAt']),
      updatedAt: _dateValue(map['updatedAt']),
      featured: _boolValue(map['featured']),
      relatedGuideIds: _stringList(map['relatedGuideIds']),
      sections:
          (map['sections'] is List
                  ? map['sections'] as List
                  : const <dynamic>[])
              .map(PlayLikeAProSection.fromMap)
              .where(
                (section) =>
                    section.heading.isNotEmpty || section.body.isNotEmpty,
              )
              .toList(growable: false),
    );
  }
}

T _enumValue<T extends Enum>(List<T> values, dynamic value, T fallback) {
  final name = value?.toString().trim() ?? '';
  for (final item in values) {
    if (item.name == name) return item;
  }
  return fallback;
}

List<String> _stringList(dynamic value) {
  if (value is! Iterable) return const <String>[];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _intValue(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolValue(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString().toLowerCase() == 'true';
}

DateTime? _dateValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}
