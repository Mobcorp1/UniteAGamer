import 'package:cloud_firestore/cloud_firestore.dart';

enum ArcSocialPlatform {
  tiktok,
  youtube,
  twitch,
  kick,
  discord,
  steam,
  xbox,
  playStation,
  epicGames,
}

extension ArcSocialPlatformX on ArcSocialPlatform {
  String get label {
    switch (this) {
      case ArcSocialPlatform.tiktok:
        return 'TikTok';
      case ArcSocialPlatform.youtube:
        return 'YouTube';
      case ArcSocialPlatform.twitch:
        return 'Twitch';
      case ArcSocialPlatform.kick:
        return 'Kick';
      case ArcSocialPlatform.discord:
        return 'Discord';
      case ArcSocialPlatform.steam:
        return 'Steam';
      case ArcSocialPlatform.xbox:
        return 'Xbox';
      case ArcSocialPlatform.playStation:
        return 'PlayStation';
      case ArcSocialPlatform.epicGames:
        return 'Epic Games';
    }
  }

  String get storageKey => name;
}

class ArcProfileSocialLink {
  const ArcProfileSocialLink({
    required this.platform,
    required this.value,
    this.hidden = false,
  });

  final ArcSocialPlatform platform;
  final String value;
  final bool hidden;

  String get normalisedValue => normaliseValue(platform, value);

  String get displayValue {
    final normalised = normalisedValue;
    if (normalised.isEmpty) return '';
    final uri = Uri.tryParse(normalised);
    if (uri != null && uri.hasScheme) {
      final path = uri.pathSegments.where((part) => part.isNotEmpty).join('/');
      return path.isEmpty ? uri.host : '${uri.host}/$path';
    }
    return normalised.startsWith('@') ? normalised : '@$normalised';
  }

  bool get isConfigured => normalisedValue.isNotEmpty;
  bool get isValid => validationError == null;
  bool get isPublic => isConfigured && isValid && !hidden;

  String? get validationError {
    final normalised = normalisedValue;
    if (normalised.isEmpty) return null;

    final uri = Uri.tryParse(normalised);
    if (uri != null && uri.hasScheme) {
      if (uri.scheme != 'https' && uri.scheme != 'http') {
        return 'Use an http or https ${platform.label} link.';
      }
      if (!_hostMatchesPlatform(platform, uri.host)) {
        return 'Use a ${platform.label} profile link or username.';
      }
      return null;
    }

    final handle = normalised.startsWith('@')
        ? normalised.substring(1)
        : normalised;
    if (!_handlePattern.hasMatch(handle)) {
      return 'Use letters, numbers, dot, dash or underscore only.';
    }
    if (handle.length < 2 || handle.length > 64) {
      return 'Use a ${platform.label} handle between 2 and 64 characters.';
    }
    return null;
  }

  Uri? get destinationUri {
    if (!isConfigured || !isValid) return null;
    final normalised = normalisedValue;
    final uri = Uri.tryParse(normalised);
    if (uri != null && uri.hasScheme) return uri;

    final handle = normalised.startsWith('@')
        ? normalised.substring(1)
        : normalised;
    final encoded = Uri.encodeComponent(handle);
    return switch (platform) {
      ArcSocialPlatform.tiktok => Uri.parse('https://www.tiktok.com/@$encoded'),
      ArcSocialPlatform.youtube => Uri.parse(
        'https://www.youtube.com/@$encoded',
      ),
      ArcSocialPlatform.twitch => Uri.parse('https://www.twitch.tv/$encoded'),
      ArcSocialPlatform.kick => Uri.parse('https://kick.com/$encoded'),
      ArcSocialPlatform.discord => Uri.parse('https://discord.com/app'),
      ArcSocialPlatform.steam => Uri.parse(
        'https://steamcommunity.com/id/$encoded',
      ),
      ArcSocialPlatform.xbox => Uri.parse(
        'https://www.xbox.com/play/user/$encoded',
      ),
      ArcSocialPlatform.playStation => Uri.parse(
        'https://profile.playstation.com/$encoded',
      ),
      ArcSocialPlatform.epicGames => Uri.parse(
        'https://store.epicgames.com/u/$encoded',
      ),
    };
  }

  String get destinationUrl => destinationUri?.toString() ?? '';

  ArcProfileSocialLink copyWith({
    ArcSocialPlatform? platform,
    String? value,
    bool? hidden,
  }) {
    return ArcProfileSocialLink(
      platform: platform ?? this.platform,
      value: value ?? this.value,
      hidden: hidden ?? this.hidden,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'platform': platform.storageKey,
      'value': normalisedValue,
      'hidden': hidden,
      'destinationUrl': destinationUrl,
    };
  }

  Map<String, dynamic> toPublicMap() {
    return <String, dynamic>{
      'platform': platform.storageKey,
      'label': platform.label,
      'value': displayValue,
      'destinationUrl': destinationUrl,
    };
  }

