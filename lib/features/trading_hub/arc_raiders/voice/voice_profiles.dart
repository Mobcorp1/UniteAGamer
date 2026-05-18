import 'package:uag_traders_hub/features/monetisation/models/uag_subscription_tier.dart';

class UagVoiceProfile {
  const UagVoiceProfile({
    required this.id,
    required this.displayName,
    required this.subtitle,
    required this.description,
    required this.requiredTier,
    required this.preferredLocales,
    required this.preferredNameHints,
    required this.fallbackNameHints,
    required this.previewText,
    required this.personalityPrefix,
    required this.rate,
    required this.pitch,
  });

  final String id;
  final String displayName;
  final String subtitle;
  final String description;
  final UagSubscriptionTier requiredTier;
  final List<String> preferredLocales;
  final List<String> preferredNameHints;
  final List<String> fallbackNameHints;
  final String previewText;
  final String personalityPrefix;
  final double rate;
  final double pitch;

  bool isUnlockedFor(UagSubscriptionTier tier, {bool adminBypass = false}) {
    if (adminBypass) return true;
    return tier.index >= requiredTier.index;
  }

  String lockedLabel() {
    switch (requiredTier) {
      case UagSubscriptionTier.free:
        return 'Included';
      case UagSubscriptionTier.essential:
        return 'Essential';
      case UagSubscriptionTier.premium:
        return 'Premium';
    }
  }
}

class UagResolvedVoiceProfile {
  const UagResolvedVoiceProfile({
    required this.profile,
    required this.ttsVoice,
    required this.engineName,
    required this.engineLocale,
    required this.isFallback,
  });

  final UagVoiceProfile profile;
  final Map<String, String> ttsVoice;
  final String engineName;
  final String engineLocale;
  final bool isFallback;

  String get id => profile.id;
  String get displayName => profile.displayName;
  String get subtitle => profile.subtitle;
  String get description => profile.description;
  UagSubscriptionTier get requiredTier => profile.requiredTier;
  String get tierLabel => profile.lockedLabel();
}

const List<UagVoiceProfile> uagVoiceProfiles = <UagVoiceProfile>[
  UagVoiceProfile(
    id: 'atlas',
    displayName: 'Atlas',
    subtitle: 'UK tactical male',
    description: 'Clear, steady operator voice for general raid support.',
    requiredTier: UagSubscriptionTier.free,
    preferredLocales: <String>['en-gb', 'en_gb', 'en-gb-x'],
    preferredNameHints: <String>[
      'daniel',
      'george',
      'arthur',
      'ryan',
      'male',
      'gbb',
    ],
    fallbackNameHints: <String>['english', 'gb', 'uk'],
    previewText: 'Atlas online. UAG Raider systems ready.',
    personalityPrefix: 'Raider check. ',
    rate: 0.45,
    pitch: 0.92,
  ),
  UagVoiceProfile(
    id: 'nova',
    displayName: 'Nova',
    subtitle: 'UK tactical female',
    description: 'Clean, bright voice for quick item calls and route checks.',
    requiredTier: UagSubscriptionTier.free,
    preferredLocales: <String>['en-gb', 'en_gb', 'en-gb-x'],
    preferredNameHints: <String>[
      'serena',
      'susan',
      'victoria',
      'female',
      'gba',
      'gbc',
    ],
    fallbackNameHints: <String>['english', 'gb', 'uk'],
    previewText: 'Nova online. UAG Raider systems ready.',
    personalityPrefix: 'Scan complete. ',
    rate: 0.47,
    pitch: 1.05,
  ),
  UagVoiceProfile(
    id: 'echo',
    displayName: 'Echo',
    subtitle: 'Fast raid comms',
    description: 'Short, punchy callouts for quick decisions mid-raid.',
    requiredTier: UagSubscriptionTier.essential,
    preferredLocales: <String>['en-gb', 'en-us', 'en_gb', 'en_us'],
    preferredNameHints: <String>['ryan', 'daniel', 'alex', 'male', 'us'],
    fallbackNameHints: <String>['english', 'local'],
    previewText: 'Echo online. Fast comms enabled.',
    personalityPrefix: 'Quick call. ',
    rate: 0.54,
    pitch: 0.98,
  ),
  UagVoiceProfile(
    id: 'valkyrie',
    displayName: 'Valkyrie',
    subtitle: 'Calm squad support',
    description: 'Smoother support voice for longer trade and tracker advice.',
    requiredTier: UagSubscriptionTier.essential,
    preferredLocales: <String>['en-gb', 'en-ie', 'en-us', 'en_gb', 'en_us'],
    preferredNameHints: <String>[
      'samantha',
      'karen',
      'moira',
      'serena',
      'female',
    ],
    fallbackNameHints: <String>['english', 'local'],
    previewText: 'Valkyrie online. Squad support ready.',
    personalityPrefix: 'Support readout. ',
    rate: 0.43,
    pitch: 1.03,
  ),
  UagVoiceProfile(
    id: 'sentinel',
    displayName: 'Sentinel',
    subtitle: 'Deep tactical',
    description: 'Slower, heavier command voice for premium raid intelligence.',
    requiredTier: UagSubscriptionTier.premium,
    preferredLocales: <String>['en-gb', 'en-us', 'en_gb', 'en_us'],
    preferredNameHints: <String>['george', 'arthur', 'daniel', 'male'],
    fallbackNameHints: <String>['english'],
    previewText: 'Sentinel online. Threat and trade intelligence ready.',
    personalityPrefix: 'Tactical assessment. ',
    rate: 0.39,
    pitch: 0.82,
  ),
  UagVoiceProfile(
    id: 'ghost',
    displayName: 'Ghost',
    subtitle: 'Low-profile scavenger',
    description: 'Quieter scavenger-style voice for stealthy item advice.',
    requiredTier: UagSubscriptionTier.premium,
    preferredLocales: <String>[
      'en-gb',
      'en-us',
      'en_ie',
      'en-au',
      'en_gb',
      'en_us',
    ],
    preferredNameHints: <String>[
      'moira',
      'samantha',
      'serena',
      'victoria',
      'female',
    ],
    fallbackNameHints: <String>['english'],
    previewText: 'Ghost online. Quiet scan mode ready.',
    personalityPrefix: 'Low-profile readout. ',
    rate: 0.41,
    pitch: 0.90,
  ),
];