  factory ArcProfileSocialLink.fromMap(Map<String, dynamic> map) {
    return ArcProfileSocialLink(
      platform: ArcProfileSocialLinks.platformFromValue(map['platform']),
      value: (map['value'] ?? map['url'] ?? map['handle'] ?? '').toString(),
      hidden: ArcProfileSocialLinks.readBool(
        map['hidden'],
        ArcProfileSocialLinks.readBool(map['private']),
      ),
    );
  }

  static final RegExp _handlePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');

  static String normaliseValue(ArcSocialPlatform platform, String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return '';
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) {
      if (!_hostMatchesPlatform(platform, uri.host)) return raw;
      return uri.replace(fragment: '').toString();
    }
    return raw.replaceFirst(RegExp(r'^@+'), '').trim();
  }

  static bool _hostMatchesPlatform(ArcSocialPlatform platform, String host) {
    final normalised = host.toLowerCase();
    return switch (platform) {
      ArcSocialPlatform.tiktok => normalised.endsWith('tiktok.com'),
      ArcSocialPlatform.youtube =>
        normalised.endsWith('youtube.com') || normalised.endsWith('youtu.be'),
      ArcSocialPlatform.twitch => normalised.endsWith('twitch.tv'),
      ArcSocialPlatform.kick => normalised.endsWith('kick.com'),
      ArcSocialPlatform.discord =>
        normalised.endsWith('discord.com') ||
            normalised.endsWith('discord.gg') ||
            normalised.endsWith('discordapp.com'),
      ArcSocialPlatform.steam => normalised.endsWith('steamcommunity.com'),
      ArcSocialPlatform.xbox => normalised.endsWith('xbox.com'),
      ArcSocialPlatform.playStation => normalised.endsWith('playstation.com'),
      ArcSocialPlatform.epicGames => normalised.endsWith('epicgames.com'),
    };
  }
}

class ArcProfileSocialLinks {
  const ArcProfileSocialLinks._();

  static ArcSocialPlatform platformFromValue(dynamic value) {
    final key = value?.toString().trim() ?? '';
    return ArcSocialPlatform.values.firstWhere(
      (platform) =>
          platform.name == key ||
          platform.label.toLowerCase() == key.toLowerCase(),
      orElse: () => ArcSocialPlatform.discord,
    );
  }

  static bool readBool(dynamic value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalised = value.toString().trim().toLowerCase();
    if (normalised == 'true') return true;
    if (normalised == 'false') return false;
    return fallback;
  }

  static List<ArcProfileSocialLink> fromProfileMaps(
    Iterable<Map<String, dynamic>> maps,
  ) {
    final links = <ArcProfileSocialLink>[];
    for (final map in maps) {
      links.addAll(fromRaw(map['socialLinks']));
      for (final platform in ArcSocialPlatform.values) {
        final raw =
            map[platform.storageKey] ?? map['${platform.storageKey}Url'];
        if (raw == null) continue;
        links.add(ArcProfileSocialLink(platform: platform, value: '$raw'));
      }
    }
    return merge(links);
  }

  static List<ArcProfileSocialLink> fromRaw(dynamic value) {
    if (value is List) {
      return merge(
        value.whereType<Map>().map(
          (item) => ArcProfileSocialLink.fromMap(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        ),
      );
    }

    if (value is Map) {
      return merge(
        value.entries.map((entry) {
          final platform = platformFromValue(entry.key);
          final rawValue = entry.value;
          if (rawValue is Map) {
            return ArcProfileSocialLink.fromMap(<String, dynamic>{
              'platform': platform.storageKey,
              ...rawValue.map((key, value) => MapEntry('$key', value)),
            });
          }
          return ArcProfileSocialLink(platform: platform, value: '$rawValue');
        }),
      );
    }

    return const <ArcProfileSocialLink>[];
  }

  static List<ArcProfileSocialLink> merge(
    Iterable<ArcProfileSocialLink> links,
  ) {
    final byPlatform = <ArcSocialPlatform, ArcProfileSocialLink>{};
    for (final link in links) {
      if (!link.isConfigured) continue;
      byPlatform[link.platform] = link.copyWith(value: link.normalisedValue);
    }
    return ArcSocialPlatform.values
        .map((platform) => byPlatform[platform])
        .whereType<ArcProfileSocialLink>()
        .toList(growable: false);
  }

  static List<ArcProfileSocialLink> publicLinks(
    Iterable<ArcProfileSocialLink> links,
  ) {
    return merge(links).where((link) => link.isPublic).toList(growable: false);
  }
}

enum ArcCreatorProgrammeStatus {
  none,
  referralMember,
  creator,
  communityPartner,
  brandAmbassador,
  eliteAmbassador,
}

extension ArcCreatorProgrammeStatusX on ArcCreatorProgrammeStatus {
  String get label {
    switch (this) {
      case ArcCreatorProgrammeStatus.none:
        return 'Not enrolled';
      case ArcCreatorProgrammeStatus.referralMember:
        return 'Referral Member';
      case ArcCreatorProgrammeStatus.creator:
        return 'Creator';
      case ArcCreatorProgrammeStatus.communityPartner:
        return 'Community Partner';
      case ArcCreatorProgrammeStatus.brandAmbassador:
        return 'Brand Ambassador';
      case ArcCreatorProgrammeStatus.eliteAmbassador:
        return 'Elite Ambassador';
    }
  }
}

class ArcCreatorProgrammeProfile {
  const ArcCreatorProgrammeProfile({
    this.status = ArcCreatorProgrammeStatus.none,
    this.publicBadgeLabel = '',
    this.publicTitle = '',
    this.referralAttributionCode = '',
    this.adminApproved = false,
    this.rewardEligible = false,
    this.wallOfLegendsEligible = false,
    this.historicalStatuses = const <String>[],
    this.updatedAt,
  });