List<UagResolvedVoiceProfile> resolveUagVoiceProfiles(dynamic rawVoices) {
  final engineVoices = _normaliseRawVoices(rawVoices);
  if (engineVoices.isEmpty) return const <UagResolvedVoiceProfile>[];

  final englishVoices = engineVoices
      .where((voice) {
        return voice.locale.toLowerCase().replaceAll('_', '-').startsWith('en');
      })
      .toList(growable: false);

  final source = englishVoices.isNotEmpty ? englishVoices : engineVoices;
  final usedEngineIds = <String>{};
  final resolved = <UagResolvedVoiceProfile>[];

  for (final profile in uagVoiceProfiles) {
    final match =
        _findBestVoiceForProfile(profile, source, usedEngineIds) ??
        source.first;
    usedEngineIds.add(match.id);
    resolved.add(
      UagResolvedVoiceProfile(
        profile: profile,
        ttsVoice: <String, String>{'name': match.name, 'locale': match.locale},
        engineName: match.name,
        engineLocale: match.locale,
        isFallback: !_matchesProfile(profile, match),
      ),
    );
  }

  return resolved;
}

_EngineVoice? _findBestVoiceForProfile(
  UagVoiceProfile profile,
  List<_EngineVoice> voices,
  Set<String> usedEngineIds,
) {
  final scored = voices.map((voice) {
    var score = 0;
    final locale = voice.locale.toLowerCase().replaceAll('_', '-');
    final name = voice.name.toLowerCase();

    if (usedEngineIds.contains(voice.id)) score -= 3;
    for (final preferredLocale in profile.preferredLocales) {
      final normalised = preferredLocale.toLowerCase().replaceAll('_', '-');
      if (locale == normalised) score += 8;
      if (locale.startsWith(normalised)) score += 6;
      if (name.contains(normalised)) score += 2;
    }
    for (final hint in profile.preferredNameHints) {
      if (name.contains(hint.toLowerCase())) score += 7;
    }
    for (final hint in profile.fallbackNameHints) {
      if (name.contains(hint.toLowerCase()) ||
          locale.contains(hint.toLowerCase()))
        score += 2;
    }
    if (name.contains('network')) score -= 2;
    if (name.contains('compact')) score -= 1;

    return _ScoredVoice(voice: voice, score: score);
  }).toList()..sort((a, b) => b.score.compareTo(a.score));

  if (scored.isEmpty) return null;
  return scored.first.voice;
}

bool _matchesProfile(UagVoiceProfile profile, _EngineVoice voice) {
  final name = voice.name.toLowerCase();
  final locale = voice.locale.toLowerCase().replaceAll('_', '-');
  return profile.preferredNameHints.any(
        (hint) => name.contains(hint.toLowerCase()),
      ) ||
      profile.preferredLocales.any((preferredLocale) {
        final normalised = preferredLocale.toLowerCase().replaceAll('_', '-');
        return locale.startsWith(normalised);
      });
}

List<_EngineVoice> _normaliseRawVoices(dynamic rawVoices) {
  if (rawVoices is! List) return const <_EngineVoice>[];

  final voices = <_EngineVoice>[];
  for (final rawVoice in rawVoices) {
    if (rawVoice is! Map) continue;
    final name = rawVoice['name']?.toString().trim() ?? '';
    final locale = rawVoice['locale']?.toString().trim() ?? '';
    if (name.isEmpty || locale.isEmpty) continue;
    voices.add(_EngineVoice(name: name, locale: locale));
  }

  voices.sort((a, b) {
    final aGb = a.locale.toLowerCase().replaceAll('_', '-').startsWith('en-gb')
        ? 0
        : 1;
    final bGb = b.locale.toLowerCase().replaceAll('_', '-').startsWith('en-gb')
        ? 0
        : 1;
    final localeSort = aGb.compareTo(bGb);
    if (localeSort != 0) return localeSort;
    return a.name.compareTo(b.name);
  });

  final deduped = <String, _EngineVoice>{};
  for (final voice in voices) {
    deduped[voice.id] = voice;
  }
  return deduped.values.toList(growable: false);
}

class _EngineVoice {
  const _EngineVoice({required this.name, required this.locale});
  final String name;
  final String locale;
  String get id => '$name|$locale';
}

class _ScoredVoice {
  const _ScoredVoice({required this.voice, required this.score});
  final _EngineVoice voice;
  final int score;
}