  final ArcCreatorProgrammeStatus status;
  final String publicBadgeLabel;
  final String publicTitle;
  final String referralAttributionCode;
  final bool adminApproved;
  final bool rewardEligible;
  final bool wallOfLegendsEligible;
  final List<String> historicalStatuses;
  final DateTime? updatedAt;

  bool get hasPublicRecognition =>
      adminApproved && status != ArcCreatorProgrammeStatus.none;

  String get displayBadgeLabel {
    if (publicBadgeLabel.trim().isNotEmpty) return publicBadgeLabel.trim();
    return status.label;
  }

  String get displayTitle {
    if (publicTitle.trim().isNotEmpty) return publicTitle.trim();
    return hasPublicRecognition ? '${status.label} Raider' : status.label;
  }

  ArcCreatorProgrammeProfile normalised({
    required String referralCode,
    required bool affiliateRequested,
  }) {
    final nextStatus =
        status == ArcCreatorProgrammeStatus.none && affiliateRequested
        ? ArcCreatorProgrammeStatus.referralMember
        : status;
    return copyWith(
      status: nextStatus,
      referralAttributionCode: referralAttributionCode.trim().isEmpty
          ? referralCode.trim()
          : referralAttributionCode.trim(),
      rewardEligible: adminApproved && rewardEligible,
      wallOfLegendsEligible: adminApproved && wallOfLegendsEligible,
    );
  }

  ArcCreatorProgrammeProfile copyWith({
    ArcCreatorProgrammeStatus? status,
    String? publicBadgeLabel,
    String? publicTitle,
    String? referralAttributionCode,
    bool? adminApproved,
    bool? rewardEligible,
    bool? wallOfLegendsEligible,
    List<String>? historicalStatuses,
    DateTime? updatedAt,
  }) {
    return ArcCreatorProgrammeProfile(
      status: status ?? this.status,
      publicBadgeLabel: publicBadgeLabel ?? this.publicBadgeLabel,
      publicTitle: publicTitle ?? this.publicTitle,
      referralAttributionCode:
          referralAttributionCode ?? this.referralAttributionCode,
      adminApproved: adminApproved ?? this.adminApproved,
      rewardEligible: rewardEligible ?? this.rewardEligible,
      wallOfLegendsEligible:
          wallOfLegendsEligible ?? this.wallOfLegendsEligible,
      historicalStatuses: historicalStatuses ?? this.historicalStatuses,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'status': status.name,
      'publicBadgeLabel': publicBadgeLabel.trim(),
      'publicTitle': publicTitle.trim(),
      'referralAttributionCode': referralAttributionCode.trim(),
      'adminApproved': adminApproved,
      'rewardEligible': rewardEligible,
      'wallOfLegendsEligible': wallOfLegendsEligible,
      'historicalStatuses': historicalStatuses,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  Map<String, dynamic> toPublicMap() {
    if (!hasPublicRecognition) return const <String, dynamic>{};
    return <String, dynamic>{
      'status': status.name,
      'label': status.label,
      'badgeLabel': displayBadgeLabel,
      'title': displayTitle,
      'wallOfLegendsEligible': wallOfLegendsEligible,
    };
  }

  factory ArcCreatorProgrammeProfile.fromMap(
    dynamic raw, {
    String fallbackReferralCode = '',
    bool affiliateEnabled = false,
  }) {
    final map = raw is Map
        ? raw.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    final rawStatus = (map['status'] ?? map['tier'] ?? '').toString().trim();
    final status = ArcCreatorProgrammeStatus.values.firstWhere(
      (item) => item.name == rawStatus,
      orElse: () => affiliateEnabled
          ? ArcCreatorProgrammeStatus.referralMember
          : ArcCreatorProgrammeStatus.none,
    );
    return ArcCreatorProgrammeProfile(
      status: status,
      publicBadgeLabel: (map['publicBadgeLabel'] ?? '').toString().trim(),
      publicTitle: (map['publicTitle'] ?? '').toString().trim(),
      referralAttributionCode:
          (map['referralAttributionCode'] ?? fallbackReferralCode)
              .toString()
              .trim(),
      adminApproved: ArcProfileSocialLinks.readBool(map['adminApproved']),
      rewardEligible: ArcProfileSocialLinks.readBool(map['rewardEligible']),
      wallOfLegendsEligible: ArcProfileSocialLinks.readBool(
        map['wallOfLegendsEligible'],
      ),
      historicalStatuses: _readStringList(map['historicalStatuses']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static List<String> _readStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
